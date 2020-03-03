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
;	li $C6 ; clear screen to grey
;	lr	$3, A
;	pi	BIOS_CLEAR_SCREEN
	
.tempX = 0
.tempColor = 1
	
	lis 0
	lr blit.x, a
	lr blit.y, a
	li $80
	lr blit.width, a
	li $40
	lr blit.height, a
	li %11000001
	lr blit.color, a
	dci solid
	pi blit	
	
	lis 5
	lr .tempX, a
	lis 11
	lr .tempColor, a
	
.faceLoop:
	dci colors
	lr a, .tempColor
	;sl 1
	adc
	lm
	lr blit.color, a
	
	lr a, .tempX
	lr blit.x, a
	li 5
	lr blit.y, a
	li 5
	lr blit.width, a
	lr blit.height, a
	dci SMILE
	pi blit
	
	li 6
	as .tempX
	lr .tempX, a

	ds .tempColor
	bc .faceLoop
	
end:
	jmp end

solid:
	db $FF
colors:
	db %00000100
	db %00001000
	db %00001100
	db %01000000
	db %01001000
	db %01001100
	db %10000000
	db %10000100
	db %10001100
	db %11000000
	db %11000100
	db %11001000

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