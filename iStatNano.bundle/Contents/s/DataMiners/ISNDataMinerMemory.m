//
//  ISNDataMinerMemory.m
//  iStat
//
//  Created by Buffy Summers on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerMemory.h"


@implementation ISNDataMinerMemory

- (id)init {
	hostPort = mach_host_self();

	formatter = [[NSNumberFormatter alloc] init];
	[formatter setFormat:@"#,###;0;($ #,##0)"];
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_0];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];

	return self;
}

- (void)dealloc {
	if(latestData)
		[latestData release];

	mach_port_deallocate(mach_task_self(), hostPort);
	[super dealloc];
}


- (NSString *)convertB:(float)value {
	[[NSAutoreleasePool alloc] init];
	NSString *types[3]= {@"MB",@"GB",@"TB" };
	int i=0;
	if(value < 1000){
		int outputP = value;
		return [NSString stringWithFormat:@"%i%@",outputP,types[i]];
	}
 
	float output=value;
	while(output >1000){
		output=output/1000;
		i++;
	}
	return [NSString stringWithFormat:@"%.2f%@",output,types[i]];
}

- (NSArray *)getDataSet {
	return latestData;
}

- (NSString *)getSwap {
	int vmmib[2] = {CTL_VM, VM_SWAPUSAGE};
	struct xsw_usage swapused;
	size_t swlen = sizeof(swapused);
	sysctl(vmmib, 2, &swapused, &swlen, NULL, 0);
	NSString *swap = [self convertSwap:[NSNumber numberWithFloat:((float) swapused.xsu_total) / (1024.0 * 1024.0)]];
	return swap;
}

- (void)mineData {		
	[[NSAutoreleasePool alloc] init];
    vm_statistics_data_t	memoryData;
    mach_msg_type_number_t	numBytes = HOST_VM_INFO_COUNT;
	unsigned int				free;
	unsigned int				active;
	unsigned int				inactive;
	unsigned int				wired;
	unsigned int				used;
	unsigned int				total;
	float				pageins;
	float				pageouts;
	NSString *pagesins_formatted;
	NSString *pagesouts_formatted;
   
    host_statistics(hostPort, HOST_VM_INFO, (host_info_t)&memoryData, &numBytes);
	
	free = (memoryData.free_count * 4) / 1024;
	active = (memoryData.active_count * 4) / 1024;
	inactive = (memoryData.inactive_count * 4) / 1024;
	wired = (memoryData.wire_count * 4) / 1024;
	used = active + wired;
	total = used + free + inactive;

	pageins = memoryData.pageins;
	pageouts = memoryData.pageouts;
	
	if(pageins > 999999) {
		float millions = pageins / 1000000;
		pagesins_formatted = [NSString stringWithFormat:@"%.1fmil",millions];
	} else {
		pagesins_formatted = [formatter stringFromNumber:[NSNumber numberWithFloat:pageins]];
	}

	if(pageouts > 999999) {
		float millions = pageouts / 1000000;
		pagesouts_formatted = [NSString stringWithFormat:@"%.1fmil",millions];
	} else {
		pagesouts_formatted = [formatter stringFromNumber:[NSNumber numberWithFloat:pageouts]];
	}
	
	float percentage = ([[NSNumber numberWithUnsignedInt:used] floatValue] / [[NSNumber numberWithUnsignedInt:total] floatValue]) * 100;
	float wired_percentage = ([[NSNumber numberWithUnsignedInt:wired] floatValue] / [[NSNumber numberWithUnsignedInt:total] floatValue]) * 100;
	float active_percentage = ([[NSNumber numberWithUnsignedInt:active] floatValue] / [[NSNumber numberWithUnsignedInt:total] floatValue]) * 100;
	
	if(latestData)
		[latestData release];
	latestData = [[NSArray arrayWithObjects:[self convertM:[NSNumber numberWithUnsignedInt:free]],[self convertM:[NSNumber numberWithUnsignedInt:used]],[self convertM:[NSNumber numberWithUnsignedInt:active]],[self convertM:[NSNumber numberWithUnsignedInt:inactive]],[self convertM:[NSNumber numberWithUnsignedInt:wired]],[NSNumber numberWithFloat:percentage],pagesins_formatted,pagesouts_formatted,[self convertM:[NSNumber numberWithUnsignedInt:inactive + free]], [self getSwap],[NSNumber numberWithFloat:wired_percentage],[NSNumber numberWithFloat:active_percentage],nil] retain];
}

- (NSString *)convertM:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	float value = [input floatValue];
	NSString *types[3]= {@"mb",@"gb",@"tb" };
	int i=0;
	while(value > 1000){
		value = value / 1024;
		i++;
	}
	if(i == 0)
		return [NSString stringWithFormat:@"%.0f%@",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.2f%@",value,types[i]];
}

- (NSString *)convertSwap:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	float value = [input floatValue];
	NSString *types[3]= {@"mb",@"gb",@"tb" };
	int i=0;
	while(value > 1000){
		value = value / 1024;
		i++;
	}
	if(i == 0)
		return [NSString stringWithFormat:@"%.0f%@",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.1f%@",value,types[i]];
}


@end
