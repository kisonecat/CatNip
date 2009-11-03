//
//  CatNipPanePref.m
//  CatNipPane
//
//  Created by Jim Fowler on 12/10/06.
//  Copyright (c) 2006 Jim Fowler. All rights reserved.
//

#import "CatNipPanePref.h"
#import <Security/Security.h>
#include <Carbon/Carbon.h>
#include <sys/types.h>
#include <sys/stat.h>

#define DEFAULT_SENSITIVITY 500

@implementation CatNipPanePref

- (NSString*)daemonPath
{
	return daemonPath;
}

- (NSString*)daemonExecutable
{
	return [[[[self daemonPath]
           stringByAppendingPathComponent:@"Contents"]
           stringByAppendingPathComponent:@"MacOS"]
           stringByAppendingPathComponent:@"CatNip"];
}

- (id)initWithBundle:(NSBundle *)bundle
{
    if ( ( self = [super initWithBundle:bundle] ) != nil ) {
        appID = CFSTR("com.kisonecat.catnip");
		daemonPath = [[bundle resourcePath] stringByAppendingPathComponent:@"CatNip.app"];
		[daemonPath retain];
		
		NSDictionary* infoDictionary = [bundle infoDictionary];
		bundleVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
		bundleBuildNumber = [infoDictionary objectForKey:@"CFBundleVersion"];
		
		[bundleVersion retain];
		[bundleBuildNumber retain];

		FSRef fsref;
			
		if (!FSPathMakeRef([[bundle bundlePath] UTF8String], &fsref, NULL)) {
			AHRegisterHelpBook( &fsref );
		}
	}
	
    return self;
}

- (void)mainViewDidLoad
{
    CFPropertyListRef value;

	// Set the version and build number
	[textAuthorName setStringValue:
		[NSString stringWithFormat:[textAuthorName stringValue],
			bundleVersion,
			bundleBuildNumber]];
	
	/* Initialize the checkbox */
    value = CFPreferencesCopyAppValue( CFSTR("Display Message"),  appID );
    if ( value && CFGetTypeID(value) == CFBooleanGetTypeID()  ) {
        [checkboxDisplayMessage setState:CFBooleanGetValue(value)];
    } else {
        [checkboxDisplayMessage setState:YES];
		CFPreferencesSetAppValue( CFSTR("Display Message"), kCFBooleanTrue, appID );
    }
    if ( value ) CFRelease(value);
	
	/* Initialize the checkbox */
    value = CFPreferencesCopyAppValue( CFSTR("Fade Desktop"),  appID );
    if ( value && CFGetTypeID(value) == CFBooleanGetTypeID()  ) {
        [checkboxFadeDesktop setState:CFBooleanGetValue(value)];
    } else {
        [checkboxFadeDesktop setState:YES];
		CFPreferencesSetAppValue( CFSTR("Fade Desktop"), kCFBooleanTrue, appID );
    }
    if ( value ) CFRelease(value);
	
	/* Initialize the checkbox */
    value = CFPreferencesCopyAppValue( CFSTR("Play Sound"),  appID );
    if ( value && CFGetTypeID(value) == CFBooleanGetTypeID()  ) {
        [checkboxPlaySound setState:CFBooleanGetValue(value)];
    } else {
        [checkboxPlaySound setState:NO];
		CFPreferencesSetAppValue( CFSTR("Play Sound"), kCFBooleanFalse, appID );
    }
    if ( value ) CFRelease(value);
	
	/* Initialize the slider */
    value = CFPreferencesCopyAppValue( CFSTR("Sensitivity"),  appID );
	int milliseconds = DEFAULT_SENSITIVITY;
	
    if ( value && CFGetTypeID(value) == CFNumberGetTypeID()  ) {
		CFNumberGetValue( value, kCFNumberIntType, &milliseconds );
    } else {
		CFNumberRef n = CFNumberCreate( NULL, kCFNumberIntType, &milliseconds );
		CFPreferencesSetAppValue( CFSTR("Sensitivity"), n, appID );
		CFRelease(n);
	}
	
	[sliderSensitivity setIntValue:milliseconds];

    if ( value ) CFRelease(value);
	
    /* Initialize the text field */
    value = CFPreferencesCopyAppValue( CFSTR("Human Password"),  appID );
    if ( value && CFGetTypeID(value) == CFStringGetTypeID()  ) {
        [textHumanPassword setStringValue:(NSString *)value];
    } else {
        [textHumanPassword setStringValue:@""];
	}

    if ( value ) CFRelease(value);
	
	[checkboxStartAtLogin setState: [self isInLoginItems]];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(catPong:)
												 name:@"CatPong" object:nil];
	
	daemonPid = -1;
	[self searchForDaemon];
}

