//
//  ISNDataMinerFans.m
//  iStatMenusFans
//
//  Created by Buffy on 2/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerFans.h"


@implementation ISNDataMinerFans

- (void) dealloc {
	if(intelClassInstance)
		[intelClassInstance release];
		
	[availableSensors release];
	[validFanSensors release];
	[fanSensorPriority release];
	[fanSensorName release];
	
	if(latestData)
		[latestData release];
		
	mach_port_deallocate(mach_task_self(), machport);
	[super dealloc];
}


- (id)init {
	self = [super init];

	sensorArray = NO;
	
	intelClassInstance = nil;

	if([self isIntel])
		intelClassInstance = [[iStatIntelControlleriStatPro alloc] init];
//	NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/iStatIntelSensorsV3.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
//	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
//		Class intelClass;
//		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
//		if(intelBundle != nil){
//			if (intelClass = [intelBundle principalClass])
//				intelClassInstance = [[intelClass alloc] init];
//		}
//	}
	
	availableSensors = [[NSMutableArray alloc] init];
	validFanSensors = [[NSMutableDictionary alloc] init];
	fanSensorPriority = [[NSMutableDictionary alloc] init];
	fanSensorName = [[NSMutableDictionary alloc] init];

	[self setDictionaries];
	[self getDataSet];
	sensorArray = YES;

	return self;
}

- (void)moduleInstalled {
	NSLog(@"Intel Module now available - fans");
	NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/iStatIntelSensorsV3.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
		Class intelClass;
		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
		if(intelBundle != nil){
			if (intelClass = [intelBundle principalClass])
				intelClassInstance = [[intelClass alloc] init];
			
			sensorArray = NO;
			[availableSensors removeAllObjects];
			[self update];
			sensorArray = YES;
		}
	}
}

- (NSArray *)sensors {
	return availableSensors;
}

- (BOOL)isIntel {
	OSType		returnType;
	long		gestaltReturnValue;
	
	returnType=Gestalt(gestaltSysArchitecture, &gestaltReturnValue);
	
	if (!returnType && gestaltReturnValue == gestaltIntel)
		return YES;

	return NO;
}

- (BOOL)hasIntelBundle {
	NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/IntelSensorsiStatPro.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
		if(intelBundle != nil){
			return YES;
		}
	}
	return NO;
}

