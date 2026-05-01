//
//  ISNDataMinerNetwork.m
//  iStat
//
//  Created by Buffy Summers on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ISNDataMinerNetwork.h"


@implementation ISNDataMinerNetwork

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self name: @"iStatNetworkPrimaryInterfaceChange" object:nil];

	if(sysConfigSessions)
		CFRelease(sysConfigSessions);
		
	if(primary_interface)
		[primary_interface release];

	[lastData removeAllObjects];
	[interfaceTypes removeAllObjects];
	[interfaceSubTypes removeAllObjects];
	[interfaceHardware removeAllObjects];
	[interfaceUserDefinedNames removeAllObjects];
	[interfaceIps removeAllObjects];
	[interfaceData removeAllObjects];
	[interfaceSpecs removeAllObjects];

	[lastData release];
	[interfaceTypes release];
	[interfaceSubTypes release];
	[interfaceHardware release];
	[interfaceUserDefinedNames release];
	[interfaceIps release];
	[interfaceData release];
	[interfaceSpecs release];

	if(latestData)
		[latestData release];

	[super dealloc];
}

- (NSString *)convertM:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	int i = 0;
	float value = [input floatValue];
	NSString *types[3]= {@"mb",@"gb",@"tb" };
	while(value > 1000){
		value = value / 1024;
		i++;
	}
	if(i == 0)
		return [NSString stringWithFormat:@"%.0f%@",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.2f%@",value,types[i]];
}

- (NSString *)convertK:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	int i = 0;
	float value = [input floatValue];
	NSString *types[3]= {@"kb/s",@"mb/s",@"gb/s" };
	while(value > 1000){
		value = value / 1024;
		i++;
	}
	if(i == 0 || i == 1)
		return [NSString stringWithFormat:@"%.0f%@",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.2f%@",value,types[i]];
}

- (void)primaryChange:(NSNotification *)note {
	[self getPrimaryInterface];
}

- (id) init {
	self = [super init];

	sysConfigSessions = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)[self description], NULL, NULL);

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(change:) name: @"iStatNetworkChange" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(primaryChange:) name: @"iStatNetworkPrimaryInterfaceChange" object:nil];
	firstRun = YES;
	
	lastData = [[NSMutableDictionary alloc] init];
	 
	interfaceTypes = [[NSMutableDictionary alloc] init];
	interfaceSubTypes = [[NSMutableDictionary alloc] init];
	interfaceHardware = [[NSMutableDictionary alloc] init];
	interfaceUserDefinedNames = [[NSMutableDictionary alloc] init];
	interfaceIps = [[NSMutableDictionary alloc] init];
	 
	interfaceData=[[NSMutableDictionary alloc] init];
	interfaceSpecs = [[NSMutableArray alloc] init];

	return self;
}

- (NSArray *)getDataSet {
	return latestData;
}

- (void)setNeedsUpdate:(BOOL)new {
	needsUpdate = new;
}

