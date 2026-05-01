//
//  ISNDataMinerDisks.m
//  iStatMenusDisks
//
//  Created by Buffy on 2/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerDisks.h"

@implementation ISNDataMinerDisks

- (id)init {
	icon_directory = [[NSString alloc] initWithString:[@"~/Library/Application Support/iSlayer/iStatPro/" stringByExpandingTildeInPath]];
	NSString *support_directory = [@"~/Library/Application Support/iSlayer/" stringByExpandingTildeInPath];
	self = [super init];

	BOOL isDir;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:support_directory isDirectory:&isDir];
    if (!exists)
    {
		[[NSFileManager defaultManager] createDirectoryAtPath:support_directory attributes:nil];
	}
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath:icon_directory isDirectory:&isDir];
    if (!exists){
		[[NSFileManager defaultManager] createDirectoryAtPath:icon_directory attributes:nil];
	} else {
		[[NSFileManager defaultManager] removeFileAtPath:icon_directory handler:nil];
		[[NSFileManager defaultManager] createDirectoryAtPath:icon_directory attributes:nil];
	}

	driveTypes = [[NSMutableDictionary alloc] init];
	[self findDrives];
	[self update];
	
	return self;
}

- (void) dealloc {
	[driveTypes removeAllObjects];
	[driveTypes release], driveTypes = nil;
	[latestData release];
	[icon_directory release];
	[super dealloc];
}

- (NSArray *)getDataSet {
	return latestData;
}

- (void)update {
	[[NSAutoreleasePool alloc] init];
	NSMutableArray *theData = [[NSMutableArray alloc] init];
    NSString *path;
	BOOL first = YES;
	int i = 0;
    NSEnumerator *mountedPathsEnumerator = [[[NSWorkspace  sharedWorkspace] mountedLocalVolumePaths] objectEnumerator];
    while (path = [mountedPathsEnumerator nextObject] ) {
		struct statfs buffer;
        int returnnewCode = statfs([path fileSystemRepresentation],&buffer);
        if ( returnnewCode == 0 ) {
			NSRange start = [path rangeOfString:@"/Volumes/"];
			if(first == NO && start.length==0){
				continue;
			}
	
			if(first)
				first = NO;

			NSNumber* driveBlocksSize=[NSNumber numberWithDouble:buffer.f_bsize/1024];
			NSNumber* driveSize;
			NSNumber* driveFree;
			NSNumber* driveUsed;
	
				FSRef pathRef;
				FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &pathRef, NULL);

				OSErr osErr;

				FSCatalogInfo catInfo;
				osErr = FSGetCatalogInfo(&pathRef, kFSCatInfoVolume, &catInfo, NULL, NULL, NULL);

				int returnValue1 = 0;

				if(osErr == noErr) {
					returnValue1 = catInfo.volume;
				}

				int vRefNum = catInfo.volume;;

				FSVolumeInfo info;
				osErr = FSGetVolumeInfo (vRefNum, 0, NULL, kFSVolInfoSizes, &info, NULL, NULL);

				driveSize = [NSNumber numberWithUnsignedLongLong:info.totalBytes / 1024];
				driveFree = [NSNumber numberWithUnsignedLongLong:info.freeBytes / 1024];
				driveUsed = [NSNumber numberWithInt:(info.totalBytes - info.freeBytes ) / 1024];
				
				if([driveSize intValue] == NSNotFound)
					continue;
			

			NSNumber* driveGraph=[NSNumber numberWithFloat:[driveUsed floatValue]/[driveSize floatValue]];
			NSNumber* drivePercentage=[NSNumber numberWithInt:[driveGraph floatValue]*100];
			driveGraph=[NSNumber numberWithFloat:[driveGraph floatValue]*80];
						
			NSString *name = [[NSString stringWithFormat:@"%s",buffer.f_mntfromname] lastPathComponent];

			if([name hasPrefix:@"disk"] && [name length] > 4){
				NSString *newName = [name substringFromIndex:4];
				NSRange paritionLocation = [newName rangeOfString:@"s"];
				if(paritionLocation.length != 0){
					name = [NSString stringWithFormat:@"disk%@",[newName substringToIndex: paritionLocation.location]];
				}
			}

			if([driveTypes objectForKey:name] != NULL && ![path isEqualToString:@"/Volumes/iDisk"]){
				if([[driveTypes objectForKey:name] isEqualToString:@"Virtual Interface"] || [[driveTypes objectForKey:name] isEqualToString:@"CD"] || [[driveTypes objectForKey:name] isEqualToString:@"DVD"])
					continue;
			}

			NSString *icon_path = [NSString stringWithFormat:@"%@/%@.tiff",icon_directory,[[NSFileManager defaultManager] displayNameAtPath:path]];
			if([[NSFileManager defaultManager] fileExistsAtPath:icon_path] == NO) {
				NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];       
				NSData *tiffRep = [icon TIFFRepresentation];
				[tiffRep writeToFile:icon_path atomically:YES];
			}
			
			[theData addObject:[NSArray arrayWithObjects:[[NSFileManager defaultManager] displayNameAtPath:path],drivePercentage,[self convertB:driveUsed],[self convertB:driveFree],path,icon_path,nil]];
			i++;
        }
	}

	if(latestData)
		[latestData release];
	latestData = theData;
}

