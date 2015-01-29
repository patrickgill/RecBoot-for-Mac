//
//  RecBootAppDelegate.m
//  RecBoot
//
//  Created by Sebastien Peek on 23/12/10.
//  Copyright 2010 sebby.net. All rights reserved.
//

#import "RecBootAppDelegate.h"

static RecBootAppDelegate *classPointer;
struct am_device* device;
struct am_device_notification *notification;

void notification_callback(struct am_device_notification_callback_info *info, int cookie) {	
	if (info->msg == ADNCI_MSG_CONNECTED) {
		NSLog(@"Device connected.");
		device = info->dev;
		AMDeviceConnect(device);
		AMDevicePair(device);
		AMDeviceValidatePairing(device);
		AMDeviceStartSession(device);
		[classPointer populateData];
	} else if (info->msg == ADNCI_MSG_DISCONNECTED) {
		NSLog(@"Device disconnected.");
		[classPointer dePopulateData];
	} else {
		NSLog(@"Received device notification: %d", info->msg);
	}
}

void recovery_connect_callback(struct am_recovery_device *rdev) {
	[classPointer recoveryCallback];
}

void recovery_disconnect_callback(struct am_recovery_device *rdev) {
	[classPointer dePopulateData];
}

@implementation RecBootAppDelegate

@synthesize window, exitRecBut, loadingInd;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	classPointer = self;
	AMDeviceNotificationSubscribe(notification_callback, 0, 0, 0, &notification);
	AMRestoreRegisterForDeviceNotifications(recovery_disconnect_callback, recovery_connect_callback, recovery_disconnect_callback, recovery_disconnect_callback, 0, NULL);
	
	NSString *foundValue = [deviceDetails stringValue];
	
	if ([foundValue isEqualToString:@"Recovery device connected"]) {
		
		[exitRecBut setEnabled:YES];
	
	} else {
		[exitRecBut setEnabled:NO];
	}

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (IBAction)enterRec:(id)pId {
	[classPointer enterRecovery];
	[classPointer dePopulateData];
	[classPointer loadingProgress];
}

- (void)enterRecovery {
	AMDeviceConnect(device);
	AMDeviceEnterRecovery(device);
}

- (IBAction)exitRec:(id)pId {
	
	[classPointer loadingProgress];
	//Allow the user to exit recovery mode through the application.
	
	//Makes recoverset the NSTask to be used.
	NSTask *recoverset = [[NSTask alloc] init];
	
	//Sets launch path.
	[recoverset setLaunchPath: [[NSBundle mainBundle] pathForResource:@"irecovery" ofType:nil]];
	//Sends the following command to irecovery.
	[recoverset setArguments:[NSArray arrayWithObjects:@"-c", @"setenv auto-boot true",nil]];
	[recoverset launch];
	[recoverset waitUntilExit];
	
	//Makes recoversave the NSTask to be used.
	NSTask *recoversave = [[NSTask alloc] init];
	//Sets launch path.
	[recoversave setLaunchPath: [[NSBundle mainBundle] pathForResource:@"irecovery" ofType:nil]];
	//Sends the following command to irecovery.
	[recoversave setArguments:[NSArray arrayWithObjects:@"-c", @"saveenv",nil]];
	[recoversave launch];
	[recoversave waitUntilExit];
	
	//Makes recoverreboot the NSTask to be used.
	NSTask *recoverreboot = [[NSTask alloc] init];
	//Sets launch path.
	[recoverreboot setLaunchPath: [[NSBundle mainBundle] pathForResource:@"irecovery" ofType:nil]];
	//Sends the following command to irecovery.
	[recoverreboot setArguments:[NSArray arrayWithObjects:@"-c", @"reboot",nil]];
	[recoverreboot launch];
	
}

- (void)recoveryCallback {
	[deviceDetails setStringValue:@"Recovery device connected"];
	[exitRecBut setEnabled:YES];
	[loadingInd setHidden:YES];
}

- (IBAction)Reboot:(id)pId {
    [classPointer rebootDevice];
    //[classPointer dePopulateData];
    //[classPointer loadingProgress];
}

- (void)rebootDevice {
    //AMDeviceConnect(device);
}

- (void)populateData {
	NSString *serialNumber = [self getDeviceValue:@"SerialNumber"];
    NSString *productType = [self getDeviceValue:@"ProductType"];
	NSString *modelNumber = [self getDeviceValue:@"ModelNumber"];
	NSString *firmwareVersion = [self getDeviceValue:@"ProductVersion"];
	NSString *deviceString = [self getDeviceValue:@"ProductType"];
	
	if ([deviceString isEqualToString:@"iPod1,1"]) {
		deviceString = @"iPod Touch 1G";
	} else if ([deviceString isEqualToString:@"iPod2,1"]) {
		deviceString = @"iPod Touch 2G";
	} else if ([deviceString isEqualToString:@"iPod3,1"]) {
		deviceString = @"iPod Touch 3G";
	} else if ([deviceString isEqualToString:@"iPhone1,1"]) {
		deviceString = @"iPhone 2G";
	} else if ([deviceString isEqualToString:@"iPhone1,2"]) {
		deviceString = @"iPhone 3G";
	} else if ([deviceString isEqualToString:@"iPhone2,1"]) {
		deviceString = @"iPhone 3G[S]";
	} else if ([deviceString isEqualToString:@"iPhone3,1"]) {
		deviceString = @"iPhone 4";
	} else if ([deviceString isEqualToString:@"iPad1,1"]) {
		deviceString = @"iPad 1G";
	} else {
		//deviceString = @"Unknown";
	}
	
	//if (deviceString == @"Unknown") {
    if ([deviceString isEqualToString: @"Unknown"]) {
		NSString *completeString = [NSString stringWithFormat:@"%@ Mode/Device detected",deviceString];
		[deviceDetails setStringValue:completeString];
	} else {
		[loadingInd setHidden:YES];
		NSString *completeString = [NSString stringWithFormat:@"%@ (%@), %@, %@, %@", deviceString, productType, modelNumber, firmwareVersion, serialNumber];
		[deviceDetails setStringValue:completeString];
	}
	
}

- (void)dePopulateData {
	[deviceDetails setStringValue:@""];
	[exitRecBut setEnabled:NO];
}

- (void)loadingProgress {
	[loadingInd setHidden:NO];
	[loadingInd startAnimation: self];
}

- (NSString *)getDeviceValue:(NSString *)value {
	return AMDeviceCopyValue(device, 0, value);
    //return (NSString *)AMDeviceCopyValue(device, 0, value);
}

@end
