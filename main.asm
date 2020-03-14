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
; O Water animation
; O Read Inputs
; X Menu (Change time, stock, bridge lengths, etc)
; X Timer Decrement
; X Draw Stock (inc/dec)
; ~ Delay function
; X Write main loop
; X Complete the game

;-------------------------------------------------------------------------------
	processor f8

cartStart = $0800
cartSize = ($400 * 2) - 1 ; 1 kilobyte * 2

	org cartStart	
header:
	db $55,"J"
cartEntry:
	jmp initGame
;-------------------------------------------------------------------------------
; Includes

	include "ves.h"
	include "utils.h"
	; include "macros.h"
	include "gfx.asm"
	include "pics.asm"

;-------------------------------------------------------------------------------
; Global register and constant definitions

; Playfield bounds
X_CENTER = 54
LEFT_WALL = 7
RIGHT_WALL = X_CENTER*2-LEFT_WALL-1
CEILING = 13
BRIDGE_Y = 46
WATER_LEVEL = BRIDGE_Y + 11
WAVE_LEVEL = WATER_LEVEL-1

; Player 1
p1.xpos = 020 ; Q 7.1 (SR 1 before drawing)
p1.ypos = 021 ; Q 7.1
p1.xvel = 022 ; Q 3.5 (SR 4 and sign extend before adding to position)
p1.yvel = 023 ; Q 3.5
p1.char = 024 ; 
p1.stoc = 025
p1.brig = 026
p1.prev = 027

; Player 2
p2.xpos = 030 ; Q 7.1 (SR 1 before drawing)
p2.ypos = 031 ; Q 7.1
p2.xvel = 032 ; Q 3.5 (SR 4 and sign extend before adding to position)
p2.yvel = 033 ; Q 3.5
p2.char = 034 ; 
p2.stoc = 035
p2.brig = 036
p2.prev = 037

; Timers
timerMin = 064
timerSec = 065
timerFrame = 066
waveTimer = 067

; Storage for menu options
optionFlags = 074
optionTimer = 075  ;(MMMMSSSS)
optionStock = 076  ;(LLLLRRRR)
optionBridge = 077 ;(LLLLRRRR)

; Mode ideas (TODO)
; - cross center or not
; - bullets can respawn like contra's laser
; - speed

;-------------------------------------------------------------------------------
initGame:
; Clear BIOS stack pointer
	setisar 073
	clr
	lr (is),a
	
; Seed RNG from uninitialized ports (taken from Dodge It) TODO: Implement
	;setisar rng
	;ins 4
	;lr (is)-,a
	;ins 5
	;lr (is)+,a

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

	; Init memory
	
;-------------------------------------------------------------------------------
menu:

menuLoop:

	;Animate water
	; pi animateWaves
	
	; jmp menuLoop

;-------------------------------------------------------------------------------
initMatch:
	; Set score, position, etc.

	; TODO: Replace
	setisar p1.xpos
	li $40
	lr (is)+, a
	lr (is),a
	
	setisar p2.xpos
	li X_CENTER*2 + $20
	lr (is)+, a
	li $40
	lr (is),a
	
	; TODO have this be selectable in the menu
	setisar optionBridge
	li (13 << 4) | (11)
	lr (is), a
	
	; TODO have initial time be selectable in the menu
	setisar timerMin
	li $08
	lr (is)+,a
	li $32
	lr (is),a
	
	; Draw playfield
	
	pi drawPlayfield
	pi drawLeftBridge
	pi drawRightBridge
	
	pi drawTimer
	
	
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
	setisaru p1.xpos
	pi doPlayer
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
	setisaru p2.xpos
	pi doPlayer
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
	
	; Animate water
	pi animateWaves
	
	; delay loop
	li $10
	lr delay.count,a
	li $00
	pi delay
	
	jmp mainLoop
; end mainLoop()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; drawPlayfield(void)
;
; This function could be genericized by having .tempCount be an argument and
;  by storing playfield list in H as an arg as well

drawPlayfield: subroutine
	lr k,p

.tempCount = 0

	li playfield_list_len
	lr .tempCount, a
.drawLoop:
	; DC = playfield_list[num*2]
	dci playfield_list
	lr a, .tempCount
	sl 1
	adc
	lm
	lr Qu, a
	lm
	lr Ql, a
	lr dc, Q
	
	pi blitGraphic
	
	ds .tempCount
	bc .drawLoop
	
	lr p,k
	pop
