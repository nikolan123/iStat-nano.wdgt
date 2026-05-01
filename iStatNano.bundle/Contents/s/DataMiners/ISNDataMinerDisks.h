//
//  ISNDataMinerDisks.h
//  iStatMenusDisks
//
//  Created by Buffy on 2/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOStorageProtocolCharacteristics.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>
#include <sys/param.h>
#include <sys/mount.h>

@interface ISNDataMinerDisks : NSObject {
	NSString *icon_directory;
	NSArray *latestData;
	NSMutableDictionary* driveTypes;
}

- (NSArray *)getDataSet;
- (void)update;
- (void)findDrives;
- (NSString *)convertB:(NSNumber *)input;
- (void)callback:(io_iterator_t)notification;

@end
