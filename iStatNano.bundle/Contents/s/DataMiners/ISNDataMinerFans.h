//
//  ISNDataMinerFans.h
//  iStatMenusFans
//
//  Created by Buffy on 2/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iStatIntelControlleriStatPro.h"


@interface ISNDataMinerFans : NSObject {
    mach_port_t machport;
	NSArray *latestData;
	BOOL sensorArray;
	NSMutableArray *availableSensors;
	NSMutableDictionary *validFanSensors;
	NSMutableDictionary *fanSensorName;
	NSMutableDictionary *fanSensorPriority;
	iStatIntelControlleriStatPro *intelClassInstance;
}

- (void)moduleInstalled;
- (NSArray *)sensors;
- (BOOL)isIntel;
- (BOOL)hasIntelBundle;
- (void)setDictionaries;
- (NSArray *)getDataSet;
- (void)update;

@end
