//
//  ISNDataMinerMemory.h
//  iStat
//
//  Created by Buffy Summers on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mach/host_info.h>
#import <mach/mach_host.h>
#include <mach/machine/vm_param.h>
#include <mach/machine/vm_types.h>
#include <sys/sysctl.h>

@interface ISNDataMinerMemory : NSObject {
	NSArray *latestData;
	NSUserDefaults *standardUserDefaults;
	mach_port_t hostPort;
	NSNumberFormatter *formatter;
}

- (void)mineData;
- (NSArray *)getDataSet;
- (NSString *)convertB:(float)value;

@end
