//
//  DataMinerBattery.h
//  iStat
//
//  Created by Buffy Summers on 8/9/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISNDataMinerBattery : NSObject {
	NSArray *latestData;
	NSUserDefaults *standardUserDefaults;
	int cyclePos;
	NSString *theCycles;
	int type;
	NSString *theCapcity;
}

- (BOOL) isLaptop;

@end
