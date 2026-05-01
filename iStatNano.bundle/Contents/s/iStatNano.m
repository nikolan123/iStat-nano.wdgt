//
//  iStatNano.m
//  iStatNano
//
//  Created by Buffy on 26/03/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "iStatNano.h"


@implementation iStatNano

int updateList = 1;

void networkChangeCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	updateList = 1;
}

- (void) installNotifiers {
	[[NSAutoreleasePool alloc] init];
    CFRunLoopSourceRef notificationLoop = NULL;
	SCDynamicStoreContext DynamicStoreContext = { 0, NULL, NULL, NULL, NULL };
	SCDynamicStoreRef store = SCDynamicStoreCreate(kCFAllocatorDefault, (CFStringRef)[self description], networkChangeCallback,&DynamicStoreContext);

	SCDynamicStoreSetNotificationKeys(store, (CFArrayRef)[NSArray arrayWithObjects:@"State:/Network/Global/IPv4", @"Setup:/Network/Global/IPv4", @"State:/Network/Interface",@"", nil],nil);
	notificationLoop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, store, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationLoop, kCFRunLoopDefaultMode);
}

- (id)initWithWebView:(WebView*)w {
	self = [super init];
	
	@try { 
		[self installNotifiers];
	}
	@catch ( NSException *e ) {  }
	
	moduleInstalled = NO;
	diskChange = NO;
	updateList = 1;
	
//	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(moduleInstalled:) name:@"iStatProIntelModuleAvailable" object:nil];	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(workspaceChange:) name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(workspaceChange:) name:NSWorkspaceDidUnmountNotification object:nil];	

	icon_directory = [[NSString alloc] initWithString:[@"~/Library/Application Support/iSlayer/ProcessesIconCache/" stringByExpandingTildeInPath]];
	NSString *support_directory = [@"~/Library/Application Support/iSlayer/" stringByExpandingTildeInPath];

	BOOL isDir;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:support_directory isDirectory:&isDir];
    if (!exists) {
		[[NSFileManager defaultManager] createDirectoryAtPath:support_directory attributes:nil];
	}

	exists = [[NSFileManager defaultManager] fileExistsAtPath:icon_directory isDirectory:&isDir];
    if (!exists){
		[[NSFileManager defaultManager] createDirectoryAtPath:icon_directory attributes:nil];
	}


	cpuDataMiner = [[ISNDataMinerCPU alloc] init];
	memoryDataMiner = [[ISNDataMinerMemory alloc] init];
	disksDataMiner = [[ISNDataMinerDisks alloc] init];
	networkDataMiner = [[ISNDataMinerNetwork alloc] init];
	tempsDataMiner = [[ISNDataMinerTemps alloc] init];
	fansDataMiner = [[ISNDataMinerFans alloc] init];
	batteryDataMiner = [[ISNDataMinerBattery alloc] init];
	smartController = [[ISNSmartController alloc] init];

	shouldUpdateSMART = YES;

	return self;
}

- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name:NSWorkspaceDidUnmountNotification object:nil];	

	[cpuDataMiner release];
	[memoryDataMiner release];
	[disksDataMiner release];
	[networkDataMiner release];
	[tempsDataMiner release];
	[fansDataMiner release];
	[batteryDataMiner release];
	[smartController release];
	[super dealloc];
}

- (void)windowScriptObjectAvailable:(WebScriptObject*)wso {
	[wso setValue:self forKey:@"iStatNano"];
}

+ (NSString *)webScriptNameForSelector:(SEL)aSel {
	NSString *retval = nil;
	if (aSel == @selector(cpuUsage)) {
		retval = @"cpuUsage";
	} else if (aSel == @selector(memoryUsage)) {
		retval = @"memoryUsage";
	} else if (aSel == @selector(diskUsage)) {
		retval = @"diskUsage";
	} else if (aSel == @selector(network)) {
		retval = @"network";
	} else if (aSel == @selector(getAppPath::)) {
		retval = @"getAppPath";
	} else if (aSel == @selector(getselfpid)) {
		retval = @"getselfpid";
	} else if (aSel == @selector(getPsName:)) {
		retval= @"getPsName";
	} else if (aSel == @selector(temps:)) {
		retval= @"temps";
	} else if (aSel == @selector(fans)) {
		retval= @"fans";
	} else if (aSel == @selector(uptime)) {
		retval= @"uptime";
	} else if (aSel == @selector(load)) {
		retval= @"load";
	} else if (aSel == @selector(processinfo)) {
		retval= @"processinfo";
	} else if (aSel == @selector(battery)) {
		retval= @"battery";
	} else if (aSel == @selector(isLaptop)) {
		retval= @"isLaptop";
	} else if (aSel == @selector(isIntel)) {
		retval= @"isIntel";
	} else if (aSel == @selector(needsIntelBundle)) {
		retval= @"needsIntelBundle";
	} else if (aSel == @selector(copyTextToClipboard:)) {
		retval= @"copyTextToClipboard";
	} else if (aSel == @selector(setNeedsSMARTUpdate)) {
		retval= @"setNeedsSMARTUpdate";
	} else if (aSel == @selector(setShouldMonitorSMARTTemps:)) {
		retval= @"setShouldMonitorSMARTTemps";
	}
	
	return retval;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSel {	
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char*)k {
	return YES;
}

- (void)setNeedsSMARTUpdate {
	shouldUpdateSMART = YES;
}

- (void)setShouldMonitorSMARTTemps:(int)should {
	if(should == 1)
		smartMonitoringEnabled = YES;
	else
		smartMonitoringEnabled = NO;
}

- (void)copyTextToClipboard:(NSString *)text {
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pb setString:text forType:NSStringPboardType];
}

- (void)workspaceChange:(NSNotification *)note {
	[disksDataMiner findDrives];
	diskChange = YES;
}

