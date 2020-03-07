;-------------------------------------------------------------------------------
; Sumo Dodge Ball Game (working title)
;  for the Channel F
; Created by Alex West
;
; Build Instructions
;  dasm main.asm -f3 -oballgame.bin

; Milestones
; - Project Started: 				2019-08-16
; - Project Started in Earnest:		2020-03-01
; - First Playable Build: ???
; - First Release Candidate: ???
; - Released: ???

; TODO LIST
; O Write draw function
; X Write main loop
; X Complete the game

	processor f8
	
	include "ves.h"
	; include "macros.h"

cartStart = $0800
cartSize = ($400 * 2) - 1 ; 1 kilobyte * 2

	org cartStart
	
header: db $55,"J"
cartEntry: jmp initGame

	include "gfx.asm"
	include "pics.asm"

initGame:
	; Clear BIOS stack pointer
	setisar 073
	clr
	lr (is),a
	
	; Seed RNG from uninitialized ports (taken from Dodge It)
	;setisar rng
	;ins 4
	;lr (is)-,a
	;ins 5
	;lr (is)+,a

	; Test
; Clear screen
	dci CLEAR_SCREEN
	pi blitGraphic
	; Clear attributes
	li $40
	lr blit.height,a
	lis 0
	lr blit.y, a
	li BG_GRAY
	lr blit.color,a
	pi blitAttribute

	pi drawPlayfield
	
	jmp end
;	dci water_attr
;	pi playfield_attr
	
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
	lr blit.char, a
	adc
	lm
	lr blit.color, a
	
	pi blitNum
	
	li 4
	as .tempX
	lr .tempX, a

	ds .tempColor
	bc .faceLoop

	jmp end
	
	dci CHECKER_OVERLAY
	pi blitGraphic
	
	dci SMILE_A
	pi blitGraphic
	
	dci SMILE_B
	pi blitGraphic

; Flag
	dci FLAG_BG
	pi blitGraphic
	dci FLAG_B
	pi blitGraphic
	dci FLAG_G
	pi blitGraphic
	dci FLAG_R
	pi blitGraphic
	dci FLAG_ATTR_GRAY
	pi blitGraphic
	dci FLAG_ATTR_BLUE
	pi blitGraphic
	dci FLAG_ATTR_GREEN
	pi blitGraphic
	dci FLAG_ATTR_BW
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
;-------------------------------------------------------------------------------

; drawPlayfield
drawPlayfield: subroutine
	lr k,p
	; Draw attributes
	dci playfield_attr
	pi blitGraphic
	; Draw score bgs
	dci score_left
	pi blitGraphic
	dci score_right
	pi blitGraphic
	dci score_line
	pi blitGraphic
	; Draw goal lines
	dci goal_left
	pi blitGraphic
	dci goal_right
	pi blitGraphic
	
	; Draw pylon
	dci pylon_b
	pi blitGraphic
	
	; Draw water
	dci water
	pi blitGraphic
	
	
	
; Draw left bridge (TODO: Make self-contained function)
.BRIDGE_Y = 46
.BRIDGE_LEN = 13
.tempCount = 0

	li RED_A | CLEAR_BG
	lr blit.color, a
	li .scrn_center-5
	lr blit.x,a
	; Get left bridge length (TODO: Make variable)
	li .BRIDGE_LEN
	lr .tempCount, a
.leftBridgeLoop:
	li CHR_BRIDGE_L
	lr blit.char, a
	li .BRIDGE_Y
	lr blit.y,a
	pi blitNum
	
	lr a, blit.x 
	ai <[-3]
	lr blit.x,a
	
	ds .tempCount
	bnz .leftBridgeLoop

; Draw right bridge (TODO: Make self-contained function)
	li BLUE_A | CLEAR_BG
	lr blit.color, a
	li .scrn_center+2
	lr blit.x,a
	; Get right bridge length (TODO: Make variable)
	li .BRIDGE_LEN
	lr .tempCount, a
.rightBridgeLoop:
	li CHR_BRIDGE_R
	lr blit.char, a
	li .BRIDGE_Y
	lr blit.y,a
	pi blitNum
	
	lr a, blit.x 
	ai 3
	lr blit.x,a
	
	ds .tempCount
	bnz .rightBridgeLoop
	
;blit.x
;blit.y
;blit.char = 5
	
	
	lr p,k
	pop

; end of drawPlayfield()
;-----

;BG_MONO  = %10000000 ;00 mono
;BG_GRAY  = %10000010 ;01 gray
;BG_BLUE  = %10100000 ;10 blue
;BG_GREEN = %10100010 ;11 green

playfield_attr:
	db %00100000
	db $7d,0
	db 2,64
	dw PLAYFIELD_ATTR_PX
PLAYFIELD_ATTR_PX:
	db %11111111, %11010101, %01011100
	db %00111101, %11010111
	db %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
	db %01011111, %11011001
	db %10100110, %10101010, %10101010

.scrn_center = 54
	
score_left:
	db RED_A|FILL
	db 0,0
	db .scrn_center-11,11
	dw SOLID

score_right:
	db BLUE_A|FILL
	db .scrn_center+11,0
	db .scrn_center-11-(2),11
	dw SOLID
	
score_line:
	db RED_A|FILL
	db 0,11
	db $7c,1
	dw SOLID
	
goal_left:
	db RED_A | CLEAR_BG | FILL
	db .scrn_center-.scrn_center+7,11+2
	db 1,44
	dw CHECKER
	
goal_right:
	db BLUE_A | CLEAR_BG | FILL
	db .scrn_center+.scrn_center-8,11+2
	db 1,44
	dw CHECKER

PYLON_PX:
	db %11111111
	db %11111111
	db %11111111
	db %11111111
	db %11111111
	db %01111111
	db %10001111
	db %11000011
	db %11110000
	db %11111100
	db %00011110
	db %00000111
	db %10000001
	db %11100000
	db %00110000
	db %00001100
	db %00000011
	db %00000000
	
pylon:
	db GREEN_A | BKG_B
	db .scrn_center-5,.BRIDGE_Y
	db 10,14
	dw PYLON_PX
	
pylon_b:
	db GREEN_A | FILL
	db .scrn_center-3,.BRIDGE_Y
	db 6,10
	dw SOLID
	
water:
	db BLUE_A|FILL
	db 0,.BRIDGE_Y+11
	db $7c,8
	dw SOLID
	
;-------------------------------------------------------------------------------
;redraw
	; object processing functions should return new x, new y, and new char
	; a redraw flag should be bitpacked in there imo
	; undraw using old x, old y, and old char
	; check if redraw flag is set
	; redraw at new x, new y, new char
	; old x,y,char get assigned new x,y,char

;-------------------------------------------------------------------------------
; delay loop
	; delay_time = time_const - CPU_counter
	; make sure we don't underflow
	; delay
	; clear CPU_counter
	
	; CPU_counter should increase by 1 for ever plotted pixel, maybe other things
	
	
	org cartStart + cartSize - 24
	dc "Copyright 2020 Alex West", 0
; EoF