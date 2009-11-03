/* Catnip - uses a markov chain to determine the likelihood of keypresses, and
   if a series of unlikely keypresses occurs, it then freezes the keyboard. */

#include <ApplicationServices/ApplicationServices.h>
#include <CoreServices/CoreServices.h>
#include <Carbon/Carbon.h>
#include "FSM.h"

int allowTyping = 1;

int millisecondsSensitivity = 500;

#define MAX_KEYCODE 128

typedef struct tagKeycap
{
	Rect rect;
} Keycap;

Keycap keycaps[MAX_KEYCODE];

static OSStatus FlipKcapResource (OSType dataDomain, 
                    OSType dataType,  
                    short id,  
                    void * dataPtr,  
                    UInt32 dataSize,  
                    Boolean currentlyNative, 
                    void* refcon) 
{
	UInt32  versionNumber;
	OSStatus status = noErr; 
	unsigned char* kcapData = (unsigned char*)dataPtr;

	// move past RECT keyboard boundary
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	
	// move past RECT editable line of text
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	
	// get number of key shapes
	short keyShapeCount = *((short*)kcapData);
	if (!currentlyNative)
		keyShapeCount = Endian16_Swap(keyShapeCount);
	*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
	kcapData += 2;
	
	int i;
	for( i=0; i<keyShapeCount; i++ ) {
		short pointCount = *((short*)kcapData);
		if (!currentlyNative)
			pointCount = Endian16_Swap(pointCount);
		*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
		kcapData += 2;

		pointCount++;
		
		int k;
		for( k=0; k<pointCount; k++ ) {
			*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
			kcapData += 2;
			
			*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
			kcapData += 2;
		}
		
		short keyCount = *((short*)kcapData);
		if (!currentlyNative)
			keyCount = Endian16_Swap(keyCount);
		*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
		kcapData += 2;
		
		keyCount++;
		
		int j;
		for( j=0; j<keyCount; j++ ) {
			*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
			kcapData += 2;
			
			*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
			kcapData += 2;
			
			*((short*)kcapData) = Endian16_Swap( *((short*)kcapData) );
			kcapData += 2;
		}
	}
		
	return status;
} 


void loadPhysicalLayout( void )
{
	Handle  KCAPHdl = NULL;

	OSStatus status = noErr; 
	status = CoreEndianInstallFlipper (kCoreEndianAppleEventManagerDomain, 
					   'KCAP',
					   FlipKcapResource,
					   NULL); 
	if (status == noErr) {
		// printf( "Successfully installed flipper.\n" );
	} else {
		// printf( "Could not install flipper.\n" );
	}

	/*
	long keyboardType;
	Gestalt( gestaltKeyboardType, &keyboardType );
	printf( "gestalt = %d\n", keyboardType );
	*/
	
	UInt8 keyboardType = LMGetKbdType();
	// printf( "You are on keyboard type %d\n", keyboardType );

	FSRef resourceFile;
		
	char* filename = "/System/Library/Components/KeyboardViewer.component/Contents/SharedSupport/KeyboardViewerServer.app/Contents/Resources/KeyboardViewerServer.rsrc";
				
	status = FSPathMakeRef( filename, &resourceFile, NULL );
	if (status == noErr) {
		short resourceRef;
		
		status = FSOpenResourceFile ( &resourceFile, 0, NULL, fsRdPerm, &resourceRef );
		if (status == noErr) {
			UseResFile( resourceRef );
			KCAPHdl = GetResource( 'KCAP', keyboardType );
		}
	}
		
	if (KCAPHdl == NULL) {
		// printf( "Could not load KCAP resource from KeyboardViewer component.\n" );
		
		UseResFile( 0 );
		KCAPHdl = GetResource( 'KCAP', keyboardType );

		if (KCAPHdl == NULL) {
			// printf( "Could not load KCAP resource from system.\n" );
			exit(0);
		}
	}
		

	unsigned char* kcapData = (unsigned char *)  (*KCAPHdl);

	short data;
	
	// move past RECT keyboard boundary
	short x1 = *((short*)kcapData);
	kcapData += 2;
	short y1 = *((short*)kcapData);
	kcapData += 2;
	short x2 = *((short*)kcapData);
	kcapData += 2;
	short y2 = *((short*)kcapData);
	kcapData += 2;

	// printf( "keyboard boundary = (%d,%d) to (%d,%d)\n", x1, y1, x2, y2 );
	
	// move past RECT editable line of text
	data = *((short*)kcapData);
	kcapData += 2;
	data = *((short*)kcapData);
	kcapData += 2;
	data = *((short*)kcapData);
	kcapData += 2;
	data = *((short*)kcapData);
	kcapData += 2;

	// get number of key shapes
	short keyShapeCount = *((short*)kcapData);
	kcapData += 2;

	int x = 0;
	int y = 0;
	
	int i;
	for( i=0; i<keyShapeCount; i++ ) {
		short pointCount = *((short*)kcapData);
		kcapData += 2;
		pointCount++;
		
		short width;
		short height;
		
		int k;
		for( k=0; k<pointCount; k++ ) {
			width = *((short*)kcapData);
			kcapData += 2;
			
			height = *((short*)kcapData);
			kcapData += 2;

			// printf( "shape %d, size (%d,%d)\n", i, width, height );
		}
		
		short keyCount = *((short*)kcapData);
		kcapData += 2;
		keyCount++;
		
		x = 0;
		y = 0;
		
		int j;
		for( j=0; j<keyCount; j++ ) {
			short keycode = *((short*)kcapData);
			kcapData += 2;

			short xOffset = *((short*)kcapData);
			kcapData += 2;

			short yOffset = *((short*)kcapData);
			kcapData += 2;

			x += xOffset;
			y += yOffset;
			
			// printf( "keycode %d at (%d,%d)\n", keycode, x, y );
			
			if ((keycode >= 0) && (keycode < MAX_KEYCODE)) {
				keycaps[keycode].rect.top = y;
				keycaps[keycode].rect.left = x;
				keycaps[keycode].rect.bottom = y + height - 1;
				keycaps[keycode].rect.right = x + width - 1;
			}
		}
	}

	// PSDrawKeycaps();
	
	return;
}

