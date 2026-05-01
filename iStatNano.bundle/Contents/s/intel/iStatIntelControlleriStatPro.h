//
//  Controller.h
//  IntelSensors
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.

#import <Cocoa/Cocoa.h>


@interface iStatIntelControlleriStatPro : NSObject {
	BOOL supported;
	NSMutableArray *availableKeys;
	NSMutableArray *supportedKeys;
	NSMutableDictionary *keyDisplayNames;
	NSMutableDictionary *priorities;
}

- (NSArray *)getFans;
- (BOOL)isSupported;
- (void)setKeys;
- (void)findSupportedKeys;
- (NSArray *)getFans;
- (NSString *)getFanName:(int)number;
- (NSDictionary *)getFanValues;
- (NSDictionary *)getTempValues;

@end
