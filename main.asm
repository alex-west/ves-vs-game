;-------------------------------------------------------------------------------
; Sumo Dodge Ball Game (working title)
;  for the Channel F
; Created by Alex West
;
; Build Instructions
;  dasm main.asm -f3 -oballgame.bin

; Milestones
; - Project Started: August 16, 2019
; - First Playable Build: ???
; - First Release Candidate: ???
; - Released: ???

; TODO LIST
; - Write draw function
; - Write main loop
; - Complete the game

	processor f8
	
	; include "ves.h"
	; include "macros.h"

cartStart = $0800
cartSize = ($400 * 2) - 1 ; 1 kilobyte * 2

	org cartStart
	
header: db $55,"J"
cartEntry: jmp initGame

initGame:
	; Init memory
	
	; Menu

initMatch:
	; Set score, position, etc.
	; Draw playfield
	
	
	; Main loop
mainLoop:
	
	; process bullets
	;  check if bullet exists
	;  check floor and ceiling collision
	;  check player collision
	;   if so, set player hit flag
	;  check if bullet has gone off the side of the screen
	;   if so, shorten the plank
	
	; process left player
	;  if human, check inputs
	;  if computer, produce AI inputs (how?)
	;  react to inputs
	;   move left or right
	;   jump (double jump) - make sure this input is edge sensitive
	;   shooting
	;    check if bullet can be spawned
	;    check angle
	;    spawn bullet
	;  draw player
	;  if fallen in water, set P1 lose flag
	
	; process right player	
	;  same as above
	
	; if p1 & p2 both lost
	;  display "TIE"
	; if p1 lost
	;  display p2 wins
	; if p2 lost
	;  display p1 wins
	; if neither lost, continue
	
	; decrement timer
	; if timer is out
	;  display TIME OUT
	; else, continue
	
	; delay loop
	
	jmp mainLoop
; end main loop

	
;redraw
	; object processing functions should return new x, new y, and new char
	; a redraw flag should be bitpacked in there imo
	; undraw using old x, old y, and old char
	; check if redraw flag is set
	; redraw at new x, new y, new char
	; old x,y,char get assigned new x,y,char
	
; delay loop
	; delay_time = time_const - CPU_counter
	; make sure we don't underflow
	; delay
	; clear CPU_counter
	
	; CPU_counter should increase by 1 for ever plotted pixel, maybe other things
	
	
	org cartStart + cartSize - 25
	dc "Copyright 2020 Alex West", 0
; EoF