void PSDrawRect( Rect* rect )
{
	printf( "%d %d moveto\n", rect->left, rect->top );  
	printf( "%d %d lineto\n", rect->right, rect->top );  
	printf( "%d %d lineto\n", rect->right, rect->bottom );  
	printf( "%d %d lineto\n", rect->left, rect->bottom );  
	printf( "%d %d lineto\n", rect->left, rect->top
			);  
	printf( "stroke\n\n" );
}

void PSDrawKeycaps( void )
{
	printf( "%%!\n" );
	printf( "%%%%\n" );
	printf( "%%%%BoundingBox:  0 0 500 500\n" );
	
	printf( "50 50 translate\n" );
	
	int i;
	for( i=0; i<128; i++ ) {
		PSDrawRect( &(keycaps[i]) );
	}
	
	printf ("showpage\n" );
	
	return;
}

Boolean areTouching( int a, int b )
{
	Rect ra = keycaps[a].rect;
	Rect rb = keycaps[b].rect;

	InsetRect( &ra, -2, -2 );
	InsetRect( &rb, -2, -2 );

	Rect intersection;
	
	SectRect( &ra, &rb, &intersection );
	
	if (EmptyRect( &intersection ))
		return false;
	// else
		return true;
}

////////////////////////////////////////////////////////////////////////
// Keycode to Character translation

void* kchrTranslation;

void loadKeyboardLayout( void )
{
	KeyboardLayoutRef layout;
	KLGetCurrentKeyboardLayout( &layout );
	KLGetKeyboardLayoutProperty( layout, kKLKCHRData, &kchrTranslation );

	return;
}

char translateKey( CGKeyCode keycode, CGEventType type )
{
	UInt16 keycodeForTranslation = keycode;
	static UInt32 translationState = 0;
	
	if (type == kCGEventKeyDown) {
		keycodeForTranslation &= 0x7F;
	}
	
	if (type == kCGEventKeyUp) {
		keycodeForTranslation |= 0x80;
	}
	
	UInt32 result = KeyTranslate( kchrTranslation, keycodeForTranslation, &translationState );
	
	return (char)result;
}

////////////////////////////////////////////////////////////////////////
// Finite state machine

////////////////////////////////////////////////////////////////////////
// Event callback

FSM* machine;
FSM_STATE* state;

// UnsignedWide pressTime[128];

pascal void TimerAction (EventLoopTimerRef  theTimer,
                         void* userData)
{
	CFNotificationCenterPostNotification (CFNotificationCenterGetLocalCenter(), 
										   CFSTR("CatLikeTyping"), 
										   NULL, 
										   NULL, 
										   true);
	allowTyping = 0;
}

