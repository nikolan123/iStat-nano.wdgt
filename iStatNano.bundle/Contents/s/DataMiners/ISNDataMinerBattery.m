//
//  DataMinerBattery.m
//  iStat
//
//  Created by Buffy Summers on 8/9/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerBattery.h"

@implementation ISNDataMinerBattery

- (id)init {
	cyclePos = 0;
	theCycles = @"0";
	[theCycles retain];

	theCapcity = @"0%";
	[theCapcity retain];
	
	[self isLaptop];
	
	latestData = [[NSArray arrayWithObjects:@"Unknown",@"0",@"Unknown",@"Unknown",@"0", @"0%", nil] retain];
	return self;
}

- (void) dealloc {
	if(latestData)
		[latestData release];
	if(theCycles)
		[theCycles release];
	if(theCapcity)
		[theCapcity release];
	[super dealloc];
}


- (BOOL) isLaptop {
	SInt32 machineName;
	Gestalt(gestaltUserVisibleMachineName, &machineName);
	NSString *theString = [NSString stringWithCString:(char *)machineName];
	NSString *substring = @"PowerBook";
	NSRange range = [theString rangeOfString:substring];
	int length = range.length;
	if(length){
			type = 0;
			return YES;
	} else {
		range = [theString rangeOfString:@"MacBook"];
		length = range.length;
		if(length){
			type = 1;
			return YES;
		} else {
			type = -1;
			return NO;
		}
	}
	type = -1;
	return NO;
}

- (NSArray *)getDataSet {
	return latestData;
}

- (void)mineData {
	if(type == 0){
		[self getPB];
	} else if(type == 1) {
		[self getMBP];
	}
}

- (void)getMBP {		
	[[NSAutoreleasePool alloc] init];
	NSString* time = @"Unknown";
	NSString* source = @"Unknown";
	NSString* status = @"Unknown";
	NSString* percentage = @"0";
	NSString *cycles = @"0";
	NSNumber *max_capacity;
	NSNumber *current_capacity;
	NSNumber *capacity_percentage;
	
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;
    
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("AppleSmartBattery"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		[latestData release];
		latestData = [[NSArray arrayWithObjects:@"Unknown",@"0",@"Unknown",@"Unknown",@"0", @"0%", nil] retain];
        return;
    }
    
    io_object_t sensorObject;
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }
		

		float percentageValue = ([[sensorData objectForKey:@"CurrentCapacity"] floatValue] / [[sensorData objectForKey:@"MaxCapacity"] floatValue]) * 100;
		percentage = [NSString stringWithFormat:@"%.0f%%",percentageValue];
		
		max_capacity = [NSNumber numberWithInt:[[sensorData objectForKey:@"DesignCapacity"] intValue]];
		current_capacity = [NSNumber numberWithInt:[[sensorData objectForKey:@"MaxCapacity"] intValue]];
		capacity_percentage = [NSNumber numberWithFloat:((float)[current_capacity floatValue] / (float)[max_capacity floatValue])*100];
		capacity_percentage = [NSNumber numberWithInt:[capacity_percentage intValue]];
		if([capacity_percentage intValue] > 100)
			capacity_percentage = [NSNumber numberWithInt:100];
		
		cycles = [NSString stringWithFormat:@"%i",[[sensorData objectForKey:@"CycleCount"] intValue]];
		if([[sensorData objectForKey:@"ExternalConnected"]intValue] == 1)
			source = @"AC Power";
		else
			source = @"Battery";
		
		if ( [[sensorData objectForKey:@"FullyCharged"] intValue] == 1 && [[sensorData objectForKey:@"ExternalConnected"]intValue] == 1) {
			time = @"Charged";
			status = @"Charged";
		} else if ( [[sensorData objectForKey:@"Amperage"] intValue] == 0 && [[sensorData objectForKey:@"IsCharging"] intValue] == 1) {
			time = @"Calculating";
			status = @"Charging";
		} else if ( [[sensorData objectForKey:@"IsCharging"] intValue] == 0 && [[sensorData objectForKey:@"Amperage"] intValue] >= 0) {
			time = @"Calculating";
			status = @"Draining";
		} else if([[sensorData objectForKey:@"ExternalConnected"]intValue] == 1 && [[sensorData objectForKey:@"Amperage"] intValue] < 0){
			time = @"Calculating";
			status = @"Draining";
		} else if(  [[sensorData objectForKey:@"IsCharging"] intValue] == 1) {
			status = @"Charging";
			int hours = 0;
			int startNS = [[sensorData objectForKey:@"TimeRemaining"] intValue];
			hours = startNS / (60);
			startNS %= (60);
			if(startNS < 10){
				time = [NSString stringWithFormat:@"%i:0%i until charged",hours,startNS];
			} else {
				time = [NSString stringWithFormat:@"%i:%i until charged",hours,startNS];
			}
		} else {
			status = @"Draining";
			int hours = 0;
			int startNS = [[sensorData objectForKey:@"TimeRemaining"] intValue];
			hours = startNS / (60);
			startNS %= (60);
			if(startNS < 10){
				time = [NSString stringWithFormat:@"%i:0%i remaining",hours,startNS];
			} else {
				time = [NSString stringWithFormat:@"%i:%i remaining",hours,startNS];
			}
		}
		CFRelease(sensorData);
        IOObjectRelease(sensorObject);
	}
    IOObjectRelease(sensorsIterator);	

	[latestData release];
	latestData = [[NSArray arrayWithObjects:time,percentage,source,status,cycles,[NSString stringWithFormat:@"%@%% (%imAh)",capacity_percentage, [current_capacity intValue]],nil] retain];
	
}

