//
//  ISPSmartController.m
//  iStatPro
//
//  Created by Buffy on 11/06/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ISNSmartController.h"
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOReturn.h>
#include <IOKit/storage/ata/ATASMARTLib.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <CoreFoundation/CoreFoundation.h>
#include <sys/param.h>
#include <sys/time.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_init.h>

@implementation ISNSmartController

#if defined(__BIG_ENDIAN__)
#define		SwapASCIIHostToBig(x,y)
#elif defined(__LITTLE_ENDIAN__)
#define		SwapASCIIHostToBig(x,y)				SwapASCIIString( ( UInt16 * ) x,y)
#else
#error Unknown endianness.
#endif

// This constant comes from the SMART specification.  Only 30 values are allowed in any of the structures.
#define kSMARTAttributeCount	30


typedef struct IOATASmartAttribute
{
    UInt8 			attributeId;
    UInt16			flag;  
    UInt8 			current;
    UInt8 			worst;
    UInt8 			rawvalue[6];
    UInt8 			reserv;
}  __attribute__ ((packed)) IOATASmartAttribute;

typedef struct IOATASmartVendorSpecificData
{
    UInt16 					revisonNumber;
    IOATASmartAttribute		vendorAttributes [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificData;

/* Vendor attribute of SMART Threshold */
typedef struct IOATASmartThresholdAttribute
{
    UInt8 			attributeId;
    UInt8 			ThresholdValue;
    UInt8 			Reserved[10];
} __attribute__ ((packed)) IOATASmartThresholdAttribute;

typedef struct IOATASmartVendorSpecificDataThresholds
{
    UInt16							revisonNumber;
    IOATASmartThresholdAttribute 	ThresholdEntries [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificDataThresholds;

void SwapASCIIString(UInt16 *buffer, UInt16 length)
{
	int	index;
	
	for ( index = 0; index < length / 2; index ++ ) {
		buffer[index] = OSSwapInt16 ( buffer[index] );
	}	
}


-(int) VerifyIdentifyData: (UInt16 *) buffer
{
	UInt8		checkSum		= -1;
	UInt32		index			= 0;
	UInt8 *		ptr				= ( UInt8 * ) buffer;
	
	require_string(((buffer[255] & 0x00FF) == kChecksumValidCookie), ErrorExit, "WARNING: Identify data checksum cookie not found");

	checkSum = 0;
		
	for (index = 0; index < 512; index++)
		checkSum += ptr[index];
	
ErrorExit:
	return checkSum;
}

- (BOOL) PrintIdentifyData: ( IOATASMARTInterface **) smartInterface withResultsDict:(NSMutableDictionary *) smartResultsDict
{
	IOReturn	error				= kIOReturnSuccess;
	UInt8 *		buffer				= NULL;
	UInt32		length				= kATADefaultSectorSize;
	
	UInt16 *	words				= NULL;
	int			checksum			= 0;
	
	BOOL		isSMARTSupported	= NO;
	
	buffer = (UInt8 *) malloc(kATADefaultSectorSize);
	require_string((buffer != NULL), ErrorExit, "malloc(kATADefaultSectorSize) failed");
	
	bzero(buffer, kATADefaultSectorSize);
	
	error = (*smartInterface)->GetATAIdentifyData(	smartInterface,
													buffer,
													kATADefaultSectorSize,
													&length );
	
	require_string((error == kIOReturnSuccess), ErrorExit, "GetATAIdentifyData failed");

	checksum = [self VerifyIdentifyData:( UInt16 * ) buffer];
	require_string((checksum == 0), ErrorExit, "Identify data verified. Checksum is NOT correct");
	
	// Terminate the strings with 0's
	// This changes the identify data, so we MUST do this part last.
	buffer[94] = 0;
	buffer[40] = 0;
	
	// Model number runs from byte 54 to 93 inclusive - byte 94 is set to 
	// zero to terminate that string.
	SwapASCIIHostToBig (&buffer[54], 40);
	
	NSString *diskName = [NSString stringWithCString:(char *)&buffer[54] encoding:NSUTF8StringEncoding];
	diskName = [diskName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
//	[smartResultsDict setObject:diskName forKey:kWindowSMARTsModelKeyString];

	// in iStat nano we only ever show the boot drive which makes naming the drive easy. 
	[smartResultsDict setObject:[NSString stringWithFormat:@"HD: %@",[[NSFileManager defaultManager] displayNameAtPath:@"/"]] forKey:kWindowSMARTsModelKeyString];
	
	// Now that we have made a deep copy of the model string, poke a 0 into byte 54 
	// in order to terminate the fw-vers string which runs from bytes 46 to 53 inclusive.
//	buffer[54] = 0;
	
//	SwapASCIIHostToBig (&buffer[46], 8);
//	[smartResultsDict setObject:[NSString stringWithCString:(char *)&buffer[46] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsFirmwareKeyString];

//	SwapASCIIHostToBig (&buffer[20], 20);
//	[smartResultsDict setObject:[NSString stringWithCString:(char *)&buffer[20] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsSerialNumberKeyString];
	
	words = (UInt16 *) buffer;
	
	isSMARTSupported = words[kATAIdentifyCommandSetSupported] & kATASupportsSMARTMask;
	
ErrorExit:
	if (buffer)
		free(buffer);

	return isSMARTSupported;
}

-(void) PrintSMARTData:(IOATASMARTInterface **) smartInterface withResultsDict:(NSMutableDictionary *) smartResultsDict
{
	
	IOReturn									error				= kIOReturnSuccess;
	Boolean										conditionExceeded	= false;
	ATASMARTData								smartData;
	IOATASmartVendorSpecificData				smartDataVendorSpecifics;
	ATASMARTDataThresholds						smartThresholds;
	IOATASmartVendorSpecificDataThresholds		smartThresholdVendorSpecifics;
	ATASMARTLogDirectory						smartLogDirectory;

	bzero(&smartData, sizeof(smartData));
	bzero(&smartDataVendorSpecifics, sizeof(smartDataVendorSpecifics));
	bzero(&smartThresholds, sizeof(smartThresholds));
	bzero(&smartThresholdVendorSpecifics, sizeof(smartThresholdVendorSpecifics));
	bzero(&smartLogDirectory, sizeof(smartLogDirectory));

	// Default the results for safety.
//	[smartResultsDict setObject:[NSNumber numberWithBool:NO] forKey:kWindowSMARTsDeviceOkKeyString];


	// Start by enabling S.M.A.R.T. reporting for this disk.
	error = (*smartInterface)->SMARTEnableDisableOperations(smartInterface, true);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTEnableDisableOperations failed");
	
	error = (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, true);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTEnableDisableAutosave failed");


	// In most cases, this value will be all that you require.  As most of the
	// S.M.A.R.T reporting attributes are vendor-specific, the only part you can
	// always count on being implemented and accurate is the overall T.E.C
	// (Threshold Exceeded Condition) status report.
	error = (*smartInterface)->SMARTReturnStatus(smartInterface, &conditionExceeded);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTReturnStatus failed" );
	
//	if (!conditionExceeded)
//		[smartResultsDict setObject:[NSNumber numberWithBool:YES] forKey:kWindowSMARTsDeviceOkKeyString];


	// NOTE:
	// The rest of the diagnostics gathering involves using portions of the API that is considered
	// optional for a drive vendor to implement.  Most vendors now do, but be warned not to rely
	// on it.  In particular, the attribute codes are usually considered vendor specific and
	// proprietary, although some codes (ie. drive temperature) are almost always present.


	// Ask the device to start collecting S.M.A.R.T. data immediately.  We are not asking
	// for an extended test to be performed at this point
	error = (*smartInterface)->SMARTExecuteOffLineImmediate (smartInterface, false);
//	if (error != kIOReturnSuccess)
//		printf("SMARTExecuteOffLineImmediate failed: %s(%x)\n", mach_error_string(error), error);


	// Next, a demonstration of how to extract the raw S.M.A.R.T. data attributes.
	// A drive can report up to 30 of these, but all are optional.  Normal values
	// vary by vendor, although the property used for this demonstration always
	// reports in degrees celcius
	error = (*smartInterface)->SMARTReadData(smartInterface, &smartData);
	if (error != kIOReturnSuccess) {
	} else {
		error = (*smartInterface)->SMARTValidateReadData(smartInterface, &smartData);
		if (error != kIOReturnSuccess) {
		} else {
			smartDataVendorSpecifics = *((IOATASmartVendorSpecificData *)&(smartData.vendorSpecific1));

			int currentAttributeIndex = 0;
			for (currentAttributeIndex = 0; currentAttributeIndex < kSMARTAttributeCount; currentAttributeIndex++) {
				IOATASmartAttribute currentAttribute = smartDataVendorSpecifics.vendorAttributes[currentAttributeIndex];
			
				// Grab and use the drive temperature if it's present.  Don't freak out if it isn't, as
				// this is an optional behaviour although most drives do support this.
				if (currentAttribute.attributeId == kWindowSMARTsDriveTempAttribute) {
					UInt8 temp = currentAttribute.rawvalue[0];
					[smartResultsDict setObject:[NSNumber numberWithUnsignedInt:temp] forKey:kWindowSMARTsDeviceTempKeyString];
					break;
				}
			}
		}
	}

ErrorExit:
	// Now that we're done, shut down the S.M.A.R.T.  If we don't, storage takes a big performance hit.
	// We should be able to ignore any error conditions here safely
	error = (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, false);
	error = (*smartInterface)->SMARTEnableDisableOperations(smartInterface, false);
}

- (IOReturn) PerformSMARTUnitTest:(io_service_t) object
{
	io_service_t				service				= IO_OBJECT_NULL;			
	IOCFPlugInInterface **		cfPlugInInterface	= NULL;
	IOATASMARTInterface **		smartInterface		= NULL;
	SInt32						score				= 0;
	HRESULT						herr				= S_OK;
	IOReturn					err					= kIOReturnSuccess;
	NSMutableDictionary *		smartResultsDict	= [[NSMutableDictionary alloc] initWithCapacity:16];
	
	// Under 10.4.8 and higher, we can use the presence of the "SMART Capable" key to find the top-most entry
	// in the registry for each device and query that.
	//service = [self GetDeviceObject: object];
	
//#if 0
//	// If you know you're going to be running only on 10.4.8 or higher, you could do this
//	require_string((service != IO_OBJECT_NULL), ErrorExit, "unable to obtain service using [self GetDeviceObject]");
//#else
	// As a fall-back, this will help you work on pre-10.4.8 systems as well.
	//if (!service)
		service = object;
//#endif
	
	err = IOCreatePlugInInterfaceForService (	service,
												kIOATASMARTUserClientTypeID,
												kIOCFPlugInInterfaceID,
												&cfPlugInInterface,
												&score );
	
	require_string ( ( err == kIOReturnSuccess ), ErrorExit,
					 "IOCreatePlugInInterfaceForService failed" );
	
	herr = ( *cfPlugInInterface )->QueryInterface (
										cfPlugInInterface,
										CFUUIDGetUUIDBytes ( kIOATASMARTInterfaceID ),
										( LPVOID ) &smartInterface );
	
	require_string ( ( herr == S_OK ), DestroyPlugIn,
					 "QueryInterface failed" );
	
	// Grab any identifying data we can on this device and then, if it supports S.M.A.R.T.,
	// qurey the S.M.A.R.T. monitoring subsystem for status information
	if ([self PrintIdentifyData:smartInterface withResultsDict:smartResultsDict])
		[self PrintSMARTData:smartInterface withResultsDict:smartResultsDict];

	[diskData addObject:smartResultsDict];
	[smartResultsDict release];
	
	( *smartInterface )->Release ( smartInterface );
	smartInterface = NULL;

DestroyPlugIn:
	IODestroyPlugInInterface ( cfPlugInInterface );
	cfPlugInInterface = NULL;

ErrorExit:
	return err;
	
}

- (void)update {
	diskData = [[NSMutableArray alloc] init];
	IOReturn				error 			= kIOReturnSuccess;
	NSMutableDictionary		*matchingDict	= [[NSMutableDictionary alloc] initWithCapacity:8];
	NSMutableDictionary 	*subDict		= [[NSMutableDictionary alloc] initWithCapacity:8];
	io_iterator_t			iter			= IO_OBJECT_NULL;
	io_object_t				obj				= IO_OBJECT_NULL;

	[subDict setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithCString:kIOPropertySMARTCapableKey]];
	[matchingDict setObject:subDict forKey:[NSString stringWithCString:kIOPropertyMatchKey]];
	[subDict release];
	subDict = NULL;

	error = IOServiceGetMatchingServices (kIOMasterPortDefault, (CFDictionaryRef)matchingDict, &iter);
	if (error != kIOReturnSuccess) {
	} else {

		while ((obj = IOIteratorNext(iter)) != IO_OBJECT_NULL) {		
			
			CFTypeRef   nameData;
			nameData = IORegistryEntrySearchCFProperty(obj, kIOServicePlane, CFSTR("BSD Name"), kCFAllocatorDefault, kIORegistryIterateRecursively); 
			if([(NSString *)nameData isEqualToString:@"disk0"])
				error = [self PerformSMARTUnitTest:obj];
			if(nameData)
				CFRelease(nameData);
			IOObjectRelease(obj);
		}
	}

	if ([diskData count] == 0) {
		iter			= IO_OBJECT_NULL;
		matchingDict	= (NSMutableDictionary *)IOServiceMatching("IOATABlockStorageDevice");

		// Remember - this call eats one reference to the matching dictionary.  In this case, removing the need to release it later
		error = IOServiceGetMatchingServices (kIOMasterPortDefault, (CFDictionaryRef)matchingDict, &iter);
		if (error != kIOReturnSuccess) {
		} else {
			while ((obj = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
				CFTypeRef   nameData;
				nameData = IORegistryEntrySearchCFProperty(obj, kIOServicePlane, CFSTR("BSD Name"), kCFAllocatorDefault, kIORegistryIterateRecursively); 
				if([(NSString *)nameData isEqualToString:@"disk0"])
					error = [self PerformSMARTUnitTest:obj];
				if(nameData)
					CFRelease(nameData);
				IOObjectRelease(obj);
			}
		}
	}
	
	IOObjectRelease(iter);
	iter = IO_OBJECT_NULL;
	
	int x;
	for(x=0;x<[diskData count];x++){
		
	}

	if(latestData){
		[latestData release];
		latestData = nil;
	}
	latestData = diskData;
}

- (NSArray *)getDataSet {
	return latestData;
}

- (void) dealloc {
	if(latestData)
		[latestData release];
	[super dealloc];
}


@end
