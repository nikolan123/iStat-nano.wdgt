//
//  ISNDataMinerTemps.h
//  iStatMenusTemps
//
//  Created by Buffy on 2/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iStatIntelControlleriStatPro.h"


@interface ISNDataMinerTemps : NSObject {
	NSArray *latestData;
	BOOL sensorArray;
	NSMutableArray *availableSensors;
	NSMutableDictionary *validTempSensors;
	NSMutableDictionary *tempSensorName;
	NSMutableDictionary *tempSensorPriority;
	iStatIntelControlleriStatPro *intelClassInstance;
    mach_port_t      machport;
}

- (void)moduleInstalled;
- (NSArray *)sensors;
- (BOOL)isIntel;
- (BOOL)hasIntelBundle;
- (void)setDictionaries;
- (NSArray *)getDataSet;
- (void)update;

@end
