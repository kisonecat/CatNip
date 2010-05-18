//
//  JFWarningView.m
//  CatNip
//
//  Created by Jim Fowler on 12/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JFWarningView.h"

@implementation JFWarningView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		displayMessage = YES;
		fadeDesktop = YES;
    }
    return self;
}

- (void)setFadeDesktop: (BOOL)b
{
	fadeDesktop = b;
	
	NSLog( @"fadeDesktop = %d\n", fadeDesktop );
	
	[self setNeedsDisplay: YES];
}

- (void)setDisplayMessage: (BOOL)b
{
	displayMessage = b;
	
	NSLog( @"displayMessage = %d\n", displayMessage );
	
	[self setNeedsDisplay: YES];
}

- (void)drawRect:(NSRect)rect
{
	CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
	
	float height = NSHeight([self frame]);
	float width = NSWidth([self frame]);
	
	CGContextSetRGBFillColor (myContext, 1, 1, 1, 0);
	CGContextFillRect (myContext, CGRectMake (0, 0, width, height));
	
	[[self window] setHasShadow: NO];
	
	if (fadeDesktop)
	{
		CGContextSetRGBFillColor (myContext, 0, 0, 0, .5);
		CGContextFillRect (myContext, CGRectMake (0, 0, width, height));
	}
	
	if (displayMessage)
	{
		NSString* warningMessage =
			NSLocalizedStringFromTable( @"WarningMessage",
										@"Messages",
										@"" );
		
		NSMutableDictionary *warningMessageAttrs = [NSMutableDictionary dictionaryWithCapacity:3];
		NSFont *warningMessageFont = [NSFont fontWithName:@"LucidaGrande-Bold" size:height/20];
		[warningMessageAttrs setObject:warningMessageFont forKey:NSFontAttributeName];
		
		if (fadeDesktop) {
			NSColor *textColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.75];
			NSColor *strokeColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.75];
			[warningMessageAttrs setObject:textColor forKey:NSForegroundColorAttributeName];
			[warningMessageAttrs setObject:strokeColor forKey:NSStrokeColorAttributeName];
			CGContextSetTextDrawingMode (myContext, kCGTextFillStroke);
		}
		else {
			NSColor *textColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.5];
			[warningMessageAttrs setObject:textColor forKey:NSForegroundColorAttributeName];
			CGContextSetTextDrawingMode(myContext,kCGTextFill);
		}
		
		[warningMessage drawAtPoint:NSMakePoint((width - [warningMessage sizeWithAttributes:warningMessageAttrs].width)/2, height/2)
					 withAttributes:warningMessageAttrs];
	}
	
	if (1)
	{
		NSString* unlockMessage =
			NSLocalizedStringFromTable( @"UnlockMessage",
										@"Messages",
										@"" );
		NSMutableDictionary *unlockMessageAttrs = [NSMutableDictionary dictionaryWithCapacity:3];
		NSFont *unlockMessageFont = [NSFont fontWithName:@"LucidaGrande-Bold" size:height/25];
		[unlockMessageAttrs setObject:unlockMessageFont forKey:NSFontAttributeName];
		
		if (fadeDesktop) {
			NSColor *textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.8];
			NSColor *strokeColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
			[unlockMessageAttrs setObject:textColor forKey:NSForegroundColorAttributeName];
			[unlockMessageAttrs setObject:strokeColor forKey:NSStrokeColorAttributeName];
		}
		else {
			NSColor *textColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.95];
			NSColor *strokeColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.95];
			[unlockMessageAttrs setObject:textColor forKey:NSForegroundColorAttributeName];
			[unlockMessageAttrs setObject:strokeColor forKey:NSStrokeColorAttributeName];
		}
		CGContextSetTextDrawingMode (myContext, kCGTextFillStroke);
		[unlockMessage drawAtPoint:NSMakePoint(width - [unlockMessage sizeWithAttributes:unlockMessageAttrs].width - 5, 5)
					withAttributes:unlockMessageAttrs];
	}
	
	return;
}

@end
