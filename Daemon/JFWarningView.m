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
		float textheight = height/20;
		
		CGContextSelectFont (myContext,
							 "LucidaGrande-Bold",
							 textheight,
							 kCGEncodingMacRoman); 
		CGContextSetCharacterSpacing (myContext, 0);
		
		CGContextSetTextDrawingMode(myContext,kCGTextInvisible);
		
		NSString* warningMessage =
			NSLocalizedStringFromTable( @"WarningMessage",
										@"Messages",
										@"" );
		
		CGContextShowTextAtPoint (myContext, 0, 0,
								  [warningMessage cString],
								  [warningMessage length]);
		
		CGPoint end = CGContextGetTextPosition(myContext);
		float textWidth = end.x;

		if (fadeDesktop) {
			CGContextSetTextDrawingMode (myContext, kCGTextFillStroke);
			CGContextSetRGBStrokeColor (myContext, 1, 1, 1, .75);
		} else {
			CGContextSetTextDrawingMode(myContext,kCGTextFill); 
		}
		CGContextSetRGBFillColor (myContext, 1, 0, 0, .5);
		
		CGContextShowTextAtPoint (myContext, width/2 - textWidth/2, height/2,
								  [warningMessage cString],
								  [warningMessage length] );
	}
	
	if (1)
	{
		NSString* unlockMessage =
			NSLocalizedStringFromTable( @"UnlockMessage",
										@"Messages",
										@"" );
															
		CGContextSelectFont (myContext,
							 "LucidaGrande-Bold",
							 height/25,
							 kCGEncodingMacRoman); 
		CGContextSetCharacterSpacing (myContext, 0);
		
		CGContextSetTextDrawingMode(myContext,kCGTextInvisible);
		CGContextShowTextAtPoint( myContext, 0, 0,
								  [unlockMessage cString],
								  [unlockMessage length]);
		
		CGPoint end = CGContextGetTextPosition(myContext);
		float messageWidth = end.x;
		
		CGContextSetTextDrawingMode (myContext, kCGTextFillStroke);
		if (fadeDesktop) {
			CGContextSetRGBFillColor (myContext, 1, 1, 1, 0.8);
			CGContextSetRGBStrokeColor (myContext, 0, 0, 0, 0.5);
		} else {
			CGContextSetRGBFillColor (myContext, 0, 0, 0, .95);
			CGContextSetRGBStrokeColor (myContext, 1, 1, 1, .95);
		}
		CGContextShowTextAtPoint (myContext, width - messageWidth, 5,
								  [unlockMessage cString],
								  [unlockMessage length]);
	}
	
	return;
}

@end