- (void) mineData {
	[[NSAutoreleasePool alloc] init];	
	double current_time = [[NSDate date] timeIntervalSince1970];
	double timer_difference = current_time - last_time;
	if(timer_difference < 0.5)
		timer_difference = 0.5;

	last_time = current_time;

	if(needsUpdate == YES){
		NSLog(@"needs update");
		[interfaceTypes removeAllObjects];
		[interfaceSubTypes removeAllObjects];
		[interfaceHardware removeAllObjects];
		[interfaceUserDefinedNames removeAllObjects];
		[interfaceIps removeAllObjects];
		[lastData removeAllObjects];
		[self getInterfaceTypes];
		[self setup];

		NSEnumerator *interfaceEnumerator = [interfaceTypes keyEnumerator];
		NSString *key;
		while(key = [interfaceEnumerator nextObject]){
			NSMutableDictionary *filler = [[NSMutableDictionary alloc] init];
			[filler setValue:[NSNumber numberWithInt:0] forKey:@"in"];
			[filler setValue:[NSNumber numberWithInt:0] forKey:@"out"];
			[lastData setValue:filler forKey:key];
		}
	}
		
	NSMutableArray *theData = [[NSMutableArray alloc] init];
		
	u_int64_t ibytes = 0;
	u_int64_t obytes = 0;

	struct if_msghdr *ifm;
	struct ifmedia_description *media;
	struct ifreq *ifr;

	int i;
	i=0;			
    int mib[6];
    char *buf = NULL, *lim, *next;
	size_t len;
	
	mib[0]	= CTL_NET;			
	mib[1]	= PF_ROUTE;	
	mib[2]	= 0;
	mib[3]	= 0;
	mib[4]	= NET_RT_IFLIST2;
	mib[5]	= 0;
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
		return;
	if ((buf = malloc(len)) == NULL) {
	}
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		if (buf)
			free(buf);
		return;
	}

    lim = buf + len;
    for (next = buf; next < lim; ) {
		char name[32];
		
		ifr = (struct ifreq *)next;
        ifm = (struct if_msghdr *)next;
		next += ifm->ifm_msglen;

        if (ifm->ifm_type == RTM_IFINFO2) {
			struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
			media = (struct ifmedia_description *)if2m;
            struct sockaddr_dl	*sdl = (struct sockaddr_dl *)(if2m + 1);
			strncpy(name, sdl->sdl_data, sdl->sdl_nlen);
			name[sdl->sdl_nlen] = 0;
			
			if ((if2m->ifm_flags & IFF_UP) == 0){
				continue;
			}
			sdl = (struct sockaddr_dl *)(if2m + 1);

			if(if2m->ifm_flags & IFF_LOOPBACK){
				continue;
			}
					
			ibytes = if2m->ifm_data.ifi_ibytes;
			obytes = if2m->ifm_data.ifi_obytes;
			
			ibytes = ibytes / 1024;
			obytes = obytes / 1024;

			NSString *key=[NSString stringWithFormat:@"%s",name];

			if([interfaceTypes objectForKey:key]){				
				if(needsUpdate){
					[[lastData objectForKey:key] setValue:[NSNumber numberWithInt:ibytes] forKey:@"in"];
					[[lastData objectForKey:key] setValue:[NSNumber numberWithInt:obytes] forKey:@"out"];
				}

				int current_in = [[NSNumber numberWithInt:ibytes-[[[lastData objectForKey:key] valueForKey:@"in"] intValue]] intValue];
				int current_out = [[NSNumber numberWithInt:obytes-[[[lastData objectForKey:key] valueForKey:@"out"] intValue]] intValue];
				current_in = current_in / timer_difference;
				current_out = current_out / timer_difference;
				
				[theData addObject:[NSArray arrayWithObjects:key,[interfaceSubTypes valueForKey:key],[interfaceIps valueForKey:key],[self convertK:[NSNumber numberWithInt:current_in]],[self convertK:[NSNumber numberWithInt:current_out]],[self convertM:[NSNumber numberWithInt:ibytes/1024]],[self convertM:[NSNumber numberWithInt:obytes/1024]],[peakValues objectForKey:key],key,nil]];

				[[lastData objectForKey:key] setValue:[NSNumber numberWithInt:ibytes] forKey:@"in"];
				[[lastData objectForKey:key] setValue:[NSNumber numberWithInt:obytes] forKey:@"out"];
				i++;
			}
		}
	}

	if(needsUpdate)
		needsUpdate = NO;	

	if (latestData)
		[latestData release];
	
	latestData = [[NSArray arrayWithArray:theData] retain];
	[theData release];
	free(buf);
	return;
}

- (NSArray *)getBandwidth {
	return [NSArray arrayWithObjects:[NSNumber numberWithInt:currentIn / 1],[NSNumber numberWithInt:currentOut / 1],nil];
}

- (int)getInterfaces {
	return [interfaceSpecs count];
}

- (NSArray *)getInterfaceSpecs {
	return interfaceSpecs;
}

- (void) setup {
	[interfaceSpecs removeAllObjects];
	NSEnumerator *interfaceEnumerator = [interfaceTypes keyEnumerator];
	NSDictionary *filter = [NSDictionary dictionary];// [[[iStatMenusNetwork core] prefs] objectForKey:@"NetworkFiltering"];
	NSString *key;
	while(key = [interfaceEnumerator nextObject]){
		if([filter objectForKey:key] != NULL && [[filter objectForKey:key] intValue] == 0)
			continue;
		[interfaceSpecs addObject:[NSArray arrayWithObjects:key,[interfaceIps objectForKey:key],[interfaceSubTypes objectForKey:key],nil]];
	}
}

