//
//  ISNDataMinerTemps.m
//  iStatMenusTemps
//
//  Created by Buffy on 2/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerTemps.h"

@implementation NSArray(ISPSort)

- (NSComparisonResult)compare:(id)aString {
    return [(NSString *)[self objectAtIndex:0] compare:(NSString *)[aString objectAtIndex:0] options:NSCaseInsensitiveSearch];
}

@end


@implementation ISNDataMinerTemps

- (id)init {
	self = [super init];

	sensorArray = NO;
	
	intelClassInstance = nil;

	// Old code for when a seperate bundle was used for temps/fans on intel macs

	/* NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/iStatIntelSensorsV3.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
		Class intelClass;
		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
		if(intelBundle != nil){
			if (intelClass = [intelBundle principalClass])
				intelClassInstance = [[intelClass alloc] init];
		}
	} */

	if([self isIntel])
		intelClassInstance = [[iStatIntelControlleriStatPro alloc] init];
	
	validTempSensors = [[NSMutableDictionary alloc] init];
	tempSensorName = [[NSMutableDictionary alloc] init];
	tempSensorPriority = [[NSMutableDictionary alloc] init];
	availableSensors = [[NSMutableArray alloc] init];

	[self setDictionaries];
	[self getDataSet:0];
	sensorArray = YES;

	return self;
}

- (void) dealloc {
	if(intelClassInstance)
		[intelClassInstance release];
		
	[validTempSensors release];
	[tempSensorName release];
	[tempSensorPriority release];
	[availableSensors release];
	
	if(latestData)
		[latestData release];
		
	mach_port_deallocate(mach_task_self(), machport);
	[super dealloc];
}

- (void)moduleInstalled {
	// Old code for when a seperate bundle was used for temps/fans on intel macs

//	NSLog(@"Intel Module now available");
//	NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/iStatIntelSensorsV3.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
//	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
//		Class intelClass;
//		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
//		if(intelBundle != nil){
//			if (intelClass = [intelBundle principalClass])
//				intelClassInstance = [[intelClass alloc] init];
//			
//			sensorArray = NO;
//			[availableSensors removeAllObjects];
//			[self update:0];
//			sensorArray = YES;
//		}
//	}
}

- (NSArray *)sensors {
	return availableSensors;
}

- (BOOL)isIntel {
	OSType		returnType;
	long		gestaltReturnValue;
	
	returnType=Gestalt(gestaltSysArchitecture, &gestaltReturnValue);
	
	if (!returnType && gestaltReturnValue == gestaltIntel)
		return YES;

	return NO;
}

- (BOOL)hasIntelBundle {
	NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/IntelSensorsiStatPro.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
		if(intelBundle != nil){
			return YES;
		}
	}
	return NO;
}

