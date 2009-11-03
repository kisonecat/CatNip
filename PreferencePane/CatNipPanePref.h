//
//  CatNipPanePref.h
//  CatNipPane
//
//  Created by Jim Fowler on 12/10/06.
//  Copyright (c) 2006 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <CoreFoundation/CoreFoundation.h>


@interface CatNipPanePref : NSPreferencePane 
{
	IBOutlet NSButton    *checkboxStartAtLogin;
	IBOutlet NSButton    *checkboxDisplayMessage;
	IBOutlet NSButton    *checkboxFadeDesktop;
	IBOutlet NSButton    *checkboxPlaySound;
	IBOutlet NSTextField *textHumanPassword;
	IBOutlet NSSlider    *sliderSensitivity;
	IBOutlet NSTextField *textAuthorName;
	
	IBOutlet NSTextField *textfieldDaemonStatus;
	IBOutlet NSButton *buttonToggleDaemon;
	
	NSObject* bundleVersion;
	NSObject* bundleBuildNumber;
	
	CFStringRef appID;
	int daemonPid;
	
	NSString* daemonPath;
}

- (id)initWithBundle:(NSBundle *)bundle;
- (void)mainViewDidLoad;
- (void)didUnselect;

- (void)startStopDaemon:(id)sender;
- (void)clickStartAtLogin:(id)sender;

- (BOOL) isInLoginItems;
- (void) removeFromLoginItems;
- (void) addToLoginItems;

- (IBAction) changeSensitivity:(id)sender;
- (IBAction) donate:(id)sender;
- (IBAction) sendEmail:(id)sender;

- (IBAction)showHelp:(id)sender;

@end
