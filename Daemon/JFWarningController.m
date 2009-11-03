//
//  JFWarningController.m
//  CatNip
//
//  Created by Jim Fowler on 12/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JFWarningController.h"

#define DEFAULT_SENSITIVITY 500

extern int millisecondsSensitivity;

@implementation JFWarningController

static JFWarningController* sharedWarningController;

+(JFWarningController*)sharedController
{
	return sharedWarningController;
}

- (void)catLikeTypingDetected:(NSNotification *)notification
{
	[self displayWarning];
}

- (void)humanTypingDetected:(NSNotification *)notification
{
	[self hideWarning];
}

- (void)loadPreferences:(NSNotification *)notification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults synchronize];
	
	NSDictionary *appDefaults = [NSDictionary
		dictionaryWithObjectsAndKeys:
		@"YES", @"Fade Desktop",
		@"YES", @"Display Message",
		@"NO", @"Play Sound",
		@"human", @"Human Password",
		[NSNumber numberWithInt: DEFAULT_SENSITIVITY], @"Sensitivity",
		nil];
	   
	[defaults registerDefaults:appDefaults];
	
	[warningView setFadeDesktop: [defaults boolForKey:@"Fade Desktop"]];
	[warningView setDisplayMessage: [defaults boolForKey:@"Display Message"]];
	
	millisecondsSensitivity = [defaults integerForKey:@"Sensitivity"];
	
	playSound = [defaults boolForKey:@"Play Sound"];
}

- (void)awakeFromNib
{
	sharedWarningController = self;

	// create status bar item
	/*
	NSStatusBar *bar = [NSStatusBar systemStatusBar];

    statusItem = [bar statusItemWithLength:NSSquareStatusItemLength];
    [statusItem retain];
	
	NSImage* image = [NSImage imageNamed: @"StatusItem"];
	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize([bar thickness],[bar thickness])];
    [statusItem setImage: image];
    [statusItem setHighlightMode:YES];
	[statusItem setMenu:[[theMenu itemAtIndex:0] submenu]];
	*/
	
	// move the window into position
	[[self window] setFrame:[[NSScreen mainScreen] frame] display:YES];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(catLikeTypingDetected:)
												 name:@"CatLikeTyping" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(humanTypingDetected:)
												 name:@"HumanTyping" object:nil];

	[self loadPreferences: nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadPreferences:)
												 name:@"Preferences Changed" object:nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(catPing:)
															name:@"CatPing" object:nil];
	
	[self catPing: nil];
}


- (void)displayWarning
{
	if (playSound) {
		NSBeep();
	}
	
	[[self window] orderFront:self];
}

- (void)hideWarning
{
	[[self window] orderOut:self];
}

- (void)catPing:(NSNotification*)aNotification
{
	[[NSDistributedNotificationCenter defaultCenter]
		postNotificationName:@"CatPong"
					  object:@"CatNip"
					userInfo:[NSDictionary dictionaryWithObject: [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]
														 forKey: @"processIdentifier"]];
}

- (IBAction)quitCatNip:(id)sender
{
	[NSApp terminate:sender];
	return;
}

- (IBAction)showPreferencePane:(id)sender
{
}

- (IBAction)toggleMonitoring:(id)sender
{
}


@end
