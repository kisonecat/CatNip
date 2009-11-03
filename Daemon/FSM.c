/*
 *  FSM.c
 *  Catnip
 *
 *  Created by Jim Fowler on 12/11/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include "FSM.h"

#define UNMARKED 0
#define MARKED 1

static int guid = 0;

FSM_STATE* machineAddState( FSM* fsm )
{
	FSM_STATE* state = malloc( sizeof(FSM_STATE) );
	state->id = guid++;

	state->marking = UNMARKED;
	
	int i;
	for( i=0; i<256; i++ )
		state->transitions[i] = fsm;
	
	state->next = fsm->next;
	fsm->next = state;
		
	return state;
}

FSM* machineNew( void )
{
	FSM* fsm = malloc( sizeof(FSM) );
	fsm->id = guid++;
	
	fsm->marking = UNMARKED;
	
	int i;
	for( i=0; i<256; i++ )
		fsm->transitions[i] = fsm;
	
	fsm->next = NULL;
	
	return fsm;
}

FSM* machineMatchString( char* string )
{
	FSM* fsm = machineNew();
	FSM_STATE* state = machineInitialState( fsm );
	
	while( *string != 0 ) {
		state = state->transitions[*string] = machineAddState( fsm );
		string++;
	}

	state->marking = MARKED;
	
	return fsm;
}

FSM* machineNondeterministicMatchString( char* string )
{
	FSM* fsm = machineNew();
	
	FSM_STATE** states = alloca( sizeof(FSM_STATE*) * (strlen(string) + 1) );
	
	states[0] = machineInitialState( fsm );

	int i, j, k;
	
	for( i=0; i<strlen(string); i++ ) {
		states[i+1] = states[i]->transitions[string[i]] = machineAddState( fsm );
		
		for( j=0; j<255; j++ ) {
			for( k=0; k<i; k++ ) {
				if ((states[k]->transitions[j] != states[0]) && (states[i]->transitions[j] != states[i+1]))
					states[i]->transitions[j] = states[k]->transitions[j];
			}
		}
	}

	states[strlen(string)]->marking = MARKED;
	
	return fsm;
}

FSM* machineConcatenate( FSM* fsm1, FSM* fsm2 )
{
	FSM_STATE* state1 = machineInitialState( fsm1 );

	while( state1 != NULL ) {
		int i;
		for( i=0; i<256; i++ ) {
			if (state1->transitions[i]->marking == MARKED)
				state1->transitions[i] = machineInitialState( fsm2 );
		}
		
		state1 = state1->next;
	}
	
	return fsm1;
}

FSM* machineOr( FSM* fsm1, FSM* fsm2 )
{
	FSM* fsm = NULL;
	FSM_STATE* state = NULL;

	FSM_STATE* state1 = machineInitialState( fsm1 );
	while( state1 != NULL ) {

		FSM_STATE* state2 = machineInitialState( fsm2 );
		while( state2 != NULL ) {
			
			if (state == NULL) {
				fsm = machineNew();
				state = machineInitialState( fsm );
			} else {
				state = machineAddState( fsm );
			}
			
			state->notepad[0] = state1;
			state->notepad[1] = state2;
			
			if ((state1->marking == MARKED) || (state2->marking == MARKED))
				state->marking = MARKED;
				
			state2 = state2->next;
		}
		state1 = state1->next;
	}
	
	state = machineInitialState( fsm );
	
	while( state != NULL ) {
		int i;
		for( i=0; i<256; i++ ) {
			FSM_STATE* search = machineInitialState( fsm );
			
			while( search != NULL ) {
				if ((search->notepad[0] == state->notepad[0]->transitions[i]) && 
					(search->notepad[1] == state->notepad[1]->transitions[i])) {
					state->transitions[i] = search;
					break;
				}
				
				search = search->next;
			}
		}
			
		state = state->next;
	}
			
	return fsm;
}

FSM_STATE* machineTransition( FSM* fsm, FSM_STATE* state, char ch )
{
	FSM* result = state->transitions[ch];
	
	if (result == NULL) {
		printf( "null state.\n" );
		exit(0);
	}

	return result;
}

int machineSuccess( FSM* fsm, FSM_STATE* state )
{
	if (state->marking == MARKED)
		return 1;
	
	return 0;
}

FSM_STATE* machineInitialState( FSM* fsm )
{
	return fsm;
}
