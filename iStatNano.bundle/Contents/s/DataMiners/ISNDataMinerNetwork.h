//
//  ISNDataMinerNetwork.h
//  iStat
//
//  Created by Buffy Summers on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <SystemConfiguration/SCNetworkReachability.h>
#include <SystemConfiguration/SCNetwork.h>
#include <SystemConfiguration/SCNetworkConfiguration.h>
#include <SystemConfiguration/SCNetworkConnection.h>
#include <SystemConfiguration/SystemConfiguration.h>


#include <net/if.h>
#include <net/if_var.h>
#include <net/if_dl.h>
#include <net/if_types.h>
#include <net/if_mib.h>
#include <net/ethernet.h>
#include <net/route.h>

#include <netinet/in.h>
#include <netinet/in_var.h>
#include <sys/sysctl.h>

@interface ISNDataMinerNetwork : NSObject {
	NSArray *latestData;
	u_int64_t previousMenuBarIn;
	u_int64_t previousMenuBarOut;

	u_int64_t currentIn;
	u_int64_t currentOut;
	
	BOOL firstRun;
	BOOL needsReset;

	NSMutableDictionary		*interfaceData;
	NSMutableDictionary		*userDefinedNames;
	NSMutableArray*			networkArray;
	NSMutableArray*			networkInterfaces;
	BOOL					needsUpdate;
	
	NSMutableDictionary* lastData;
	NSMutableDictionary* peakValues;
	NSMutableArray* interfaceSpecs;
	
	NSMutableDictionary *interfaceTypes;
	NSMutableDictionary *interfaceSubTypes;
	NSMutableDictionary *interfaceHardware;
	NSMutableDictionary *interfaceUserDefinedNames;
	NSMutableDictionary *interfaceIps;
	NSString *primary_interface;
	
	SCDynamicStoreRef sysConfigSessions;
	
	double last_time;
}

- (NSArray *)getInterfaceSpecs;
- (int)getInterfaces;
- (void) installNotifiers;
- (NSArray *)getDataSet;
- (void) mineData;
- (NSArray *)getBandwidth;
- (void) setup;
- (void)getInterfaceTypes;
- (NSArray *)getNamesAndTypes;
- (void)getPrimaryInterface;

@end