- (BOOL)hasDiskSetupChanged {
	if(diskChange) {
		diskChange = NO;
		return YES;
	}
	return NO;
}

- (BOOL)hasNetworkSetupChanged {
	if(updateList == 1){
		updateList = 0;
		[networkDataMiner setNeedsUpdate:YES];
		return YES;
	}
	return NO;
}

- (void)installIntelModule {
	//[[NSWorkspace sharedWorkspace] launchApplication:[[NSBundle bundleWithIdentifier:@"com.iSlayer.iStatNano.widgetplugin"] pathForResource:@"iStat Intel Module Installer" ofType:@"app"]];
}

- (NSArray *)cpuUsage {
	[cpuDataMiner mineData];
	return [cpuDataMiner getDataSet];
}

- (NSArray *)memoryUsage {
	[memoryDataMiner mineData];
	return [memoryDataMiner getDataSet];
}

- (NSArray *)diskUsage {
	[disksDataMiner update];
	return [disksDataMiner getDataSet];
}

- (NSArray *)network {
	[networkDataMiner mineData];
	return [networkDataMiner getDataSet];
}

- (NSArray *)temps:(int)degrees {
	if(!smartMonitoringEnabled){
		return [tempsDataMiner getDataSet:degrees];
	}
	
	if(shouldUpdateSMART){
		shouldUpdateSMART = NO;
		[smartController update];
	}
	
	NSMutableArray *finalTemps = [[NSMutableArray alloc] init];

	NSArray *sensorTemps = [tempsDataMiner getDataSet:degrees];
	NSArray *smartTemps = [smartController getDataSet];


	NSString *degreesSuffix = [NSString stringWithUTF8String:"\xC2\xB0"];					
	if(degrees == 2)
		degreesSuffix = @"K";
	
	int x;
	for(x=0;x<[smartTemps count];x++){
		if([[smartTemps objectAtIndex:x] objectForKey:@"deviceTemp"] == NULL || [[smartTemps objectAtIndex:x] objectForKey:@"model"] == NULL)
			continue;
			
		int value = [[[smartTemps objectAtIndex:x] objectForKey:@"deviceTemp"] intValue];
		if(degrees == 1) // Fahrenheight
			value = (value * 2) - ((value * 2) * 1 / 10) + 32;
		
		if(degrees == 2) // Kelvin
			value += 273.15;
			
		NSString *name = [[smartTemps objectAtIndex:x] objectForKey:@"model"];

		[finalTemps addObject:[NSArray arrayWithObjects:name, [NSString stringWithFormat:@"%i%@",value,degreesSuffix], nil]];
	}
	
	[finalTemps addObjectsFromArray:sensorTemps];

	return [finalTemps autorelease];
}

- (NSArray *)fans {
	return [fansDataMiner getDataSet];
}

- (NSArray *)battery {
	[batteryDataMiner mineData];
	return [batteryDataMiner getDataSet];
}

- (BOOL)isLaptop {
	return [batteryDataMiner isLaptop];
}

- (NSString *)uptime {
	return [cpuDataMiner getUptime];
}

- (NSString *)load {
	return [cpuDataMiner getLoad];
}

- (NSString *)processinfo {
	return [cpuDataMiner processInfo];
}

- (NSString *)getAppPath:(int)thePID:(NSString *)name {
	FSRef theRef;
	ProcessSerialNumber psn;
	GetProcessForPID(thePID,&psn); 
	GetProcessBundleLocation(&psn,&theRef);

	CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &theRef);
	NSString *pathName;
	NSString *bundlePath;
	if (url) {
		pathName = (NSString *)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		bundlePath = [[NSBundle bundleWithPath:pathName] bundleIdentifier];
		NSString *icon_path = [NSString stringWithFormat:@"%@/%@.tiff",icon_directory,bundlePath];
		if([[NSFileManager defaultManager] fileExistsAtPath:icon_path] == NO) {
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:pathName];       
			NSData *tiffRep = [icon TIFFRepresentation];
			[tiffRep writeToFile:icon_path atomically:YES];
		}
		CFRelease(url);
		CFRelease(pathName);
		return icon_path;
	}
	return @"";
}

- (NSString *)getPsName:(int)thePid {	
	CFStringRef name = NULL;
	ProcessSerialNumber psn2;
	OSStatus err = GetProcessForPID(thePid, &psn2); 
	if(err != noErr) {
		return @"Unknown widget";
	}
	
	err = CopyProcessName(&psn2, &name);
	if(err != noErr) {
		return @"Unknown widget";
	}
	
	if(name == NULL)
		return @"Unknown widget";
	else
		return name;
}

- (int)getselfpid {
	return getpid();
}

- (BOOL)isIntel {
	OSType		returnType;
	long		gestaltReturnValue;
	
	returnType=Gestalt(gestaltSysArchitecture, &gestaltReturnValue);
	
	if (!returnType && gestaltReturnValue == gestaltIntel)
		return YES;

	return NO;
}

- (BOOL)needsIntelBundle {
	if(![self isIntel])
		return NO;

	NSString *dest = [NSString stringWithFormat:@"%@/Library/Application Support/iSlayer/iStat/iStatIntelSensorsV3.bundle",[[NSString stringWithFormat:@"~/"] stringByExpandingTildeInPath]];
	if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
		NSBundle *intelBundle = [NSBundle bundleWithPath:dest];
		if(intelBundle != nil){
			return NO;
		}
	}
	return YES;
}

- (void)moduleInstalled:(NSNotification *)note {
	[tempsDataMiner moduleInstalled];
	[fansDataMiner moduleInstalled];
	moduleInstalled = YES;
}

- (BOOL)wasIntelModuleInstalled {
	return NO;
	return moduleInstalled;
}

@end
