//
//  AppDelegate.m
//  Caffeine
//
//  Created by Tomas Franzén on 2006-05-20.
//  Copyright 2006 Lighthead Software. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreServices/CoreServices.h>


@implementation AppDelegate

- (id)init {
	[super init];
	timer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES] retain];
	
	// Workaround for a bug in Snow Leopard where Caffeine would prevent the computer from going to sleep when another account was active.
	userSessionIsActive = YES;
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(userSessionDidResignActive:) name:NSWorkspaceSessionDidResignActiveNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(userSessionDidBecomeActive:) name:NSWorkspaceSessionDidBecomeActiveNotification object:nil];
	
	return self;
}


- (void)awakeFromNib {
	
	NSStatusItem *item = [[[NSStatusBar systemStatusBar] statusItemWithLength:30] retain];
	menuView = [[LCMenuIconView alloc] initWithFrame:NSZeroRect];
	[item setView:menuView];
	[menuView setStatusItem:item];
	[menuView setMenu:menu];
	[menuView setAction:@selector(toggleActive:)];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"SuppressLaunchMessage"]];
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressLaunchMessage"])
		[self showPreferences:nil];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"ActivateOnLaunch"])
		[self toggleActive:nil];
	
}


- (void)dealloc {
	[timer invalidate];
	[timer release];
	[menuView release];
	[timeoutTimer release];
	[super dealloc];
}


- (BOOL)screensaverIsRunning {
	NSString *activeAppID = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"];
	NSArray *bundleIDs = [NSArray arrayWithObjects:@"com.apple.ScreenSaver.Engine", @"com.apple.loginwindow", nil];
	return activeAppID && [bundleIDs containsObject:activeAppID];
}




- (void)activateWithTimeoutDuration:(NSTimeInterval)interval {
	if(timeoutTimer) [[timeoutTimer autorelease] invalidate];
	timeoutTimer = nil;
	if(interval > 0)
		timeoutTimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timeoutReached:) userInfo:nil repeats:NO] retain];
	isActive = YES;
	[menuView setActive:isActive];
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:interval ? interval : -1], @"duration", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.lightheadsw.caffeine.activation" object:nil userInfo:info];	
}

- (void)activate {
	[self activateWithTimeoutDuration:0];	
}

- (void)deactivate {
	isActive = NO;
	if(timeoutTimer) [[timeoutTimer autorelease] invalidate];
	timeoutTimer = nil;
	[menuView setActive:isActive];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.lightheadsw.caffeine.deactivation" object:nil userInfo:nil];
}



- (IBAction)activateWithTimeout:(id)sender {
	int minutes = [(NSMenuItem*)sender tag];
	int seconds = minutes*60;
	if(seconds == -60) seconds = 2;
	if(minutes)
		[self activateWithTimeoutDuration:seconds];
	else
		[self activate];
}



- (void)toggleActive:(id)sender {
	if(timeoutTimer) [[timeoutTimer autorelease] invalidate];
	timeoutTimer = nil;
	
	if(isActive) {
		[self deactivate];
	} else {
		int defaultMinutesDuration = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultDuration"];
		int seconds = defaultMinutesDuration*60;
		if(seconds == -60) seconds = 2;
		if(defaultMinutesDuration)
			[self activateWithTimeoutDuration:seconds];
		else
			[self activate];
	}
}


- (void)timeoutReached:(NSTimer*)timer {
	[self deactivate];
}

- (BOOL)isActive {
	return isActive;
}

- (void)userSessionDidResignActive:(NSNotification *)note {
	userSessionIsActive = NO;
}

- (void)userSessionDidBecomeActive:(NSNotification *)note {
	userSessionIsActive = YES;
}

- (IBAction)showAbout:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:self];
}

- (IBAction)showPreferences:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[firstTimeWindow center];
	[firstTimeWindow makeKeyAndOrderFront:sender];
}


- (void)timer:(NSTimer*)timer {
	if(isActive && ![self screensaverIsRunning] && userSessionIsActive)
		UpdateSystemActivity(UsrActivity);
}


- (LSSharedFileListItemRef)applicationItemInList:(LSSharedFileListRef)list {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	
	NSArray *items = (id)LSSharedFileListCopySnapshot(list, NULL);
	for(id item in items) {    
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		CFURLRef URL = NULL;
		if(LSSharedFileListItemResolve(itemRef, 0, &URL, NULL)) continue;
		
		BOOL matches = [[(NSURL*)URL path] isEqual:appPath];
		CFRelease(URL);
		if(matches)
			return itemRef;
	}
	CFRelease(items);
	return NULL;
}


- (BOOL)startsAtLogin {
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	LSSharedFileListItemRef item = [self applicationItemInList:loginItems];
	BOOL starts = (item != NULL);
	if(item) CFRelease(item);
	CFRelease(loginItems);
	return starts;
}

- (void)setStartsAtLogin:(BOOL)start {
	if(start == [self startsAtLogin]) return;
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if(start) {
		NSString *appPath = [[NSBundle mainBundle] bundlePath];
		CFURLRef appURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)appPath, kCFURLPOSIXPathStyle, YES);
		LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, appURL, NULL, NULL);
		CFRelease(appURL);
	}else{
		LSSharedFileListItemRef item = [self applicationItemInList:loginItems];
		if(item) {
			LSSharedFileListItemRemove(loginItems, item);
			CFRelease(item);
		}
			
	}
	
	CFRelease(loginItems);
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self showPreferences:nil];
	return NO;
}

- (void)menuNeedsUpdate:(NSMenu *)m {
	if(isActive) {
		[infoMenuItem setHidden:NO];
		[infoSeparatorItem setHidden:NO];
		if(timeoutTimer) {
			NSTimeInterval left = [[timeoutTimer fireDate] timeIntervalSinceNow];
			if(left >= 3600)
				[infoMenuItem setTitle:[NSString stringWithFormat:@"%02d:%02d left", (int)(left/3600), (int)(((int)left%3600)/60)]];
			else if(left >= 60)
				[infoMenuItem setTitle:[NSString stringWithFormat:@"%d minutes left", (int)(left/60)]];
			else
				[infoMenuItem setTitle:[NSString stringWithFormat:@"%d seconds left", (int)left]];
		}else{
			[infoMenuItem setTitle:@"Caffeine is active"];
		}
	}else{
		[infoMenuItem setHidden:YES];
		[infoSeparatorItem setHidden:YES];
	}
}

@end