- (BOOL) isInLoginItems
{
	NSMutableArray* loginItems;
	
	loginItems = (NSMutableArray*) CFPreferencesCopyValue((CFStringRef)
														  @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow",
														  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	loginItems = [[loginItems autorelease] mutableCopy];
	
	NSEnumerator* enumerator = [loginItems objectEnumerator];
	NSDictionary* d;
	
	[checkboxStartAtLogin setState: NO];
	
	NSString* daemonPath = [self daemonPath];
	
	while (d = [enumerator nextObject]) {
		if ([[d objectForKey: @"Path"] isEqual: daemonPath]) {
			[loginItems release];
			return YES;
		}
	}
	
	CFPreferencesSetValue((CFStringRef)
						  @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef)
						  @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef) @"loginwindow",
							 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	[loginItems release];

	return NO;
}

- (void) removeFromLoginItems
{
	NSMutableArray* loginItems;
	
	loginItems = (NSMutableArray*) CFPreferencesCopyValue((CFStringRef)
														  @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow",
														  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	loginItems = [[loginItems autorelease] mutableCopy];
	
	NSEnumerator* enumerator = [loginItems objectEnumerator];
	NSDictionary* d;
	
	[checkboxStartAtLogin setState: NO];
	
	NSString* daemonPath = [self daemonPath];
	
	while (d = [enumerator nextObject]) {
		if ([[d objectForKey: @"Path"] isEqual: daemonPath]) {
			[loginItems removeObject: d];
		}
	}
	
	CFPreferencesSetValue((CFStringRef)
						  @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef)
						  @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef) @"loginwindow",
							 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[loginItems release];
	
	return;
}

- (void) addToLoginItems
{
	NSMutableArray* loginItems;
	
	loginItems = (NSMutableArray*) CFPreferencesCopyValue((CFStringRef)
														  @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow",
														  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	loginItems = [[loginItems autorelease] mutableCopy];

	[loginItems addObject: [NSDictionary dictionaryWithObjectsAndKeys:
		[self daemonPath], @"Path", [NSNumber numberWithInt: 0], @"Hide", nil ]];
	
	CFPreferencesSetValue((CFStringRef)
						  @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef)
						  @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef) @"loginwindow",
							 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[loginItems release];
	
	return;
}

- (IBAction)clickStartAtLogin:(id)sender
{
	if ([self isInLoginItems]) {
		[self removeFromLoginItems];
	} else {
		[self addToLoginItems];
	}

	[sender setState: [self isInLoginItems]];
}
	
- (void)didUnselect
{
    CFNotificationCenterRef center;
	
    CFPreferencesSetAppValue( CFSTR("Human Password"), 
							  [textHumanPassword stringValue], appID );
    CFPreferencesAppSynchronize( appID );
	
    center = CFNotificationCenterGetDistributedCenter();
    CFNotificationCenterPostNotification(center,
										 CFSTR("Preferences Changed"), appID, NULL, TRUE);
}

- (void)startStopDaemon:(id)sender
{
	if (daemonPid < 0) {
		[textfieldDaemonStatus setStringValue:
				NSLocalizedStringFromTableInBundle(@"IsStarting",nil,[NSBundle bundleForClass:[self class]], @"Starting")];
		[buttonToggleDaemon setEnabled: NO];
		[self startDaemon];
	} else {
		[textfieldDaemonStatus setStringValue:
				NSLocalizedStringFromTableInBundle(@"NotRunning",nil,[NSBundle bundleForClass:[self class]], @"Not Running")];
		[self stopDaemon];
	}

	return;
}

- (void) stopDaemon
{
	if (daemonPid >= 0) {
		[textfieldDaemonStatus setStringValue:
			NSLocalizedStringFromTableInBundle(@"NotRunning",nil,[NSBundle bundleForClass:[self class]], @"Not Running")];
		[buttonToggleDaemon setTitle:
			NSLocalizedStringFromTableInBundle(@"StartCommand",nil,[NSBundle bundleForClass:[self class]], @"Start Command")];
		[buttonToggleDaemon setEnabled: YES];

		kill(daemonPid, SIGTERM);
	
		daemonPid = -1;
	}
}

-(BOOL)isDaemonSetuid
{
	struct stat s;
	
	// Get the file permissions of the daemon
	stat( [[self daemonExecutable] cString], &s );
	
	// Is the daemon owned by root and setuid?
	if ((s.st_uid == 0) && (s.st_mode & S_ISUID))
		return YES;
	
	return NO;
}

