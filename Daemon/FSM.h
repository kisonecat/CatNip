/*
 *  FSM.h
 *  Catnip
 *
 *  Created by Jim Fowler on 12/11/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

typedef struct tagFSM
{
	int marking;
	int id;
	struct tagFSM* transitions[256];
	struct tagFSM* next;
	struct tagFSM* notepad[2];
} FSM;

typedef FSM FSM_STATE;

FSM* machineMatchString( char* string );
FSM* machineOr( FSM* fsm1, FSM* fsm2 );

FSM_STATE* machineInitialState( FSM* fsm );
FSM_STATE* machineTransition( FSM* fsm, FSM_STATE* state, char ch );

int machineSuccess( FSM* fsm, FSM_STATE* state );