- (void)findDrives {
	[driveTypes removeAllObjects];
    IONotificationPortRef port;

    port = IONotificationPortCreate( kIOMasterPortDefault );

    if (port){
        CFMutableDictionaryRef properties;
        properties = IOServiceMatching( kIOMediaClass );
        if ( properties ){
            io_iterator_t notification;
			CFDictionaryAddValue( properties, CFSTR ( kIOMediaWholeKey ), kCFBooleanTrue );
            notification = 0;
			IOServiceAddMatchingNotification( port, kIOMatchedNotification, properties, NULL, NULL, &notification );
            if ( notification ) {
                [self callback:notification];
                IOObjectRelease( notification );
            }
        }
		
        IONotificationPortDestroy( port );
    }
}

- (void)callback:(io_iterator_t)notification {
	[[NSAutoreleasePool alloc] init];
    io_object_t media;

    while ( ( media = IOIteratorNext( notification ) ) ) {
		NSString* bsdName = NULL;
        CFDictionaryRef properties;

        properties = NULL;

		IORegistryEntryCreateCFProperties( media, ( CFMutableDictionaryRef * ) &properties, kCFAllocatorDefault, 0 );

        if ( properties ){
 			NSDictionary* disk = [NSDictionary dictionaryWithDictionary:(NSDictionary* )properties];
			bsdName = [disk objectForKey:@"BSD Name"];
			CFRelease( properties );
        }
		
		if(IOObjectConformsTo( media, kIOCDMediaClass ) ){
			[driveTypes setValue:@"CD" forKey:bsdName];
			IOObjectRelease( media );
			continue;
		}
		if(IOObjectConformsTo( media, kIODVDMediaClass ) ){
			[driveTypes setValue:@"DVD" forKey:bsdName];
			IOObjectRelease( media );
			continue;
		}
		
		properties = IORegistryEntrySearchCFProperty( media, kIOServicePlane, CFSTR( kIOPropertyProtocolCharacteristicsKey ), kCFAllocatorDefault, kIORegistryIterateParents | kIORegistryIterateRecursively );
        if ( properties ){
 			NSDictionary* disk = [NSDictionary dictionaryWithDictionary:(NSDictionary* )properties];
			[driveTypes setValue:[disk objectForKey:@"Physical Interconnect"] forKey:bsdName];
            CFRelease( properties );
        }

        IOObjectRelease( media );
    }
}

- (NSString *)convertB:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	float value = [input floatValue];
	
	if(value < 1024)
		return @"0KB";
		
	value = value / 1024;
	NSString *types[3]= {@"MB",@"GB",@"TB" };
	int i=0;
	if(value < 1024){
		int outputP=value;
		return [NSString stringWithFormat:@"%i%@",outputP,types[i]];
	}
	float output=value;
	while(output > 1000){
		output = output / 1024;
		i++;
	}
	if(i > 3)
		return @"0KB";
	
	return [NSString stringWithFormat:@"%.2f%@",output,types[i]];
}

@end