- (void) setDictionaries {
	[validTempSensors setObject:@"65536" forKey:@"Hard drive"];			//Powerbook Cpu - all rev's ?
	[tempSensorName setObject:@"HD Bay" forKey:@"Hard drive"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"3" forKey:@"Hard drive"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"CPU TOPSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorName setObject:@"CPU Bottom" forKey:@"CPU TOPSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU TOPSIDE"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU BOTTOMSIDE"];			//iBook Cpu - all rev's
	[tempSensorName setObject:@"CPU Top" forKey:@"CPU BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU A AD7417 AMB"];		//Unknown -17" Powerbook
	[tempSensorName setObject:@"CPU A Amb" forKey:@"CPU A AD7417 AMB"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"3" forKey:@"CPU A AD7417 AMB"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU B AD7417 AMB"];		//Unknown -17" Powerbook
	[tempSensorName setObject:@"CPU B Amb" forKey:@"CPU B AD7417 AMB"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"3" forKey:@"CPU B AD7417 AMB"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"10" forKey:@"CPU A AD7417 AD1"];			//Single Core G5 Tower Cpu A
	[tempSensorName setObject:@"CPU A" forKey:@"CPU A AD7417 AD1"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU A AD7417 AD1"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"10" forKey:@"CPU B AD7417 AD1"];			//Single Core G5 Tower Cpu B
	[tempSensorName setObject:@"CPU B" forKey:@"CPU B AD7417 AD1"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU B AD7417 AD1"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"10" forKey:@"CPU T-Diode"];				//G5 iMac Cpu - all rev's
	[tempSensorName setObject:@"CPU" forKey:@"CPU T-Diode"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU T-Diode"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"10" forKey:@"CPU A DIODE TEMP"];			//xserve ?
	[tempSensorName setObject:@"CPU A" forKey:@"CPU A DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU A DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU A0 DIODE TEMP"];			//Quad G5 Cpu A Core 0
	[tempSensorName setObject:@"CPU A Core 1" forKey:@"CPU A0 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU A0 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU A1 DIODE TEMP"];			//Quad G5 Cpu A Core 1
	[tempSensorName setObject:@"CPU A Core 2" forKey:@"CPU A1 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU A1 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU B0 DIODE TEMP"];			//Quad G5 Cpu B Core 0
	[tempSensorName setObject:@"CPU B Core 1" forKey:@"CPU B0 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU B0 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"CPU B1 DIODE TEMP"];			//Quad G5 Cpu B Core 1
	[tempSensorName setObject:@"CPU B Core 2" forKey:@"CPU B1 DIODE TEMP"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU B1 DIODE TEMP"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"ODD Temp"];				//Optical Drive Temp ?
	[tempSensorName setObject:@"Optical Drive" forKey:@"ODD Temp"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"ODD Temp"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"HD Temp"];				//Hard Drive Temp
	[tempSensorName setObject:@"HD Bay" forKey:@"HD Temp"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"3" forKey:@"HD Temp"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"NB Ambient"];				//Northbridge Ambient ?
	[tempSensorName setObject:@"Mem Controller" forKey:@"NB Ambient"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"NB Ambient"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"NB Temp"];				//Northbridge Temp ?
	[tempSensorName setObject:@"Mem Controller" forKey:@"NB Temp"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"NB Temp"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"GPU Ambient"];			//GPU Ambiend
	[tempSensorName setObject:@"GPU Ambient" forKey:@"GPU Ambient"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"GPU Ambient"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"GPU Temp"];				//GPU Temp
	[tempSensorName setObject:@"GPU" forKey:@"GPU Temp"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"2" forKey:@"GPU Temp"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"Incoming Air Temp"];		//Incoming Air Temp - iMacs
	[tempSensorName setObject:@"Incoming Air" forKey:@"Incoming Air Temp"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"2" forKey:@"Incoming Air Temp"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"CPU/INTREPID BOTTOMSIDE"];//Incoming Air Temp - iMacs
	[tempSensorName setObject:@"CPU Bottom" forKey:@"CPU/INTREPID BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"1" forKey:@"CPU/INTREPID BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"PWR SUPPLY BOTTOMSIDE"];	//Incoming Air Temp - iMacs
	[tempSensorName setObject:@"Power Supply" forKey:@"PWR SUPPLY BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"PWR SUPPLY BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"TRACK PAD"];				//Incoming Air Temp - iMacs
	[tempSensorName setObject:@"Track Pad" forKey:@"TRACK PAD"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"2" forKey:@"TRACK PAD"];			//Powerbook Cpu - all rev's ?

//	[validTempSensors setObject:@"65536" forKey:@"ALS MLB"];				//Unknown -17" Powerbook
//	[tempSensorName setObject:@"ALS MLB" forKey:@"ALS MLB"];			//Powerbook Cpu - all rev's ?
//	[tempSensorPriority setObject:@"4" forKey:@"ALS MLB"];			//Powerbook Cpu - all rev's ?

//	[validTempSensors setObject:@"65536" forKey:@"ALS Sutro"];				//Unknown -17" Powerbook
//	[tempSensorName setObject:@"ALS Sutro" forKey:@"ALS Sutro"];			//Powerbook Cpu - all rev's ?
//	[tempSensorPriority setObject:@"4" forKey:@"ALS Sutro"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"DRIVE BAY"];				//Unknown -17" Powerbook
	[tempSensorName setObject:@"Drive Bay" forKey:@"DRIVE BAY"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"DRIVE BAY"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"BACKSIDE"];				//Unknown -17" Powerbook
	[tempSensorName setObject:@"Backside" forKey:@"BACKSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"BACKSIDE"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"U3 HEATSINK"];			//Unknown -17" Powerbook
	[tempSensorName setObject:@"U3 Heatsink" forKey:@"U3 HEATSINK"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"U3 HEATSINK"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"gpu-diode"];				//Unknown -17" Powerbook
	[tempSensorName setObject:@"GPU" forKey:@"gpu-diode"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"2" forKey:@"gpu-diode"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"gpu-case"];				//Unknown -17" Powerbook
	[tempSensorName setObject:@"GPU Case" forKey:@"gpu-case"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"gpu-case"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"SYS CTRLR AMBIENT"];		//Unknown -17" Powerbook
	[tempSensorName setObject:@"Sys Controller" forKey:@"SYS CTRLR AMBIENT"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"SYS CTRLR AMBIENT"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"SYS CTRLR INTERNAL"];		//Unknown -17" Powerbook
	[tempSensorName setObject:@"Sys Controller" forKey:@"SYS CTRLR INTERNAL"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"SYS CTRLR INTERNAL"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"Behind the DIMMS"];		//Unknown -17" Powerbook
	[tempSensorName setObject:@"Behind Dimms" forKey:@"Behind the DIMMS"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"Behind the DIMMS"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"Between the Processors"];	//Unknown -17" Powerbook
	[tempSensorName setObject:@"Between CPU's" forKey:@"Between the Processors"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"Between the Processors"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"PCI SLOTS"];				//Unknown -17" Powerbook
	[tempSensorName setObject:@"PCI Slots" forKey:@"PCI SLOTS"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"PCI SLOTS"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"PWR/MEMORY BOTTOMSIDE"];	//Unknown -17" Powerbook
	[tempSensorName setObject:@"Memory/Power" forKey:@"PWR/MEMORY BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"PWR/MEMORY BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"TUNNEL"];					//Unknown -17" Powerbook
	[tempSensorName setObject:@"Tunnel" forKey:@"TUNNEL"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"TUNNEL"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"TUNNEL HEATSINK"];		//Unknown -17" Powerbook
	[tempSensorName setObject:@"Tunnel Heatsink" forKey:@"TUNNEL HEATSINK"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"4" forKey:@"TUNNEL HEATSINK"];			//Powerbook Cpu - all rev's ?
	
	[validTempSensors setObject:@"65536" forKey:@"BATTERY"];				//Battery Temp - Powerbooks
	[tempSensorName setObject:@"Battery" forKey:@"BATTERY"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"2" forKey:@"BATTERY"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"GPU ON DIE"];				//GPU Die Temp - 12" Powerbooks
	[tempSensorName setObject:@"GPU" forKey:@"GPU ON DIE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"2" forKey:@"GPU ON DIE"];			//Powerbook Cpu - all rev's ?

	[validTempSensors setObject:@"65536" forKey:@"HDD BOTTOMSIDE"];			//Hard Drive - Powerbooks
	[tempSensorName setObject:@"HD Bay" forKey:@"HDD BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
	[tempSensorPriority setObject:@"3" forKey:@"HDD BOTTOMSIDE"];			//Powerbook Cpu - all rev's ?
}

- (NSArray *)getDataSet:(int)degrees {
	NSMutableArray *theData = [[NSMutableArray alloc] init];
	
	NSString *degreesSuffix = [NSString stringWithUTF8String:"\xC2\xB0"];					
	if(degrees == 2)
		degreesSuffix = @"K";

	if(intelClassInstance!= nil){
		int value = 0;
		@try { 
			NSDictionary *temps = [intelClassInstance getTempValues];
								
			NSEnumerator *groupEnumerator = [temps objectEnumerator];
			NSArray *group;
			while(group = [groupEnumerator nextObject]){
				NSEnumerator *sensorEnumerator = [group objectEnumerator];
				NSArray *sensor;
				while(sensor = [sensorEnumerator nextObject]){
					if(!sensorArray)
						[availableSensors addObject:[sensor objectAtIndex:0]];

					value = [[sensor objectAtIndex:1] intValue];
					if(degrees == 1) // Fahrenheight
						value = (value * 2) - ((value * 2) * 1 / 10) + 32;
					
					if(degrees == 2) // Kelvin
						value += 273.15;
			
					[theData addObject:[NSArray arrayWithObjects:[sensor objectAtIndex:0], [NSString stringWithFormat:@"%i%@",value,degreesSuffix], nil]];
				}
			}
		}

		@catch ( NSException *e ) {  
			return [NSArray array];
		}
		return [theData autorelease];
	}

	NSMutableDictionary *priorityOne = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *priorityTwo = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *priorityThree = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *priorityFour = [[NSMutableDictionary alloc] init];
		
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;    
    
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOHWSensor"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    io_object_t sensorObject;
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData,  kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }

		if([validTempSensors objectForKey:[sensorData objectForKey:@"location"]] != NULL){
			IORegistryEntrySetCFProperty(sensorObject,CFSTR("force-update"),(CFNumberRef)[sensorData valueForKey:@"sensor-id"]);
			if(!sensorArray)
				[availableSensors addObject:[sensorData objectForKey:@"location"]];

			id currentValue = [sensorData objectForKey:@"current-value"];
			int value = [currentValue intValue] / [[validTempSensors objectForKey:[sensorData objectForKey:@"location"]] intValue];
			if(value <= 0)
				continue;
			if(degrees == 1)
				value = (value * 2) - ((value * 2) * 1 / 10) + 32;
			if(degrees == 2)
				value += 273.15;

			if([[tempSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 1){
				[priorityOne setObject:[NSString stringWithFormat:@"%i%@",value,degreesSuffix] forKey:[tempSensorName valueForKey:[sensorData objectForKey:@"location"]]];
			} else if([[tempSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 2){
				[priorityTwo setObject:[NSString stringWithFormat:@"%i%@",value,degreesSuffix] forKey:[tempSensorName valueForKey:[sensorData objectForKey:@"location"]]];
			} else if([[tempSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 3){
				[priorityThree setObject:[NSString stringWithFormat:@"%i%@",value,degreesSuffix] forKey:[tempSensorName valueForKey:[sensorData objectForKey:@"location"]]];
			} else if([[tempSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 4){
				[priorityFour setObject:[NSString stringWithFormat:@"%i%@",value,degreesSuffix] forKey:[tempSensorName valueForKey:[sensorData objectForKey:@"location"]]];
			}
		}
        CFRelease(sensorData);
        IOObjectRelease(sensorObject);
    }
    IOObjectRelease(sensorsIterator);	

	
	NSEnumerator *sensorEnumerator = [priorityOne keyEnumerator];
	NSString *key=@"";
	while(key = [sensorEnumerator nextObject]){
		[theData addObject:[NSArray arrayWithObjects:key, [priorityOne objectForKey:key], nil]];
	}
	
	sensorEnumerator = [priorityTwo keyEnumerator];
	while(key = [sensorEnumerator nextObject]){
		[theData addObject:[NSArray arrayWithObjects:key, [priorityTwo objectForKey:key], nil]];
	}
	
	sensorEnumerator = [priorityThree keyEnumerator];
	while(key = [sensorEnumerator nextObject]){
		[theData addObject:[NSArray arrayWithObjects:key, [priorityThree objectForKey:key], nil]];
	}
	
	sensorEnumerator = [priorityFour keyEnumerator];
	while(key = [sensorEnumerator nextObject]){
		[theData addObject:[NSArray arrayWithObjects:key, [priorityFour objectForKey:key], nil]];
	}
	
	[priorityOne release];
	[priorityTwo release];
	[priorityThree release];
	[priorityFour release];
	return [theData autorelease];
}

@end