; end of drawPlayfield()
;-------------------------------------------------------------------------------
	
;-------------------------------------------------------------------------------	
; Draw left bridge

drawLeftBridge: subroutine
	lr k,p
	
.tempCount = 0
	
	; Get left bridge length
	setisar optionBridge
	lr a,(is)
	sr 4
	lr .tempCount, a

	; set color, set x
	li RED_A | CLEAR_BG
	lr blit.color, a
	li X_CENTER-5
	lr blit.x,a
	
.loop:
	; reset char, reset y
	li CHR_BRIDGE_L
	lr blit.char, a
	li BRIDGE_Y
	lr blit.y,a
	
	pi blitNum
	
	; adjust x
	lr a, blit.x 
	ai <[-3]
	lr blit.x,a
	
	ds .tempCount
	bnz .loop

	lr p,k
	pop
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw right bridge

drawRightBridge: subroutine
	lr k,p

.tempCount = 0

	; Get right bridge length
	setisar optionBridge
	lr a,(is)
	ni %00001111
	lr .tempCount, a

	; set color, set x
	li BLUE_A | CLEAR_BG
	lr blit.color, a
	li X_CENTER+2
	lr blit.x,a
.loop:
	; reset char, reset y
	li CHR_BRIDGE_R
	lr blit.char, a
	li BRIDGE_Y
	lr blit.y,a
	pi blitNum
	
	; adjust x
	lr a, blit.x 
	ai 3
	lr blit.x,a
	
	ds .tempCount
	bnz .loop
	
	lr p,k
	pop
; end of drawPlayfield()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; drawTimer()

drawTimer: subroutine
	lr k,p
	
.TIMER_Y = CEILING-8
.tempCount = 0

	; set color
	li GREEN_A | BKG_B
	lr blit.color, a
	; set initial x
	li X_CENTER+6
	lr blit.x,a
	; prep for loop
	lis 1
	lr .tempCount, a
	
	setisar timerSec
	
.loop:
; Draw ones
	lr a,(is)
	ni $0F
	lr blit.char, a
	; Set y
	li .TIMER_Y
	lr blit.y, a
	pi blitNum
	; adjust x
	lr a, blit.x
	ai <[-4]
	lr blit.x, a
	
; Draw tens
	; get color
	lr a,(is)- ; adjust isar to point to minutes
	ni $F0
	sr 4
	lr blit.char, a
	; Reset y
	li .TIMER_Y
	lr blit.y, a
	pi blitNum
	; adjust x
	lr a, blit.x
	ai <[-7]
	lr blit.x, a

	ds .tempCount
	bc .loop
	
	lr p,k
	pop
; end of drawTimer()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; data for drawPlayfield()

; Lists of objects to draw
playfield_list_len = 9
playfield_list:
	dw playfield_attr
	dw colon
	dw score_left
	dw score_right
	dw score_line
	dw goal_left
	dw goal_right
	dw pylon
	dw water

; Attributes to draw
playfield_attr:
	db %00100000
	db $7d,0
	db 2,64
	dw PLAYFIELD_ATTR_PX
PLAYFIELD_ATTR_PX: ; 00 mono, 01 gray, 10 blue, 11 green
	db %11111111, %11010101, %01011100, %00111101
	db %11010111, %01010101, %01010101, %01010101
	db %01010101, %01010101, %01010101, %01011111
	db %11011001, %10100110, %10101010, %10101010

; Timer colon
COLON_PX:
	db %11001100
colon:
	db GREEN_A
	db X_CENTER-1,CEILING-7
	db 2,3
	dw COLON_PX
	
score_left:
	db RED_A|FILL
	db 0,0
	db X_CENTER-11,11
	dw SOLID

score_right:
	db BLUE_A|FILL
	db X_CENTER+11,0
	db X_CENTER-11-(2),11
	dw SOLID
	
score_line:
	db RED_A|FILL
	db 0,CEILING-2
	db $7c,1
	dw SOLID
	
goal_left:
	db RED_A | CLEAR_BG | FILL
	db LEFT_WALL,CEILING
	db 1,WATER_LEVEL-CEILING
	dw CHECKER
	
