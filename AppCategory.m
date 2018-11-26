//
//  AppCategory.m
//  Caffeine
//
//  Created by Tomas Franzén on 2008-06-04.
//  Copyright 2008 Lighthead Software. All rights reserved.
//

#import "AppCategory.h"
#import "AppDelegate.h"


@implementation NSApplication (AppCategory)


- (void)activateCaffeine:(NSScriptCommand*)command {
	NSNumber *duration = [[command arguments] objectForKey:@"duration"];
	if(duration)
		[[self delegate] activateWithTimeoutDuration:[duration doubleValue]];
	else
		[[self delegate] activate];
}

- (void)deactivateCaffeine:(NSScriptCommand*)command {
	[[self delegate] deactivate];
}

- (BOOL)isCaffeineActive {
	return [[self delegate] isActive];
}

@end