- (void)getPrimaryInterface {
	[[NSAutoreleasePool alloc] init];
	
	if(primary_interface) {
		[primary_interface release];
		primary_interface = nil;
	}
	
	NSDictionary *primary_data = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)@"State:/Network/Global/IPv4");
	if(primary_data != NULL) {
		if([primary_data valueForKey:@"PrimaryInterface"]) {
			primary_interface = [primary_data valueForKey:@"PrimaryInterface"];
			[primary_interface retain];
		}
	}
}

- (void)getInterfaceTypes {
	[[NSAutoreleasePool alloc] init];

	[self getPrimaryInterface];
	
	NSDictionary *services=(NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)@"Setup:/Network/Global/IPv4"); // Get a list of all interfaces
	NSEnumerator *servicedEnumerator=[[services valueForKey:@"ServiceOrder"] objectEnumerator];
    NSString *service;
	while(service = [servicedEnumerator nextObject]) {
		NSString *servicePath = [NSString stringWithFormat:@"Setup:/Network/Service/%@/Interface",service];
		NSDictionary *serviceInterface = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)servicePath); // Get the details for the current interface
		NSString *name;
		NSString *stateName;
		
		if([serviceInterface objectForKey:@"DeviceName"])
			name = [serviceInterface objectForKey:@"DeviceName"];
		else
			continue; // If there is no device name we continue.This is the case with VPN's especially
		stateName = name;

		// Check for PPPoE connections. We need to check the connection is actually active 
		// ethernet based PPPoE connections show as active for the "en" interface always so we need to check that the corresponding ppp interface is active
		if([serviceInterface objectForKey:@"SubType"]){
			if([[serviceInterface objectForKey:@"SubType"] isEqualToString:@"PPPoE"]){
				NSString *linkPath = [NSString stringWithFormat:@"State:/Network/Service/%@/PPP",service]; // Get the ppp dictionary for the interface
				NSDictionary *interfaceLink = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)linkPath);
				if(interfaceLink == NULL){
					continue; // No dictionary was found so we continue
				} else {
					name = [interfaceLink objectForKey:@"InterfaceName"]; // This gives us the ppp name for this ethernet interface
					NSString *ipPath = [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",name];
					NSDictionary *interfaceIP = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)ipPath); // Get IP Address
					if([interfaceIP objectForKey:@"Addresses"])
						[interfaceIps setObject:[[interfaceIP objectForKey:@"Addresses"] objectAtIndex:0] forKey:name];
					else
						[interfaceIps setObject:@"" forKey:name];
					/// We set static objects for PPPoE connections because the values are always the same except for IP
					[interfaceTypes setObject:@"Ethernet" forKey:name];
					[interfaceHardware setObject:@"Ethernet" forKey:name];
					[interfaceSubTypes setObject:@"PPPoE" forKey:name];
					continue;
				}
				
			}
		}

		// Check for dialup modems
		// Like PPPoE connections we need to check the interface is active before we continue
		if([serviceInterface objectForKey:@"Type"] && [serviceInterface objectForKey:@"Hardware"]){
			if([[serviceInterface objectForKey:@"Type"] isEqualToString:@"PPP"] && [[serviceInterface objectForKey:@"Hardware"] isEqualToString:@"Modem"] ){
				NSString *pppPath = [NSString stringWithFormat:@"State:/Network/Service/%@/IPv4",service];
				NSDictionary *pppIPv4 = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)pppPath);
				if(![pppIPv4 objectForKey:@"InterfaceName"])
					continue; // No name was found for the interface which means its not active
				stateName = name = [pppIPv4 objectForKey:@"InterfaceName"];
				NSString *linkPath = [NSString stringWithFormat:@"State:/Network/Service/%@/PPP",service];
				NSDictionary *interfaceLink = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)linkPath);
				if(interfaceLink == NULL || ![interfaceLink objectForKey:@"InterfaceName"]) // No details were found so we skip it
					continue;
			}
		}
		
		// Check Link status.We only care about active interfaces
		NSString *linkPath = [NSString stringWithFormat:@"State:/Network/Interface/%@/Link",stateName];
		NSDictionary *interfaceLink = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)linkPath); 
		if(interfaceLink != NULL){
			 if([[interfaceLink objectForKey:@"Active"] intValue] == 0)
				continue;
		}

		// Workout the path for the IP for the current Interface
		NSString *ipPath = [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",name];
		if([serviceInterface objectForKey:@"Type"] && [serviceInterface objectForKey:@"Hardware"])
			if([[serviceInterface objectForKey:@"Type"] isEqualToString:@"PPP"] && [[serviceInterface objectForKey:@"Hardware"] isEqualToString:@"Modem"] )
				ipPath = [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",stateName];
			
		NSDictionary *interfaceIP = (NSDictionary *)SCDynamicStoreCopyValue(sysConfigSessions,(CFStringRef)ipPath);
		if(interfaceIP == NULL)
			continue;
			
		// IP Address
		if([interfaceIP objectForKey:@"Addresses"])
			[interfaceIps setObject:[[interfaceIP objectForKey:@"Addresses"] objectAtIndex:0] forKey:name];
		else
			[interfaceIps setObject:@"" forKey:name];
			
		// Interface Type (Ethernet, Modem etc)
		if([serviceInterface objectForKey:@"Type"])
			[interfaceTypes setObject:[serviceInterface objectForKey:@"Type"] forKey:name];
		else
			[interfaceTypes setObject:@"Ethernet" forKey:name];
	
		// Interface Hardware (Ethernet, Modem etc)
		if([serviceInterface objectForKey:@"Hardware"])
			[interfaceHardware setObject:[serviceInterface objectForKey:@"Hardware"] forKey:name];
		else
			[interfaceHardware setObject:@"Ethernet" forKey:name];

		// SubType - This helps us differenciate Ethernet from Airport
		if([serviceInterface objectForKey:@"SubType"])
			[interfaceSubTypes setObject:[serviceInterface objectForKey:@"SubType"] forKey:name];
		else
			[interfaceSubTypes setObject:[interfaceHardware objectForKey:name] forKey:name];

		// UserDefinedName - This is the name that is displayed in system preferences
		if([serviceInterface objectForKey:@"UserDefinedName"])
			[interfaceUserDefinedNames setObject:[serviceInterface objectForKey:@"UserDefinedName"] forKey:name];
		else
			[interfaceUserDefinedNames setObject:[interfaceTypes objectForKey:name] forKey:name];
	}
}