- (void)setDictionaries {

	[validFanSensors setObject:@"65536" forKey:@"Hard drive"];			//Powerbook Cpu - all rev's ?
	[fanSensorName setObject:@"Hard Drive" forKey:@"Hard drive"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"2" forKey:@"Hard drive"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"DRIVE BAY A INTAKE"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"Drive Bay" forKey:@"DRIVE BAY A INTAKE"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"3" forKey:@"DRIVE BAY A INTAKE"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"EXPANSION SLOTS INTAKE"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"Slots Intake" forKey:@"EXPANSION SLOTS INTAKE"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"4" forKey:@"EXPANSION SLOTS INTAKE"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"65536" forKey:@"REAR LEFT EXHAUST"];		//Incoming Air Temp - iMacs
	[fanSensorName setObject:@"Rear Exhaust" forKey:@"REAR LEFT EXHAUST"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"3" forKey:@"REAR LEFT EXHAUST"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"65536" forKey:@"REAR RIGHT EXHAUST"];		//Incoming Air Temp - iMacs
	[fanSensorName setObject:@"Rear right Exhaust" forKey:@"REAR RIGHT EXHAUST"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"3" forKey:@"REAR RIGHT EXHAUST"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"65536" forKey:@"PCI SLOTS"];				//Unknown -17" Powerbook
	[fanSensorName setObject:@"PCI Slots" forKey:@"PCI SLOTS"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"4" forKey:@"PCI SLOTS"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"65536" forKey:@"CPU A INLET"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU A Inlet" forKey:@"CPU A INLET"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU A INLET"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"65536" forKey:@"CPU B INLET"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU B Inlet" forKey:@"CPU B INLET"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU B INLET"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU Fan"];					//Cpu Fan - iMacs - Gen 2 and 3
	[fanSensorName setObject:@"CPU" forKey:@"CPU Fan"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU Fan"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"ODD Fan"];					//Optical Drive Fan ? -iMacs
	[fanSensorName setObject:@"Optical Drive" forKey:@"ODD Fan"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"2" forKey:@"ODD Fan"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"HDD Fan"];					//Hard Drive Fan -iMacs
	[fanSensorName setObject:@"Hard Drive" forKey:@"HDD Fan"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"2" forKey:@"HDD Fan"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"System Fan"];					//System Fan - G5 iMacs rev b
	[fanSensorName setObject:@"System" forKey:@"System Fan"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"2" forKey:@"System Fan"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"Hard Drive"];					//hard Drive Fan - G5 iMacs rev b
	[fanSensorName setObject:@"Hard Drive" forKey:@"Hard Drive"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"2" forKey:@"Hard Drive"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"65536" forKey:@"REAR MAIN ENCLOSURE"];	//Fan - 12" Powerbooks
	[fanSensorName setObject:@"Rear Enclosure" forKey:@"REAR MAIN ENCLOSURE"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"2" forKey:@"REAR MAIN ENCLOSURE"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU B PUMP"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU B Pump" forKey:@"CPU B PUMP"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU B PUMP"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU A PUMP"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU A Pump" forKey:@"CPU A PUMP"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU A PUMP"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU A INTAKE"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU A Intake" forKey:@"CPU A INTAKE"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU A INTAKE"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU A EXHAUST"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU A Exhaust" forKey:@"CPU A EXHAUST"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU A EXHAUST"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU B INTAKE"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU B Intake" forKey:@"CPU B INTAKE"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU B INTAKE"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"CPU B EXHAUST"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU B Exhaust" forKey:@"CPU B EXHAUST"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU B EXHAUST"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"DRIVE BAY"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"Drive Bay" forKey:@"DRIVE BAY"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"3" forKey:@"DRIVE BAY"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"SLOT"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"Slots" forKey:@"SLOT"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"4" forKey:@"SLOT"];			//Powerbook Cpu - all rev's ?

	[validFanSensors setObject:@"1" forKey:@"BACKSIDE"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"Backside" forKey:@"BACKSIDE"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"4" forKey:@"BACKSIDE"];			//Powerbook Cpu - all rev's ?
	
	[validFanSensors setObject:@"1" forKey:@"CPU fan"];			//Unknown -17" Powerbook
	[fanSensorName setObject:@"CPU" forKey:@"CPU fan"];			//Powerbook Cpu - all rev's ?
	[fanSensorPriority setObject:@"1" forKey:@"CPU fan"];			//Powerbook Cpu - all rev's ?

	[fanSensorName setObject:@"Hard Drive/Expansion" forKey:@"IO"];			//mac pro
	[fanSensorName setObject:@"Exhaust" forKey:@"EXHAUST"];			//mac pro
	[fanSensorName setObject:@"Power Supply" forKey:@"PS"];			//mac pro
	[fanSensorName setObject:@"CPU Fan" forKey:@"CPU_MEM"];			//mac pro
	[fanSensorName setObject:@"Left Fan" forKey:@"Leftside"];			//macbook pros
	[fanSensorName setObject:@"Right Fan" forKey:@"Rightside"];			//macbook pros
	[fanSensorName setObject:@"Main Fan" forKey:@"Master"];			//intel mac mini
	[fanSensorName setObject:@"Optical Drive" forKey:@"ODD"];			//24 inch imac
	[fanSensorName setObject:@"CPU Fan" forKey:@"CPU"];			//24 inch imac
	[fanSensorName setObject:@"Hard Drive" forKey:@"HDD"];			//24 inch imac
}

- (NSArray *)getDataSet {
	NSMutableArray *theData = [[NSMutableArray alloc] init];

	if(intelClassInstance!= nil){
		@try { 
			NSDictionary *temps = [intelClassInstance getFanValues];
								
			NSEnumerator *itemEnumerator = [temps keyEnumerator];
			NSString *key;
			while(key = [itemEnumerator nextObject]){
				if(!sensorArray)
					[availableSensors addObject:key];
				
				if([fanSensorName valueForKey:key] != NULL)
					[theData addObject:[NSArray arrayWithObjects:[fanSensorName valueForKey:key], [temps valueForKey:key], nil]];
				else
					[theData addObject:[NSArray arrayWithObjects:key, [temps valueForKey:key], nil]];
			}
		}

		@catch ( NSException *e ) {  
			return [NSArray array];
		}
		return [theData autorelease];
	}

	NSMutableDictionary *priorityOne = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *priorityTwo = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *priorityThree = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *priorityFour = [[NSMutableDictionary alloc] init];
		
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;    
        
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOHWControl"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    io_object_t sensorObject;
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }
		

		NSString *sensorType = [sensorData objectForKey:@"type"];
			if([validFanSensors objectForKey:[sensorData objectForKey:@"location"]] != NULL && ([sensorType isEqualToString:@"fan-rpm"] || [sensorType isEqualToString:@"fanspeed"])){
				if(!sensorArray)
					[availableSensors addObject:[fanSensorName valueForKey:[sensorData valueForKey:@"location"]]];

				id currentValue = [NSNumber numberWithInt:0];
				id targetValue = [NSNumber numberWithInt:0];
				if([sensorData objectForKey:@"target-value"])
					targetValue = [sensorData objectForKey:@"target-value"];
				if([sensorData objectForKey:@"current-value"])
					currentValue = [sensorData objectForKey:@"current-value"];

				int currentSpeed = [currentValue intValue] / [[validFanSensors objectForKey:[sensorData objectForKey:@"location"]] intValue];
				int targetSpeed = [targetValue intValue] / [[validFanSensors objectForKey:[sensorData objectForKey:@"location"]] intValue];

				int value = 0;
				if(value == 0 && targetSpeed != 0)
					value = targetSpeed;
				if(value == 0 && currentSpeed != 0)
					value = currentSpeed;

				if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 1){
					[priorityOne setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 2){
					[priorityTwo setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 3){
					[priorityThree setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 4){
					[priorityFour setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				}
			}
        CFRelease(sensorData);
        IOObjectRelease(sensorObject);
    }
    IOObjectRelease(sensorsIterator);
	
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("AppleFCU"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }

    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }

		NSArray *userPrefsDictionary1 = [NSArray arrayWithArray:(NSArray *)[sensorData objectForKey:@"control-info"]];

		NSEnumerator *mountedPathsEnumerator = [userPrefsDictionary1 objectEnumerator];
		NSArray *fanSensor;
		while (fanSensor = [mountedPathsEnumerator nextObject] ){
			if([validFanSensors objectForKey:[fanSensor valueForKey:@"location"]] != NULL){
				if(!sensorArray)
					[availableSensors addObject:[fanSensorName valueForKey:[fanSensor valueForKey:@"location"]]];
				id currentValue = [fanSensor valueForKey:@"target-value"];
			
				int tempInt;
				tempInt = [currentValue intValue];
				int value=tempInt/[[validFanSensors objectForKey:[fanSensor valueForKey:@"location"]] intValue];

				if([[fanSensorPriority objectForKey:[fanSensor valueForKey:@"location"]] intValue] == 1){
					[priorityOne setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[fanSensor valueForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[fanSensor valueForKey:@"location"]] intValue] == 2){
					[priorityTwo setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[fanSensor valueForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[fanSensor valueForKey:@"location"]] intValue] == 3){
					[priorityThree setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[fanSensor valueForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[fanSensor valueForKey:@"location"]] intValue] == 4){
					[priorityFour setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[fanSensor valueForKey:@"location"]]];
				}
			}
		}
	
		CFRelease(sensorData);
        IOObjectRelease(sensorObject);
    }
    IOObjectRelease(sensorsIterator);	
	
	if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOHWSensor"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData,  kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }
		

		NSString *sensorType = [sensorData objectForKey:@"type"];
			if([validFanSensors objectForKey:[sensorData objectForKey:@"location"]] != NULL && ([sensorType isEqualToString:@"fan-rpm"] || [sensorType isEqualToString:@"fanspeed"])){
				if(!sensorArray)
					[availableSensors addObject:[fanSensorName valueForKey:[sensorData valueForKey:@"location"]]];

				id currentValue = [NSNumber numberWithInt:0];
				id targetValue = [NSNumber numberWithInt:0];
				if([sensorData objectForKey:@"target-value"])
					targetValue = [sensorData objectForKey:@"target-value"];
				if([sensorData objectForKey:@"current-value"])
					currentValue = [sensorData objectForKey:@"current-value"];

				int currentSpeed = [currentValue intValue] / [[validFanSensors objectForKey:[sensorData objectForKey:@"location"]] intValue];
				int targetSpeed = [targetValue intValue] / [[validFanSensors objectForKey:[sensorData objectForKey:@"location"]] intValue];

				int value = 0;
				if(value == 0 && targetSpeed != 0)
					value = targetSpeed;
				if(value == 0 && currentSpeed != 0)
					value = currentSpeed;

				if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 1){
					[priorityOne setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 2){
					[priorityTwo setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 3){
					[priorityThree setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				} else if([[fanSensorPriority objectForKey:[sensorData objectForKey:@"location"]] intValue] == 4){
					[priorityFour setObject:[NSString stringWithFormat:@"%irpm",value] forKey:[fanSensorName valueForKey:[sensorData objectForKey:@"location"]]];
				}
			}
        CFRelease(sensorData);
        IOObjectRelease(sensorObject);
    }
    IOObjectRelease(sensorsIterator);

	
	NSEnumerator *sensorEnumerator = [priorityOne keyEnumerator];
	NSString *key=@"";
	while(key = [sensorEnumerator nextObject]) {
		[theData addObject:[NSArray arrayWithObjects:key, [priorityOne objectForKey:key], nil]];
	}
	
	sensorEnumerator = [priorityTwo keyEnumerator];
	while(key = [sensorEnumerator nextObject]) {
		[theData addObject:[NSArray arrayWithObjects:key, [priorityTwo objectForKey:key], nil]];
	}
	
	sensorEnumerator = [priorityThree keyEnumerator];
	while(key = [sensorEnumerator nextObject]) {
		[theData addObject:[NSArray arrayWithObjects:key, [priorityThree objectForKey:key], nil]];
	}
	
	sensorEnumerator = [priorityFour keyEnumerator];
	while(key = [sensorEnumerator nextObject]) {
		[theData addObject:[NSArray arrayWithObjects:key, [priorityFour objectForKey:key], nil]];
	}
	return [theData autorelease];
}

@end