CGEventRef catnipEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	static int pressed[MAX_KEYCODE];
	
	static EventLoopTimerUPP  timerUPP;
	static EventLoopTimerRef  theTimer;

	// If there's a timer set to go off and we released a key, defuse it.
	if ((theTimer != nil) && (type == kCGEventKeyUp)) {
		OSStatus error; 
		error = RemoveEventLoopTimer(theTimer); 
    
		DisposeEventLoopTimerUPP(timerUPP); 
	
		theTimer = nil;
	}
		
	// Paranoid sanity check.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp))
        return event;
	
	// Compute the incoming keycode.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(
										event, kCGKeyboardEventKeycode);
	
	/* printf( "rect = (%d,%d) to (%d,%d)\n",
			keycaps[keycode].rect.left,
			keycaps[keycode].rect.top,
			keycaps[keycode].rect.right,
			keycaps[keycode].rect.bottom );
	*/
	
	// if we're not allowed to type
	if (allowTyping == 0) {
		// convert the keycode to a letter
		char letter = translateKey( keycode, type );

		// push it through the finite state automata
		if (type == kCGEventKeyDown)
			state = machineTransition( machine, state, letter );
			
		if (machineSuccess( machine, state )) {
			allowTyping = 1;
			CFNotificationCenterPostNotification (CFNotificationCenterGetLocalCenter(), 
												  CFSTR("HumanTyping"), 
												  NULL, 
												  NULL, 
												  true);
			state = machineInitialState( machine );
			return 0;
		}
	}
		
	// record which keys are pressed down
	if (keycode < MAX_KEYCODE) {
		if (type == kCGEventKeyDown) {
			pressed[keycode] = 1;
			// Microseconds( &(pressTime[keycode]) );
		}
		
		if (type == kCGEventKeyUp) {
			pressed[keycode] = 0;
		}
	}

	if (allowTyping) {
		// count how many keys are pressed down.
		int k;
		int pressedCount = 0;
		for( k=0; k<MAX_KEYCODE; k++ )
			pressedCount += pressed[k];
		
		// find neighboring pairs of pressed keys
		int i, j;
		
		for( i=0; i<MAX_KEYCODE; i++ )  {
			if (pressed[i]) {
				if (EmptyRect( &(keycaps[i]) )) continue;
				
				for( j=0; j<MAX_KEYCODE; j++ ) {
					if ((i != j) && (pressed[j])) {
						if (EmptyRect( &(keycaps[j]) )) continue;

						if (areTouching(i,j)) {
							
							// set off a timer---if something else doesn't happen soon,
							// it's probably a slow-moving, big-pawed cat
							
							EventLoopRef       mainLoop;
							
							if (theTimer == nil) {
								mainLoop = GetMainEventLoop();
								timerUPP = NewEventLoopTimerUPP(TimerAction);
							
								InstallEventLoopTimer (mainLoop,
													   millisecondsSensitivity * kEventDurationSecond/1000,
													   0,
													   timerUPP,
													   NULL,
													   &theTimer);
							}
						}
					}
				}
			}
		}
	}

	if ((allowTyping) || (type == kCGEventKeyUp))
		return event;
	// else
		return 0;
}

int main(int argc, char ** argv)
{
    CFMachPortRef eventPort;
    CFRunLoopSourceRef  eventSrc;
    CFRunLoopRef    runLoop;

    eventPort = CGEventTapCreate(kCGSessionEventTap,
								 kCGHeadInsertEventTap,
								 0,
								 ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp)),
								 catnipEventCallback,
								 NULL );
    if ( eventPort == NULL )
    {
        printf( "NULL event port\n" );
        exit( 1 );
    
	}

	// renounce root privilege
	setuid(getuid());
	
    eventSrc = CFMachPortCreateRunLoopSource(NULL, eventPort, 0);
    if ( eventSrc == NULL )
        printf( "No event run loop src?\n" );
	
    runLoop = CFRunLoopGetCurrent();
    if ( runLoop == NULL )
        printf( "No run loop?\n" );
	
	loadKeyboardLayout();
	loadPhysicalLayout();
	
	machine = machineOr( machineNondeterministicMatchString( "human" ), machineNondeterministicMatchString( "chimp" ) );
	state = machineInitialState( machine );
	
    CFRunLoopAddSource(runLoop,  eventSrc, kCFRunLoopDefaultMode);

    return NSApplicationMain(argc,  (const char **) argv);
}