-(void)setuidDaemon
{
	AuthorizationRef authRef;
	OSStatus status;
	AuthorizationFlags flags;
	
	flags = kAuthorizationFlagDefaults;
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,  
								 flags, &authRef);
	
	if (status != errAuthorizationSuccess) {
		return;
	}
	
	AuthorizationItem authItems = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &authItems};
	flags = kAuthorizationFlagDefaults |  
		kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize |  
		kAuthorizationFlagExtendRights;
	
	status = AuthorizationCopyRights (authRef, &rights, NULL, flags, NULL);
	if (status != errAuthorizationSuccess) {
		AuthorizationFree(authRef,kAuthorizationFlagDefaults);
		return;
	}
	
	FILE* pipe = NULL;
	flags = kAuthorizationFlagDefaults;
	
	char* args[3];

	args[0] = "root";
	args[1] = [[self daemonExecutable] cString];
	args[2] = NULL;
	
	status =  
		AuthorizationExecuteWithPrivileges(authRef,"/usr/sbin/chown",flags,args,&pipe);
	if (status == noErr) {
		int result;
		wait(&result);
		// NSRunAlertPanel( @"waiting finished", @"chowned!", nil, nil, nil );
	}
	
	args[0] = "+s";
	args[1] = [[self daemonExecutable] cString];
	args[2] = NULL;
	
	status =  
		AuthorizationExecuteWithPrivileges(authRef,"/bin/chmod",flags,args,&pipe);
	if (status == noErr) {
		int result;
		wait(&result);
		// NSRunAlertPanel( @"waiting finished", @"chmoded!", nil, nil, nil );
	}
	
	AuthorizationFree(authRef,kAuthorizationFlagDefaults);
	
	return;
}

-(void) startDaemon
{
	if (daemonPid < 0) {
		if ([self isDaemonSetuid] == NO)
			[self setuidDaemon];
		
		NSTask* daemonTask = [[NSTask alloc] init];
		
		[daemonTask setLaunchPath:[self daemonExecutable]];
		[daemonTask setArguments:[NSArray arrayWithObject:@""]];
		[daemonTask launch];
	}
}

-(void) searchForDaemon
{
	CFNotificationCenterRef center;

	center = CFNotificationCenterGetDistributedCenter();
    CFNotificationCenterPostNotification(center,
										 CFSTR("CatPing"), appID, NULL, TRUE);
}

-(void)catPong:(NSNotification*)aNotification
{
	NSLog( @"hear pong\n" );
	
	if (daemonPid < 0) {
		daemonPid = [[[aNotification userInfo] objectForKey:@"processIdentifier"] intValue];
		NSLog( @"hear pong from pid %d\n", daemonPid );
		
		[textfieldDaemonStatus setStringValue:
			NSLocalizedStringFromTableInBundle(@"IsRunning", nil, [NSBundle bundleForClass:[self class]], @"Running")];
		[buttonToggleDaemon setTitle:
			NSLocalizedStringFromTableInBundle(@"StopCommand", nil, [NSBundle bundleForClass:[self class]], @"Stop Command")];
		[buttonToggleDaemon setEnabled: YES];
	}

	return;
}

- (IBAction)checkboxClicked:(id)sender
{
	if ( [checkboxDisplayMessage state] )
        CFPreferencesSetAppValue( CFSTR("Display Message"), kCFBooleanTrue, appID );
	else
		CFPreferencesSetAppValue( CFSTR("Display Message"), kCFBooleanFalse, appID );
	
	if ( [checkboxFadeDesktop state] )
        CFPreferencesSetAppValue( CFSTR("Fade Desktop"), kCFBooleanTrue, appID );
	else
		CFPreferencesSetAppValue( CFSTR("Fade Desktop"), kCFBooleanFalse, appID );
    
	if ( [checkboxPlaySound state] )
        CFPreferencesSetAppValue( CFSTR("Play Sound"), kCFBooleanTrue, appID );
	else
		CFPreferencesSetAppValue( CFSTR("Play Sound"), kCFBooleanFalse, appID );
}

- (IBAction) changeSensitivity:(id)sender
{
	int milliseconds = [(NSSlider*)sender intValue];
	
	CFNumberRef n = CFNumberCreate( NULL, kCFNumberIntType, &milliseconds );

	CFPreferencesSetAppValue( CFSTR("Sensitivity"), n, appID );
	
	CFRelease(n);
}

- (IBAction) donate:(id)sender
{
	[[NSWorkspace sharedWorkspace]
		openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=jim%40uchicago%2eedu&item_name=CatNip&no_shipping=2&no_note=1&tax=0&currency_code=USD&bn=PP%2dDonationsBF&charset=UTF%2d8"]];
}

- (IBAction) sendEmail:(id)sender
{
	[[NSWorkspace sharedWorkspace]
		openURL:[NSURL URLWithString:@"mailto:jim@uchicago.edu?subject=CatNip"]];
}

- (IBAction)showHelp:(id)sender
{
	// NSRunAlertPanel(@"showing help", @"trying to show help", @"OK", nil, nil );
	
	AHGotoPage( @"CatNip Help", NULL, @"" );
}

@end
