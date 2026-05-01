//
//  iStatNano.h
//  iStatNano
//
//  Created by Buffy on 26/03/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <WebKit/WebView.h>
#import "ISNDataMinerCPU.h"
#import "ISNDataMinerDisks.h"
#import "ISNDataMinerTemps.h"
#import "ISNDataMinerFans.h"
#import "ISNDataMinerNetwork.h"
#import "ISNDataMinerMemory.h"
#import "ISNDataMinerBattery.h"
#import "ISNSmartController.h"

@interface iStatNano : NSObject {
	ISNDataMinerCPU *cpuDataMiner;
	ISNDataMinerMemory *memoryDataMiner;
	ISNDataMinerDisks *disksDataMiner;
	ISNDataMinerNetwork *networkDataMiner;
	ISNDataMinerTemps *tempsDataMiner;
	ISNDataMinerFans *fansDataMiner;
	ISNDataMinerBattery *batteryDataMiner;
	ISNSmartController *smartController;

	NSString *icon_directory;
	BOOL moduleInstalled;
	BOOL diskChange;

	BOOL shouldUpdateSMART;
	BOOL smartMonitoringEnabled;
}

@end