- (NSArray *)getNamesAndTypes {
	[[NSAutoreleasePool alloc] init];
	NSMutableArray *theArray = [[NSMutableArray alloc] init];
	[self getInterfaceTypes];
	[self setup];
	
	struct if_msghdr *ifm;
	struct ifmedia_description *media;
	struct ifreq *ifr;

    int mib[6];
    char *buf = NULL, *lim, *next;
	size_t len;
	
	mib[0]	= CTL_NET;			// networking subsystem
	mib[1]	= PF_ROUTE;			// type of information
	mib[2]	= 0;				// protocol (IPPROTO_xxx)
	mib[3]	= 0;				// address family
	mib[4]	= NET_RT_IFLIST2;	// operation
	mib[5]	= 0;
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
		return [[NSArray alloc] init];
	if ((buf = malloc(len)) == NULL) {
	}
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		if (buf)
			free(buf);
		return [[NSArray alloc] init];
	}

    lim = buf + len;
    for (next = buf; next < lim; ) {
		char name[32];
		
		ifr = (struct ifreq *)next;
        ifm = (struct if_msghdr *)next;
		next += ifm->ifm_msglen;

        if (ifm->ifm_type == RTM_IFINFO2) {
			struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
			media = (struct ifmedia_description *)if2m;
            struct sockaddr_dl	*sdl = (struct sockaddr_dl *)(if2m + 1);
			strncpy(name, sdl->sdl_data, sdl->sdl_nlen);
			name[sdl->sdl_nlen] = 0;
			
			if ((if2m->ifm_flags & IFF_UP) == 0){
				continue;
			}
			sdl = (struct sockaddr_dl *)(if2m + 1);

			if(if2m->ifm_flags & IFF_LOOPBACK){
				continue;
			}

			NSString *key=[NSString stringWithFormat:@"%s",name];
			
			if([interfaceTypes objectForKey:key]){
				NSArray *item = [[NSArray alloc] initWithObjects:key,[interfaceSubTypes objectForKey:key],nil];
				[theArray addObject:item];				
				
			}
		}
	}

	free(buf);
	
	return [theArray autorelease];
}

@end