- (NSString *)getPB {
	[[NSAutoreleasePool alloc] init];
	NSArray *powerSources = (NSArray *)IOPSCopyPowerSourcesList( IOPSCopyPowerSourcesInfo());
    NSEnumerator *powerEnumerator = [powerSources objectEnumerator];
    CFTypeRef itemRef;
    NSDictionary *itemData;
	NSString* time = @"Unknown";
	NSString* source = @"Unknown";
	NSString* status = @"Unknown";
	NSString* percentage = @"0%";
		
	while( itemRef = [powerEnumerator nextObject] )
    {
        itemData = (NSDictionary *)IOPSGetPowerSourceDescription( IOPSCopyPowerSourcesInfo(), itemRef);
        if([[itemData objectForKey:@"Transport Type"] isEqualToString: @"Internal"])
        {
			percentage = [NSString stringWithFormat:@"%@%%",[itemData objectForKey:@"Current Capacity"]];
			if([[itemData objectForKey:@"Power Source State"] isEqualToString:@"AC Power"]){
				source = @"AC Power";
				if([[itemData objectForKey:@"Time to Full Charge"] intValue] < 0){
					if([[itemData objectForKey:@"Is Charging"] intValue] == 0){
						time = @"Charged";
						status = @"Charged";
					} else {
						time = @"Calculating";
						status = @"Charging";
					}
				} else {
						status = @"Charging";
					int hours = 0;
					int startNS = [[itemData objectForKey:@"Time to Full Charge"] intValue];
					hours = startNS / (60);
					startNS %= (60);
					if(startNS < 10){
						time = [NSString stringWithFormat:@"%i:0%i until charged",hours,startNS];
					} else {
						time = [NSString stringWithFormat:@"%i:%i until charged",hours,startNS];
					}
				}
			}
			if([[itemData objectForKey:@"Power Source State"] isEqualToString:@"Battery Power"]){
				source = @"Battery";
				if([[itemData objectForKey:@"Time to Empty"] intValue] < 0){
						time = @"Calculating";
						status = @"Draining";
				} else {
						status = @"Draining";
					int hours = 0;
					int startNS = [[itemData objectForKey:@"Time to Empty"] intValue];
					hours = startNS / (60);
					startNS %= (60);
					if(startNS < 10){
						time = [NSString stringWithFormat:@"%i:0%i remaining",hours,startNS];
					} else {
						time = [NSString stringWithFormat:@"%i:%i remaining",hours,startNS];
					}
				}
			}
			break;
		}
    }
	[latestData release];
	latestData = [[NSArray arrayWithObjects:time,percentage,source,status,[self getCycles],theCapcity,nil] retain];
}

