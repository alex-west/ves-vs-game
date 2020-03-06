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
	
	include "ves.h"
	; include "macros.h"

cartStart = $0800
cartSize = ($400 * 2) - 1 ; 1 kilobyte * 2

	org cartStart
	
header: db $55,"J"
cartEntry: jmp initGame

	include "gfx.asm"

initGame:

	; Test
; Clear screen
	dci CLEAR_SCREEN
	pi blitGraphic
	
	li $40
	lr blit.height,a
	lis 0
	lr blit.y, a
	;li %00001001
	li %10000010
	lr blit.color,a
	pi blitAttribute

	dci water_attr
	pi blitGraphic
	
; prep loop
.tempX = 0
.tempColor = 1

	lis 5
	lr .tempX, a
	lis 15
	lr .tempColor, a
	
.faceLoop:
	
	lr a, .tempX
	lr blit.x, a
	li 5
	lr blit.y, a
	li 5
	
	dci colors
	lr a, .tempColor
	lr blit.num, a
	adc
	lm
	lr blit.color, a
	
	pi blitNum
	
	li 4
	as .tempX
	lr .tempX, a

	ds .tempColor
	bc .faceLoop
	
	dci CHECKER_OVERLAY
	pi blitGraphic
	
	dci SMILE_A
	pi blitGraphic
	
	dci SMILE_B
	pi blitGraphic
	
end:
	jmp end

solid:
	db $FF
colors:
	db %01000000 >> 2
	db %10000000 >> 2
	db %11000000 >> 2
	db %01000000 >> 2
	db %01000000 >> 2
	db %01000000 >> 2
	db %10000000 >> 2
	db %10000000 >> 2
	db %10000000 >> 2
	db %11000000 >> 2
	db %11000000 >> 2
	db %11000000 >> 2
	db %01000000 >> 2
	db %01000000 >> 2
	db %01000000 >> 2
	db %10000000 >> 2

;11 red
;10 green
;01 blue
;00 bkg

; %0000 0001 ;bw
; %0000 1001 ;gray
; %1000 0001 ;blue
; %1000 1001 ;green
	
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
	
	
	org cartStart + cartSize - 24
	dc "Copyright 2020 Alex West", 0
; EoF