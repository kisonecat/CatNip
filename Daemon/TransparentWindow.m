#import "TransparentWindow.h"

@implementation TransparentWindow

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
{
    if (self = [super initWithContentRect: contentRect
                                styleMask: NSBorderlessWindowMask
                                  backing: bufferingType
                                    defer: flag]) {
		[self setLevel: NSStatusWindowLevel];
		[self setBackgroundColor: [NSColor clearColor]];
		[self setLevel: NSStatusWindowLevel];
		[self setAlphaValue:1.0];
		[self setOpaque:NO];
		[self setHasShadow:NO];
		[self setIgnoresMouseEvents:YES];
	}
	
	return self;
}


@end