- (NSString *)getCycles {
	if(cyclePos==5)
		cyclePos = 0;
	if(cyclePos==0)
		[self updateCycles];
	cyclePos++;
	return theCycles;
}

- (void)updateCycles {
	BOOL found = NO;
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;

    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOPMrootDomain"), &sensorsIterator);
	
    if (ioStatus != kIOReturnSuccess) {
		if(theCycles)
			[theCycles release];
		theCycles = [NSString stringWithFormat:@"0"];
		[theCycles retain];

		if(theCapcity)
			[theCapcity release];
		theCapcity = [NSString stringWithFormat:@"0%"];
		[theCapcity retain];
 
		return;
    }
    
    io_object_t sensorObject;
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
		if([sensorData objectForKey:@"IOBatteryInfo"] && ([[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] count] > 0)){
			found = YES;

			if(theCycles)
				[theCycles release];
			theCycles = [NSString stringWithFormat:@"%@",[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Cycle Count"]];
			[theCycles retain];

			if(theCapcity)
				[theCapcity release];

			NSNumber *max_capacity = [NSNumber numberWithInt:[[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"AbsoluteMaxCapacity"] intValue]];
			NSNumber *current_capacity = [NSNumber numberWithInt:[[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Capacity"] intValue]];
			float cur_cacp = [current_capacity intValue] / [max_capacity intValue];
			NSNumber *capacity_percentage = [NSNumber numberWithFloat:((float)[current_capacity floatValue] / (float)[max_capacity floatValue])*100];
			capacity_percentage = [NSNumber numberWithInt:[capacity_percentage intValue]];
			if([capacity_percentage intValue] > 100)
				capacity_percentage = [NSNumber numberWithInt:100];

			theCapcity = [NSString stringWithFormat:@"%@%% (%imA)",capacity_percentage, [current_capacity intValue]];
			[theCapcity retain];
		}
		[sensorData release];
        IOObjectRelease(sensorObject);
	}
    IOObjectRelease(sensorsIterator);	

	if(!found){
		ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("AppleSMUDevice"), &sensorsIterator);
	
		if (ioStatus != kIOReturnSuccess) {
			if(theCycles)
				[theCycles release];
			theCycles = [NSString stringWithFormat:@"0"];
			[theCycles retain];

			if(theCapcity)
				[theCapcity release];
			theCapcity = [NSString stringWithFormat:@"0%"];
			[theCapcity retain];
 
			return;
		}
    
		io_object_t sensorObject;
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if([sensorData objectForKey:@"IOBatteryInfo"] && ([[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] count] > 0)){
				found = YES;

				if(theCycles)
					[theCycles release];
				theCycles = [NSString stringWithFormat:@"%@",[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Cycle Count"]];
				[theCycles retain];

				if(theCapcity)
					[theCapcity release];

				NSNumber *max_capacity = [NSNumber numberWithInt:[[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"AbsoluteMaxCapacity"] intValue]];
				NSNumber *current_capacity = [NSNumber numberWithInt:[[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Capacity"] intValue]];
				float cur_cacp = [current_capacity intValue] / [max_capacity intValue];
				NSNumber *capacity_percentage = [NSNumber numberWithFloat:((float)[current_capacity floatValue] / (float)[max_capacity floatValue])*100];
				capacity_percentage = [NSNumber numberWithInt:[capacity_percentage intValue]];
				if([capacity_percentage intValue] > 100)
					capacity_percentage = [NSNumber numberWithInt:100];

				theCapcity = [NSString stringWithFormat:@"%@%% (%imAh)",capacity_percentage, [current_capacity intValue]];
				[theCapcity retain];
			}
			[sensorData release];
			IOObjectRelease(sensorObject);
		}
		IOObjectRelease(sensorsIterator);	
	}
}

@end