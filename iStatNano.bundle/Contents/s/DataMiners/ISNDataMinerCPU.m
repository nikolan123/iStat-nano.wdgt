//
//  ISNDataMinerCPU.m
//  iStat
//
//  Created by Buffy Summers on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerCPU.h"

@implementation ISNDataMinerCPU

- (id)init {
	self = [super init];
	
	machPort = mach_host_self();
	processor_set_default(machPort, &procPort);
	
	[self setup];
	return self;
}

- (void)dealloc {
	free(lastCPUInfo);
	if(latestData)
		[latestData release];
	[super dealloc];
}

- (int)getProcessors {
	return processors;
}

- (void)setup {
	int  error, selectors[2] = { CTL_HW, HW_NCPU };
	mach_msg_type_number_t		processorMsgCount;
	unsigned int	processor_count;
	size_t datasize = sizeof(processor_count);
	error = sysctl(selectors, 2, &processor_count, &datasize, NULL, 0);
	processor_cpu_load_info_t	processorTickInfo;
	host_processor_info(machPort, PROCESSOR_CPU_LOAD_INFO, &processor_count, (processor_info_array_t *)&processorTickInfo, &processorMsgCount);		
    lastCPUInfo   = malloc(processor_count * sizeof(*lastCPUInfo));


	int i;
	int j;
	processors = processor_count;
    for (i = 0; i < processor_count; i++) {
		for (j = 0; j < CPU_STATE_MAX; j++) {
			lastCPUInfo[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
		}
	}
	vm_deallocate(machPort, (vm_address_t)processorTickInfo, (vm_size_t)(processorMsgCount * sizeof(*processorTickInfo)));
}

- (void)mineData {
	[[NSAutoreleasePool alloc] init];	
	NSMutableArray *individualCpuDataFull = [[NSMutableArray alloc] init];
	
	mach_msg_type_number_t			processorMsgCount;
	processor_cpu_load_info_t		newCPUInfo;
	unsigned int					processor_count;
	int								i;
	int								totalCPUTicks;
	int total_user = 0;
	int total_sys = 0;
	int total_nice = 0;

	host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processor_count, (processor_info_array_t *)&newCPUInfo, &processorMsgCount);
	for(i=0;i<processor_count;i++){
		totalCPUTicks = 0;
		int j;
		for (j = 0; j < CPU_STATE_MAX; j++) {
			totalCPUTicks += newCPUInfo[i].cpu_ticks[j] - lastCPUInfo[i].cpu_ticks[j];
		}
		float core_sys = (newCPUInfo[i].cpu_ticks[CPU_STATE_SYSTEM] - lastCPUInfo[i].cpu_ticks[CPU_STATE_SYSTEM]) / (float)totalCPUTicks * 100;
		float core_user = (newCPUInfo[i].cpu_ticks[CPU_STATE_USER] - lastCPUInfo[i].cpu_ticks[CPU_STATE_USER]) / (float)totalCPUTicks * 100;
		float core_nice = (newCPUInfo[i].cpu_ticks[CPU_STATE_NICE] - lastCPUInfo[i].cpu_ticks[CPU_STATE_NICE]) / (float)totalCPUTicks * 100;

		total_sys += core_sys;
		total_user += core_user;
		total_nice += core_nice;

		[individualCpuDataFull addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:(core_sys + core_user + core_nice)],[NSNumber numberWithFloat:core_sys], [NSNumber numberWithFloat:core_user], [NSNumber numberWithFloat:core_nice] , nil]];

		for(j = 0; j < CPU_STATE_MAX; j++){
			lastCPUInfo[i].cpu_ticks[j] = newCPUInfo[i].cpu_ticks[j];
		}
	}
	vm_deallocate(mach_task_self(), (vm_address_t)newCPUInfo, (vm_size_t)(processor_count * sizeof(*lastCPUInfo)));

	int activeProcs = processor_count;
	if ( activeProcs > 1) {
		total_sys = total_sys / activeProcs;
		total_user = total_user / activeProcs;
		total_nice = total_nice / activeProcs;
	}
	
	if(total_sys < 0)
		total_sys = 0;
	if(total_user < 0)
		total_user = 0;
	if(total_nice < 0)
		total_nice = 0;

	int idle = 100 - total_sys - total_user - total_nice;

	[latestData release];
	NSArray *mainData = [NSArray arrayWithObjects:[NSNumber numberWithInt:total_sys],[NSNumber numberWithInt:total_user],[NSNumber numberWithInt:total_nice],[NSNumber numberWithInt:idle],[NSNumber numberWithInt:100 - idle],nil];
	latestData = [NSArray arrayWithObjects:mainData,individualCpuDataFull,nil];
	[latestData retain];
	[individualCpuDataFull release];
}

- (NSArray *)getDataSet {
	return latestData;
}

- (NSString *)getLoad {
	[[NSAutoreleasePool alloc] init];
	struct loadavg loadinfo;
	int mib[2];
	size_t size;
	mib[0] = CTL_VM;
	mib[1] = VM_LOADAVG;
	size = sizeof(loadinfo);
	sysctl(mib, 2, &loadinfo, &size, NULL, 0);

	return [NSString stringWithFormat:@"%.2f, %.2f, %.2f",(double) loadinfo.ldavg[0]/ loadinfo.fscale, (double) loadinfo.ldavg[1]/ loadinfo.fscale, (double) loadinfo.ldavg[2]/ loadinfo.fscale];
}

- (NSString *)processInfo {
	kern_return_t result;
	struct processor_set_load_info processData;
	unsigned int count = PROCESSOR_SET_LOAD_INFO_COUNT;
	
	result = processor_set_statistics(procPort, PROCESSOR_SET_LOAD_INFO, (processor_set_info_t)&processData, &count);
	if (result != KERN_SUCCESS)
		return @"";
	else
		return [NSString stringWithFormat:@"%i tasks, %i threads",processData.task_count, processData.thread_count];
} 

- (NSString *)getUptime {
	NSString *uptime = @"";

    int            uptimeDays;
    int            uptimeHours;
    int            uptimeMinutes;
    int            uptimeSeconds;
    time_t         currentTime;
    time_t         uptimeInSeconds = 0;
    struct timeval bootTime;
    size_t         size = sizeof(bootTime);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };    

    time(&currentTime);
        
	if ((sysctl(mib, 2, &bootTime, &size, NULL, 0) != -1) && (bootTime.tv_sec != 0)) {
        uptimeInSeconds = currentTime - bootTime.tv_sec;

        uptimeDays = uptimeInSeconds / (60 * 60 * 24);
        uptimeInSeconds %= (60 * 60 * 24);
        
        uptimeHours = uptimeInSeconds / (60 * 60);
        uptimeInSeconds %= (60 * 60);
        
        uptimeMinutes = uptimeInSeconds / 60;
        uptimeInSeconds %= 60;
        
        uptimeSeconds = uptimeInSeconds;
		uptime = [NSString stringWithFormat:@"%id %ih %im",uptimeDays,uptimeHours,uptimeMinutes,uptimeInSeconds];
	}

	return uptime;
}

@end
