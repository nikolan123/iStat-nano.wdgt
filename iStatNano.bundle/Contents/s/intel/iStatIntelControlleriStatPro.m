//
//  Controller.m
//  IntelSensors
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.

#import "iStatIntelControlleriStatPro.h"
#import <smc.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <IOKit/IOKitLib.h>

@implementation iStatIntelControlleriStatPro

io_connect_t conn2;
kern_return_t result;
SMCVal_t      val;

- (void) dealloc {
	[availableKeys release];
	[supportedKeys release];
	[keyDisplayNames release];
	[priorities release];

	SMCClose(&conn2);
	smc_close();	
	[super dealloc];
}


- (id)init {
	self = [super init];
	result = SMCOpen(&conn2);
    if (result != kIOReturnSuccess){
		supported = NO;
		return self;
	}
	supported = YES;
	smc_init();
	
	supportedKeys = [[NSMutableArray alloc] init];
	[self setKeys];
	[self findSupportedKeys];
	
	return self;
}

- (BOOL)isSupported {
	return supported;
}

- (void)setKeys {
	availableKeys = [[NSMutableArray alloc] init];
	[availableKeys addObject:@"TC0H"];
	[availableKeys addObject:@"TC0D"];
	[availableKeys addObject:@"TC1D"];
	[availableKeys addObject:@"TCAH"];
	[availableKeys addObject:@"TCBH"];
	[availableKeys addObject:@"TG0P"];
	[availableKeys addObject:@"TA0P"];
	[availableKeys addObject:@"TH0P"];
	[availableKeys addObject:@"TO0P"];
	[availableKeys addObject:@"TH1P"];
	[availableKeys addObject:@"TH2P"];
	[availableKeys addObject:@"TH3P"];
	[availableKeys addObject:@"Th0H"];
	[availableKeys addObject:@"Th1H"];
	[availableKeys addObject:@"TG0H"];
	[availableKeys addObject:@"TG0D"];
	[availableKeys addObject:@"Tp1C"];
	[availableKeys addObject:@"Tp0C"];
	[availableKeys addObject:@"TB0T"];
	[availableKeys addObject:@"TN0P"];
	[availableKeys addObject:@"TN1P"];
	[availableKeys addObject:@"TN0H"];
	[availableKeys addObject:@"TM0S"];
	[availableKeys addObject:@"TM1S"];
	[availableKeys addObject:@"TM2S"];
	[availableKeys addObject:@"TM3S"];
	[availableKeys addObject:@"TM4S"];
	[availableKeys addObject:@"TM5S"];
	[availableKeys addObject:@"TM6S"];
	[availableKeys addObject:@"TM7S"];
	[availableKeys addObject:@"TM8S"];
	[availableKeys addObject:@"TM9S"];
	[availableKeys addObject:@"TMAS"];
	[availableKeys addObject:@"TMBS"];
	[availableKeys addObject:@"TMCS"];
	[availableKeys addObject:@"TMDS"];
	[availableKeys addObject:@"TMES"];
	[availableKeys addObject:@"TMFS"];
	[availableKeys addObject:@"TM0P"];
	[availableKeys addObject:@"TM1P"];
	[availableKeys addObject:@"TM2P"];
	[availableKeys addObject:@"TM3P"];
	[availableKeys addObject:@"TM4P"];
	[availableKeys addObject:@"TM5P"];
	[availableKeys addObject:@"TM6P"];
	[availableKeys addObject:@"TM7P"];
	[availableKeys addObject:@"TM8P"];
	[availableKeys addObject:@"TM9P"];
	[availableKeys addObject:@"TMAP"];
	[availableKeys addObject:@"TMBP"];
	[availableKeys addObject:@"TMCP"];
	[availableKeys addObject:@"TMDP"];
	[availableKeys addObject:@"TMEP"];
	[availableKeys addObject:@"TMFP"];
	[availableKeys addObject:@"Tm0P"];
	[availableKeys addObject:@"TS0C"];
	[availableKeys addObject:@"TW0P"];
	[availableKeys addObject:@"Tp0P"];

	// intel xserve sensors
	[availableKeys addObject:@"TA0S"]; // pci slot 1 sensor 1
	[availableKeys addObject:@"TA1S"]; // pci slot 1 sensor 2
	[availableKeys addObject:@"TA2S"]; // pci slot 2 sensor 1
	[availableKeys addObject:@"TA3S"]; // pci slot 2 sensor 2
	[availableKeys addObject:@"TA1P"]; // Ambient 2
	[availableKeys addObject:@"Tp1P"]; // power supply 2
	[availableKeys addObject:@"Tp2P"]; // power supply 3
	[availableKeys addObject:@"Tp3P"]; // power supply 4
	[availableKeys addObject:@"Tp4P"]; // power supply 5
	[availableKeys addObject:@"Tp5P"]; // power supply 5

	keyDisplayNames = [[NSMutableDictionary alloc] init];
	[keyDisplayNames setValue:@"Memory Controller" forKey:@"Tm0P"];
	[keyDisplayNames setValue:@"Mem Bank A1" forKey:@"TM0P"];
	[keyDisplayNames setValue:@"Mem Bank A2" forKey:@"TM1P"];
	[keyDisplayNames setValue:@"Mem Bank A3" forKey:@"TM2P"];
	[keyDisplayNames setValue:@"Mem Bank A4" forKey:@"TM3P"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank A5" forKey:@"TM4P"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank A6" forKey:@"TM5P"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank A7" forKey:@"TM6P"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank A8" forKey:@"TM7P"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank B1" forKey:@"TM8P"];
	[keyDisplayNames setValue:@"Mem Bank B2" forKey:@"TM9P"];
	[keyDisplayNames setValue:@"Mem Bank B3" forKey:@"TMAP"];
	[keyDisplayNames setValue:@"Mem Bank B4" forKey:@"TMBP"];  // guessing
	[keyDisplayNames setValue:@"Mem Bank B5" forKey:@"TMCP"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank B6" forKey:@"TMDP"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank B7" forKey:@"TMEP"]; // guessing
	[keyDisplayNames setValue:@"Mem Bank B8" forKey:@"TMFP"]; // guessing
	[keyDisplayNames setValue:@"Mem module A1" forKey:@"TM0S"];
	[keyDisplayNames setValue:@"Mem module A2" forKey:@"TM1S"];
	[keyDisplayNames setValue:@"Mem module A3" forKey:@"TM2S"];
	[keyDisplayNames setValue:@"Mem module A4" forKey:@"TM3S"];// guessing
	[keyDisplayNames setValue:@"Mem module A5" forKey:@"TM4S"]; // guessing
	[keyDisplayNames setValue:@"Mem module A6" forKey:@"TM5S"]; // guessing
	[keyDisplayNames setValue:@"Mem module A7" forKey:@"TM6S"]; // guessing
	[keyDisplayNames setValue:@"Mem module A8" forKey:@"TM7S"]; // guessing
	[keyDisplayNames setValue:@"Mem module B1" forKey:@"TM8S"];
	[keyDisplayNames setValue:@"Mem module B2" forKey:@"TM9S"];
	[keyDisplayNames setValue:@"Mem module B3" forKey:@"TMAS"]; 
	[keyDisplayNames setValue:@"Mem module B4" forKey:@"TMBS"]; // guessing
	[keyDisplayNames setValue:@"Mem module B5" forKey:@"TMCS"]; // guessing
	[keyDisplayNames setValue:@"Mem module B6" forKey:@"TMDS"]; // guessing
	[keyDisplayNames setValue:@"Mem module B7" forKey:@"TMES"]; // guessing
	[keyDisplayNames setValue:@"Mem module B8" forKey:@"TMFS"]; // guessing
	[keyDisplayNames setValue:@"CPU A" forKey:@"TC0H"];
	[keyDisplayNames setValue:@"CPU A" forKey:@"TC0D"];
	[keyDisplayNames setValue:@"CPU B" forKey:@"TC1D"];
	[keyDisplayNames setValue:@"CPU A" forKey:@"TCAH"];
	[keyDisplayNames setValue:@"CPU B" forKey:@"TCBH"];
	[keyDisplayNames setValue:@"GPU" forKey:@"TG0P"];
	[keyDisplayNames setValue:@"Ambient" forKey:@"TA0P"];
	[keyDisplayNames setValue:@"HD Bay 1" forKey:@"TH0P"];
	[keyDisplayNames setValue:@"HD Bay 2" forKey:@"TH1P"];
	[keyDisplayNames setValue:@"HD Bay 3" forKey:@"TH2P"];
	[keyDisplayNames setValue:@"HD Bay 4" forKey:@"TH3P"];
	[keyDisplayNames setValue:@"Optical Drive" forKey:@"TO0P"];
	[keyDisplayNames setValue:@"Heatsink A" forKey:@"Th0H"];
	[keyDisplayNames setValue:@"Heatsink B" forKey:@"Th1H"];
	[keyDisplayNames setValue:@"GPU Diode" forKey:@"TG0D"];
	[keyDisplayNames setValue:@"GPU Heatsink" forKey:@"TG0H"];
	[keyDisplayNames setValue:@"Power supply 2" forKey:@"Tp1C"];
	[keyDisplayNames setValue:@"Power supply 1" forKey:@"Tp0C"];
	[keyDisplayNames setValue:@"Power supply 1" forKey:@"Tp0P"];
	[keyDisplayNames setValue:@"Enclosure Bottom" forKey:@"TB0T"];
	[keyDisplayNames setValue:@"Northbridge 1" forKey:@"TN0P"];
	[keyDisplayNames setValue:@"Northbridge 2" forKey:@"TN1P"];
	[keyDisplayNames setValue:@"Northbridge" forKey:@"TN0H"];
	[keyDisplayNames setValue:@"Expansion Slots" forKey:@"TS0C"];
	[keyDisplayNames setValue:@"Airport Card" forKey:@"TW0P"];

	[keyDisplayNames setValue:@"PCI Slot 1 Pos 1" forKey:@"TA0S"];
	[keyDisplayNames setValue:@"PCI Slot 1 Pos 2" forKey:@"TA1S"];
	[keyDisplayNames setValue:@"PCI Slot 2 Pos 1" forKey:@"TA2S"];
	[keyDisplayNames setValue:@"PCI Slot 2 Pos 2" forKey:@"TA3S"];
	[keyDisplayNames setValue:@"Ambient 2" forKey:@"TA1P"];
	[keyDisplayNames setValue:@"Power supply 2" forKey:@"Tp1P"];
	[keyDisplayNames setValue:@"Power supply 3" forKey:@"Tp2P"];
	[keyDisplayNames setValue:@"Power supply 4" forKey:@"Tp3P"];
	[keyDisplayNames setValue:@"Power supply 5" forKey:@"Tp4P"];
	[keyDisplayNames setValue:@"Power supply 6" forKey:@"Tp5P"];

	priorities = [[NSMutableDictionary alloc] init];
	[priorities setValue:[NSNumber numberWithInt:1] forKey:@"TC0H"];
	[priorities setValue:[NSNumber numberWithInt:1] forKey:@"TC0D"];
	[priorities setValue:[NSNumber numberWithInt:1] forKey:@"TC1D"];
	[priorities setValue:[NSNumber numberWithInt:1] forKey:@"TCAH"];
	[priorities setValue:[NSNumber numberWithInt:1] forKey:@"TCBH"];
	[priorities setValue:[NSNumber numberWithInt:2] forKey:@"TG0P"];
	[priorities setValue:[NSNumber numberWithInt:3] forKey:@"TA0P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TH0P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TH1P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TH2P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TH3P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TO0P"];
	[priorities setValue:[NSNumber numberWithInt:2] forKey:@"Th0H"];
	[priorities setValue:[NSNumber numberWithInt:2] forKey:@"Th1H"];
	[priorities setValue:[NSNumber numberWithInt:2] forKey:@"TG0D"];
	[priorities setValue:[NSNumber numberWithInt:2] forKey:@"TG0H"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp1C"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp0C"];
	[priorities setValue:[NSNumber numberWithInt:3] forKey:@"TB0T"];
	[priorities setValue:[NSNumber numberWithInt:3] forKey:@"TN0P"];
	[priorities setValue:[NSNumber numberWithInt:3] forKey:@"TN1P"];
	[priorities setValue:[NSNumber numberWithInt:3] forKey:@"TN0H"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM0S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM1S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM2S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM3S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM4S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM5S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM6S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM7S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM8S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM9S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMAS"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMBS"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMCS"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMDS"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMES"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMFS"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM0P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM1P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM2P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM3P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM4P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM5P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM6P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM7P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM8P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TM9P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMAP"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMBP"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMCP"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMDP"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMEP"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TMFP"];
	[priorities setValue:[NSNumber numberWithInt:3] forKey:@"Tm0P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TS0C"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TW0P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp0P"];

	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TA0S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TA1S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TA2S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TA3S"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"TA1P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp1P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp2P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp3P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp4P"];
	[priorities setValue:[NSNumber numberWithInt:4] forKey:@"Tp5P"];
}

- (void)findSupportedKeys {
    SMCVal_t      val;
	
	NSEnumerator *keyEnumerator = [availableKeys objectEnumerator];
	NSString *key;
	while(key = [keyEnumerator nextObject]){
		result = SMCReadKey2([key cString], &val,conn2);
		if (result == kIOReturnSuccess){
			if (val.dataSize > 0) {
				if(((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64 <= 0)
					continue;
				
				[supportedKeys addObject:key];
			}
		}
	}
}

- (NSArray *)getFans {
    kern_return_t result;
    SMCVal_t      val;
    UInt32Char_t  key;
    int           totalFans, i;

    result = SMCReadKey("FNum", &val);
    if (result != kIOReturnSuccess)
        return [NSArray array];

   totalFans = _strtoul(val.bytes, val.dataSize, 10); 

	NSMutableArray *fans = [[NSMutableArray alloc] init];
    for (i = 0; i < totalFans; i++)
    {
        sprintf(key, "F%dAc", i); 
        SMCReadKey(key, &val); 
		[fans addObject:[NSString stringWithFormat:@"Fan %i",i]];
    }

	return [fans autorelease];
}


// getFanName - originally from smcFanControl
- (NSString *)getFanName:(int)number {
	UInt32Char_t  key;
	char temp;
	SMCVal_t      val;
	kern_return_t result;
	NSMutableString *desc;
	desc = [[NSMutableString alloc]init];
	sprintf(key, "F%dID", number);
	result = SMCReadKey2(key, &val,conn2);
	int i;
	for (i = 0; i < val.dataSize; i++) {
		if ((int)val.bytes[i ] >32) {
			temp = (unsigned char)val.bytes[i];
			[desc appendFormat:@"%c",temp];
		}
	}
	
	if([desc length] == 0)
		[desc setString:[NSString stringWithFormat:@"Fan %i",number]];
	return [desc autorelease];
}	

- (NSDictionary *)getFanValues {
    SMCVal_t      val;
    UInt32Char_t  key;
    int           totalFans, i;

    result = SMCReadKey("FNum", &val);
    if (result != kIOReturnSuccess)
        return [NSDictionary dictionary];

	totalFans = _strtoul(val.bytes, val.dataSize, 10); 

	NSMutableDictionary *fans = [[NSMutableDictionary alloc] init];
    for (i = 0; i < totalFans; i++) {
        sprintf(key, "F%dAc", i); 
        SMCReadKey(key, &val); 
		[fans setValue:[NSString stringWithFormat:@"%@rpm",[NSNumber numberWithInt:_strtof(val.bytes, val.dataSize, 2)]] forKey:[self getFanName:i]];
	}

	return [fans autorelease];
}

- (NSDictionary *)getTempValues {
	NSMutableArray *values = [[NSMutableArray alloc] init];
	NSMutableArray *priorityOne = [[NSMutableArray alloc] init];
	NSMutableArray *priorityTwo = [[NSMutableArray alloc] init];
	NSMutableArray *priorityThree = [[NSMutableArray alloc] init];
	NSMutableArray *priorityFour = [[NSMutableArray alloc] init];

    SMCVal_t val;
	
	NSEnumerator *keyEnumerator = [supportedKeys objectEnumerator];
	NSString *key;
	while(key = [keyEnumerator nextObject]){
		result = SMCReadKey2([key cString], &val, conn2);
		if (result == kIOReturnSuccess){
			if (val.dataSize > 0) {
				if(((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64 == 0)
					continue;
					
				if([[priorities objectForKey:key] intValue] == 1)
					[priorityOne addObject:[NSArray arrayWithObjects:[keyDisplayNames objectForKey:key], [NSNumber numberWithInt:((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64], nil]];
				
				if([[priorities objectForKey:key] intValue] == 2)
					[priorityTwo addObject:[NSArray arrayWithObjects:[keyDisplayNames objectForKey:key], [NSNumber numberWithInt:((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64], nil]];
				
				if([[priorities objectForKey:key] intValue] == 3)
					[priorityThree addObject:[NSArray arrayWithObjects:[keyDisplayNames objectForKey:key], [NSNumber numberWithInt:((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64], nil]];
				
				if([[priorities objectForKey:key] intValue] == 4)
					[priorityFour addObject:[NSArray arrayWithObjects:[keyDisplayNames objectForKey:key], [NSNumber numberWithInt:((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64], nil]];
			}	
		}
	}

	[priorityOne sortUsingSelector:@selector(compare:)];
	[priorityTwo sortUsingSelector:@selector(compare:)];
	[priorityThree sortUsingSelector:@selector(compare:)];
	[priorityFour sortUsingSelector:@selector(compare:)];
	
	[values addObject:priorityOne];
	[values addObject:priorityTwo];
	[values addObject:priorityThree];
	[values addObject:priorityFour];

	[priorityOne release];
	[priorityTwo release];
	[priorityThree release];
	[priorityFour release];

	return [values autorelease];
}

@end