goal_right:
	db BLUE_A | CLEAR_BG | FILL
	db RIGHT_WALL,CEILING
	db 1,WATER_LEVEL-CEILING
	dw CHECKER
	
pylon:
	db GREEN_A | FILL
	db X_CENTER-3,BRIDGE_Y
	db 6,10
	dw SOLID
	
water:
	db BLUE_A|FILL
	db 0,WATER_LEVEL
	db $7c,8
	dw SOLID
; end of data for drawPlayfield()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; doPlayer()
;
; Rough draft. Trying to figure out how to do this

doPlayer: subroutine
	lr k,p
	
; -- Read and process inputs ----------
.xTemp = 0
.yTemp = 1
.curInput = 2
.edgeInput = 3

; if human, check inputs for the appropriate player
	lr a,is
	ni 070
	ci 020
	bnz .p2inputs
	pi readRightHand
	br .processInputs
.p2inputs:
	pi readLeftHand

.processInputs:
	;  Handle edge sensitivity and stuff
	; .cur = A (controller)
	lr .curInput, a
	; .edge = .temp XOR .prev
	setisarl p1.prev
	xs (is)
	lr .edgeInput, a
	; .prev = .cur
	lr a, .curInput
	lr (is), a
	
	; TODO LATER: if computer, produce AI inputs (how?)
	
; get temp position
	setisarl p1.xpos
	lr a, (is)+
	lr .xTemp, a
	lr a, (is)
	lr .yTemp, a

; Free Movement (TEMPORARY)
	li HAND_LEFT
	ns .curInput
	bz .checkRightInput
	lr a, .xTemp
	ai <[-2]
	lr .xTemp, a
.checkRightInput:
	li HAND_RIGHT
	ns .curInput
	bz .checkUpInput
	lr a, .xTemp
	ai 2
	lr .xTemp, a	
.checkUpInput:
	li HAND_UP
	ns .curInput
	bz .checkDownInput
	lr a, .yTemp
	ai <[-2]
	lr .yTemp, a
.checkDownInput:
	li HAND_DOWN
	ns .curInput
	bz .endCheckInput
	lr a, .yTemp
	ai 2
	lr .yTemp, a
.endCheckInput:
	
	; move x
	;  if .cur & HAND_LEFT
	;   xvel -= X_ACCEL (make sure not to overflow)
	;  if .cur & HAND_RIGHT
	;   xvel += X_ACCEL
	; .xtemp = xpos + xvel
	
	; move y ; maybe have a double jump
	;  if .edge & HAND_G_UP (maybe?)
	;   yvel = JUMP_Y_VEL
	;  yvel -= Y_GRAVITY
	; .ytemp = ypos + yvel
	
	; Collision detection (ejection)
	;  if newpos is inside the bridge, eject up and clear yvel
	;  if newpos is under the left bridge, eject left
	;  if newpos is under the right bridge, eject right
	;  if newpos is on the other side of the court
	;   and if the mode does not permit crossing that line, eject back into court
	;  if newpos in above the ceiling, eject down
	;  if newpos is left of the left goal, eject left
	;  if newpos is right of the right goal, eject right
	;  if newpos is in the water, let checkDeath handle it
	;
	; ^-- perhaps put that stuff in its own function with x,y,w,h args and
	;  returns for x,y,and water collisions (so it can be reused for bullets)
	
	; adjust angle
	;  if .cur & HAND_CCW
	;   angle--
	;  if .cur & HAND_CW
	;   angle++
	
	; spawn bullet
	;  if .edge & HAND_G_DOWN
	;   spawn bullet based on angle (if possible)
	
; Undraw from oldpos
	; Set color
	li BKG_A
	lr blit.color,a 
	
	; Get old position
	setisarl p1.xpos
	lr a, (is)+
	sr 1
	lr blit.x, a
	lr a, (is)
	sr 1
	lr blit.y, a
	
	; Get old character??? (or just clear of block?)
	setisarl p1.char
	lr a, (is)
	;ni $0F
	lr blit.char, a
	
	pi blitNum
	
; Set newpos
	setisarl p1.xpos
	lr a, .xTemp
	lr (is)+, a
	lr a, .yTemp
	lr (is), a
	
; Redraw at newpos
	; Set color
	lr a,is
	ni 070
	ci 020
	bnz .p2color
	li RED_A
	br .setColor
