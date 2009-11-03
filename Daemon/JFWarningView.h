//
//  JFWarningView.h
//  CatNip
//
//  Created by Jim Fowler on 12/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JFWarningView : NSView {
	BOOL displayMessage;
	BOOL fadeDesktop;
}

- (void)setFadeDesktop: (BOOL)b;
- (void)setDisplayMessage: (BOOL)b;

@end
