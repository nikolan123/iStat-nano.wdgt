//
//  ISPSmartController.h
//  iStatPro
//
//  Created by Buffy on 11/06/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define kWindowSMARTsModelKeyString							@"model"
#define kWindowSMARTsFirmwareKeyString						@"firmware"
#define kWindowSMARTsSerialNumberKeyString					@"serialNumber"
#define kWindowSMARTsSMARTSupportKeyString					@"SMARTSupported"
#define kWindowSMARTsWriteCacheSupportKeyString				@"writeCacheSupported"
#define kWindowSMARTsPMSupportKeyString						@"powerManagementSupported"
#define kWindowSMARTsCFSupportKeyString						@"compactFlashSupported"
#define kWindowSMARTsAPMSupportKeyString					@"advancedPowerManagementSupported"
#define kWindowSMARTs48BitAddressingSupportKeyString		@"lba48Supported"
#define kWindowSMARTsFlushCacheCommandSupportKeyString		@"flushCacheSupported"
#define kWindowSMARTsFlushCacheExtCommandSupportKeyString	@"flushCacheExtSupported"
#define kWindowSMARTsQueueDepthKeyString					@"queueDepth"
#define kWindowSMARTsNCQSupportKeyString					@"NCQSupported"
#define kWindowSMARTsDeviceInitiatedPMKeyString				@"deviceCanInitiatePHYPowerManagement"
#define kWindowSMARTsHostInitiatedPMKeyString				@"deviceSupportsHostInitiatedPHYPowerManagement"
#define kWindowSMARTsInterfaceSpeedKeyString				@"interfaceSpeed"
#define kWindowSMARTsDeviceOkKeyString						@"deviceOK"
#define kWindowSMARTsDeviceTempKeyString					@"deviceTemp"
#define kWindowSMARTsDeviceMaxTempKeyString					@"deviceMaxTemp"
#define kWindowSMARTsDeviceLifetimeMaxTempKeyString			@"deviceLifetimeMaxTemp"
#define kWindowSMARTsDeviceTempThresholdKeyString			@"deviceTempThreshold"
#define kATADefaultSectorSize                             512

// The following attribute is optionally supported and is generally considered
// to be vendor-specific, although it appears that the majority of vendors
// do implement it.  For this sample code, this information was obtained from
// WikiPedia: <http://en.wikipedia.org/wiki/S.M.A.R.T.>
#define kWindowSMARTsDriveTempAttribute						0xC2


@interface ISNSmartController : NSObject {
	NSMutableArray *diskData;
	NSMutableArray *latestData;
	NSArray *temps;
	NSArray *disksStatus;
}

@end