.p2color:
	li BLUE_A
.setColor:
	lr blit.color,a 
	
	; Get new position
	setisarl p1.xpos
	lr a, (is)+
	sr 1
	lr blit.x, a
	lr a, (is)
	sr 1
	lr blit.y, a
	
	; Get character
	setisarl p1.char
	lr a, (is)
	;ni $0F
	lr blit.char, a
	
	pi blitNum
	
	lr p,k
	pop
; end doPlayer()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; readLeftHand()
;  reads the left hand-controller
readLeftHand: subroutine
	clr
	outs 0
	outs 4
	ins 4
	com
	pop
;
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; readRightHand()
readRightHand: subroutine
	clr
	outs 0
	outs 1
	ins 1
	com
	pop
;
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; readConsole()
readConsole:
	clr
	outs 0
	ins 0
	com
	pop
;
;-------------------------------------------------------------------------------
	
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
	
; args
; A - lower part of delay
delay.count = 0

delay: subroutine

.loop:
	inc
	bnz .loop
	
	ds delay.count
	lis 0
	bnz .loop
	
	pop
; end of delay()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; animateWaves()
;
; animates some nices waves
;
;0__________12         36____________48

;WAVE_LEVEL
;waveTimer

WAVE_LEN = 16
WAVE_GAP = 16
WAVE_SPEED = 1
NUM_WAVES = 4

animateWaves: subroutine
	lr k,p

.loopCount = 0
.tempX = 1
	
	lis NUM_WAVES
	lr .loopCount, a
	
	dci SOLID
	lis 1
	lr blit.width, a
	
	setisar waveTimer
	lr a, (IS)
	lr .tempX, a
	
	;br .part2

.loop:
; undraw
	; set color, y, and h
	li BKG_A | FILL
	lr blit.color, a
	li WAVE_LEVEL
	lr blit.y, a
	lis 1
	lr blit.height, a
	
	lr a,.tempX
	ni $7f
	ci $7c
	bnc .next1
	lr blit.x, a
	
	pi blit
	
.next1: ;adjust .tempX
	lr a, .tempX
	ai WAVE_LEN
	lr .tempX, a
	
; draw
	; set color, y, and h
	li BLUE_A | FILL
	lr blit.color, a
	li WAVE_LEVEL
	lr blit.y, a
	lis 1
	lr blit.height, a

	lr a,.tempX
	ni $7f
	ci $7c
	bnc .next2
	lr blit.x, a

	pi blit
	
.next2: ;adjust .tempX
	lr a, .tempX
	ai WAVE_GAP
	lr .tempX, a
	
	ds .loopCount
	bnz .loop
	
; Do the opposite direction
.part2:
	lis NUM_WAVES
	lr .loopCount, a
	; reload timer
	setisar waveTimer
	lr a, (IS)
	sr 1
	lr .tempX, a

.loop2:
; undraw
	; set color, y, and h
	li BKG_A | FILL
	lr blit.color, a
	li WAVE_LEVEL
	lr blit.y, a
	lis 1
	lr blit.height, a
	
	lr a,.tempX
	ni $7f
	ci $7c
	bnc .next3
	lr blit.x, a
	
	pi blit
	
.next3: ;adjust .tempX
	lr a, .tempX
	ai <[WAVE_LEN]
	lr .tempX, a
	
; undraw
	; set color, y, and h
	li BLUE_A | FILL
	lr blit.color, a
	li WAVE_LEVEL
	lr blit.y, a
	lis 1
	lr blit.height, a

	lr a,.tempX
	ni $7f
	ci $7c
	bnc .next4
	lr blit.x, a

	pi blit
	
.next4: ;adjust .tempX
	lr a, .tempX
	ai <[WAVE_GAP]
	lr .tempX, a
	
	ds .loopCount
	bnz .loop2
	
.temp = 0
	; inc waveTimer
	setisar waveTimer
	lis WAVE_SPEED
	as (IS)
	lr .temp, a
	ni $7
	lr a, .temp
	bnz .setTimer
	ai 4
.setTimer:	
	lr (IS), a
	
	
	lr p,k
	pop
; end of animateWaves()
;-------------------------------------------------------------------------------

	org cartStart + cartSize - 24
	
	dc "Copyright 2020 Alex West", 0
	
; EoF