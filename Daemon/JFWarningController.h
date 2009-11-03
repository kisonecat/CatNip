//
//  JFWarningController.h
//  CatNip
//
//  Created by Jim Fowler on 12/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JFWarningView.h"

@interface JFWarningController : NSWindowController {
	IBOutlet JFWarningView* warningView;
	IBOutlet NSMenu* theMenu;
	NSStatusItem* statusItem;
	BOOL playSound;
}

- (IBAction)quitCatNip:(id)sender;
- (IBAction)showPreferencePane:(id)sender;
- (IBAction)toggleMonitoring:(id)sender;

@end
