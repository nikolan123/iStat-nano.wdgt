//
//  ISNDataMinerCPU.h
//  iStat
//
//  Created by Buffy Summers on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <mach/machine.h>
#import <mach/mach_types.h>
#import <mach/processor_info.h>
#import <sys/sysctl.h>

@interface ISNDataMinerCPU : NSObject {
	host_name_port_t machPort;
	processor_set_name_port_t procPort;
	NSArray *latestData;
	processor_cpu_load_info_t	lastCPUInfo;
	int processors;
}

+ (id)ISNDataMinerCore;
- (int)getProcessors;
- (void)setup;
- (void)mineData;
- (NSArray *)getDataSet;
- (NSString *)getLoad;
- (NSString *)processInfo;
- (NSString *)getUptime;


@end
