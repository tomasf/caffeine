//
//  LCMenuIconView.m
//  Caffeine
//
//  Created by Tomas Franzén on 2009-09-04.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import "LCMenuIconView.h"


@implementation LCMenuIconView
@synthesize isActive, statusItem, menu;

- (id)initWithFrame:(NSRect)r {
	[super initWithFrame:r];
	activeImage = [[NSImage imageNamed:@"active"] retain];
	inactiveImage = [[NSImage imageNamed:@"inactive"] retain];
	
	highlightImage = [[NSImage imageNamed:@"highlighted"] retain];
	highlightActiveImage = [[NSImage imageNamed:@"highlightactive"] retain];
	return self;
}


- (void)drawRect:(NSRect)r {
	NSImage *i = isActive ? activeImage : inactiveImage;
	if(menuIsShown) i = isActive ? highlightActiveImage : highlightImage;
	NSRect f = [self bounds];
	NSPoint p = NSMakePoint(f.size.width/2 - [i size].width/2, f.size.height/2 - [i size].height/2 + 1);
	
	if(menuIsShown) [statusItem drawStatusBarBackgroundInRect:r withHighlight:YES];
	[i drawAtPoint:p fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}


- (void)setActive:(BOOL)flag {
	isActive = flag;
	[self setNeedsDisplay:YES];
}


- (void)rightMouseDown:(NSEvent*)e {
	menuIsShown = YES;
	[self setNeedsDisplay:YES];
	[statusItem popUpStatusItemMenu:menu];
	menuIsShown = NO;
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)e {
	if([e modifierFlags] & (NSCommandKeyMask | NSControlKeyMask))
		return [self rightMouseDown:e];
	
	[NSApp sendAction:action to:target from:self];
}

- (void)mouseUp:(NSEvent *)theEvent {
	if([NSDate timeIntervalSinceReferenceDate] - lastMouseUp < 0.2) {
		[NSApp sendAction:@selector(showPreferences:) to:nil from:nil];
		lastMouseUp = 0;
	} else lastMouseUp = [NSDate timeIntervalSinceReferenceDate];
}




- (void)setAction:(SEL)a {
	action = a;
}

- (void)setTarget:(id)t {
	target = t;
}


@end
