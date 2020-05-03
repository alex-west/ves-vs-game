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
; - Playfield Collision Working:	2020-03-14
; - First Playable Build: ???
; - First Release Candidate: ???
; - Released: ???

; TODO LIST
; O Write draw function
; O Water animation
; O Read Inputs
; ~ Playfield collision
; X Player physics
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
; Global register and constant definitions {

; Playfield bounds
X_CENTER = 54
LEFT_WALL = 6
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
p1.stat = 025 ; use this for some flags
GROUND_FLAG = %00010000
p1.brig = 026 ; Q 7.1
p1.prev = 027

; Player 2
p2.xpos = 030 ; Q 7.1 (SR 1 before drawing)
p2.ypos = 031 ; Q 7.1
p2.xvel = 032 ; Q 3.5 (SR 4 and sign extend before adding to position)
p2.yvel = 033 ; Q 3.5
p2.char = 034 ; 
p2.stat = 035
p2.brig = 036 ; Q 7.1
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
; - VVVVVV jumps
; - tug o war with bridge
; - bouncy water (lava?)
; - big bullets

; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
initGame: ; {
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

; }	----------------------------------------------------------------------------
menu:; {
menuLoop:

	;Animate water
	; pi animateWaves
	
	; jmp menuLoop
; } ----------------------------------------------------------------------------
initMatch: ; {
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
	li (12 << 4) | (12)
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
	
; } ----------------------------------------------------------------------------
mainLoop: ; {
	
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
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; drawPlayfield(void) {
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
; } ----------------------------------------------------------------------------
	
;-------------------------------------------------------------------------------	
; Draw left bridge {

drawLeftBridge: subroutine
	lr k,p
	
.tempCount = 0
.tempPx = 1
	
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
	
	; set tempPx (Q 7.1)
	li X_CENTER*2-4
	lr .tempPx, a
	
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
	
	; adjust .tempPx
	lr a, .tempPx
	ai <[-6]
	lr .tempPx, a
	
	ds .tempCount
	bnz .loop
	
	setisar p1.brig
	lr a, .tempPx
	lr (is), a
	
	lr p,k
	pop
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Draw right bridge {

drawRightBridge: subroutine
	lr k,p

.tempCount = 0
.tempPx = 1

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
	
	; set tempPx (Q 7.1)
	li X_CENTER*2 + 4
	lr .tempPx, a
	
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
	
	; adjust .tempPx
	lr a, .tempPx
	ai 6
	lr .tempPx, a
	
	ds .tempCount
	bnz .loop
	
	setisar p2.brig
	lr a, .tempPx
	lr (is), a
	
	lr p,k
	pop
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; drawTimer() {

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

; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; data for drawPlayfield() {

; Lists of objects to draw
playfield_list_len = 9
playfield_list: ; Rendered in reverse order
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
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; doPlayer() {
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
	
; Handle x movement
X_ACCEL = $04
X_MAX = $30

	setisarl p1.xvel
	; if .curInput & HAND_LEFT
	lr a, .curInput
	ni HAND_LEFT
	bz .accelRight
	; xvel -= X_ACCEL (make sure not to overflow)
	li <[-X_ACCEL]
	; make sure we don't overflow
	as (is)
	bp .applyAccelLeft
	ci <[-X_MAX]
	bm .applyAccelLeft
	li <[-X_MAX]
.applyAccelLeft:
	lr (is), a

.accelRight:
	;  if .cur & HAND_RIGHT
	lr a, .curInput
	ni HAND_RIGHT
	bz .applyDrag
	;   xvel += X_ACCEL
	li X_ACCEL
	; make sure we don't overflow
	as (is)
	bm .applyAccelRight
	ci <[X_MAX]
	bp .applyAccelRight
	li <[X_MAX]
.applyAccelRight:
	lr (is), a
	br .applyVel
	
; apply drag to vel
.DRAG = 2
.applyDrag: ;
	lr a, (is)
	;ai 0
	ci 8
	bz .applyVel
	bm .antiRightDrag
	ai .DRAG
	lr (is), a
	br .applyVel
.antiRightDrag:
	ai <[-.DRAG]
	lr (is), a

	; .xtemp = xpos + xvel
.applyVel
	lr a, (is)
	ai 0
	bp .noSignExt
	sr 4
	oi $F0
	br .applyVelB
.noSignExt:
	sr 4
.applyVelB
	as .xTemp
	lr .xTemp, a
	
; move y
JUMP_Y_VEL = <[-$50]
GRAVITY = $04
Y_DOWN_MAX = $70
	; TODO: maybe have a double jump
	;  if .edge & HAND_G_UP (maybe?)
	lr a, .curInput
	ni HAND_UP
	bz .applyGravity
	; if on ground
	setisarl p1.stat
	lr a, (is)
	ni GROUND_FLAG
	bz .applyGravity
	; Initiate jump	
	;   yvel = JUMP_Y_VEL
	setisarl p1.yvel
	li JUMP_Y_VEL
	lr (is), a
.applyGravity:
	setisarl p1.yvel
	;  yvel += Y_GRAVITY
	li GRAVITY
	; make sure we don't overflow
	as (is)
	bm .applyGravity2
	ci <[Y_DOWN_MAX]
	bp .applyGravity2
	li <[Y_DOWN_MAX]
.applyGravity2:
	lr (is), a
	;br .applyVel
	
	; .ytemp = ypos + yvel
.applyYVel:
	lr a, (is)
	ai 0
	bp .noYSignExt
	sr 4
	oi $F0
	br .applyYVel2
.noYSignExt:
	sr 4
.applyYVel2:
	as .yTemp
	lr .yTemp, a

	; Collision detection (ejection)
	lis 6
	lr collision.width, a
	li 10
	lr collision.height, a
	pi collision
	; TODO: Use collision's return flags to set velocity, handle death, and set
	;  the player's ground flag
; zero xvel if xbonk is set 
	lr a, collision.flags
	ni XBONK_FLAG
	bz .testYbonk
	setisarl p1.xvel
	clr
	lr (is), a
.testYbonk:
	; zero yvel if ybonk is set 
	setisarl p1.stat
	lr a, (is)
	ni <[~GROUND_FLAG]
	lr (is), a
	lr a, collision.flags
	ni YBONK_FLAG ; or with CEILING_FLAG ?
	bz .testWater
	; Set ground flag if appropriate
	lr a, (is)
	oi GROUND_FLAG
	lr (is), a
	; Clear velocity ; TODO: Fix glitch that allows you to hold to the ceiling
	setisarl p1.yvel
	clr
	lr (is), a
.testWater:
	
	; pray for death if water is set (TODO)
	
	; adjust angle
	;  if .cur & HAND_CCW
	;   angle--
	;  if .cur & HAND_CW
	;   angle++
	
	; spawn bullet
	;  if .edge & HAND_G_DOWN
	;   spawn bullet based on angle (if possible)
	
; Undraw from oldpos {
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
	
	; Get old character??? (or just aclear block?)
	setisarl p1.char
	lr a, (is)
	;ni $0F
	lr blit.char, a
	
	pi blitNum
; }
	
; Set newpos
	setisarl p1.xpos
	lr a, .xTemp
	lr (is)+, a
	lr a, .yTemp
	lr (is), a
	
; Redraw at newpos {
	; Set color
	lr a,is
	ni 070
	ci 020
	bnz .p2color
	li RED_A | CLEAR_BG
	br .setColor
.p2color:
	li BLUE_A | CLEAR_BG
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
 ; }
	
	lr p,k
	pop 
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; collision() {
;  Given x and y positions (in r0 and r1) and width and height (in r4 and r5)
;   ejects the player back into the playfield.
;
; TODO: Set return flags (xbonk, ybonk, ground, death)

collision: subroutine

; == args
collision.x = 0
collision.y = 1
collision.width = 4
collision.height = 5
; Abbreviated versions
.x = collision.x
.y = collision.y
.width = collision.width
.height = collision.height

; Returns
collision.flags = 6
.flags = collision.flags
CEILING_FLAG = %1000
WATER_FLAG   = %0100
YBONK_FLAG   = %0010
XBONK_FLAG   = %0001

; Temps
.tempIS = 7
.tempLBridge = 8
.tempRBridge = 9

; Constants
.BRIDGE_Y = BRIDGE_Y*2
.X_CENTER = X_CENTER*2

.LEFT_WALL = LEFT_WALL*2 + 2
.RIGHT_WALL = RIGHT_WALL*2
.CEILING = CEILING*2
.WATER_LEVEL = WATER_LEVEL*2

	; Save ISAR
	lr a, is
	lr .tempIS, a
	; Load bridge temps
	setisar p1.brig
	lr a, (is)
	lr .tempLBridge, a
	setisaru p2.brig
	lr a, (is)
	lr .tempRBridge, a
	; Clear return value
	clr
	lr .flags, a

	; Collision detection (ejection)
; Bridge collision
	;  if newpos is inside the bridge, eject up set ybonk flag
	;  if newpos is under the left bridge, eject left and set xbonk flag
	;  if newpos is under the right bridge, eject right and set xbonk flag
	;  if newpos is in the water, set death flag
	
	; .BRIDGE_Y - (.y+.height)
	lr a, .y
	as .height
	ci .BRIDGE_Y
	; if(.BRIDGE_Y > (.y+.height)) we're not in the bridge
	bc .testLeft
	; if this is true we should be in vertical range of the bridge
	ci .BRIDGE_Y+6
	bc .testBridge
	
; else, we are below the bridge (but not necessarily underneath)
	; .tempLBridge - (.x+.width)
	lr a, .x
	as .width
	com
	inc
	as .tempLBridge	
	; if(.tempLBridge > (.x+.width)) don't eject
	bc .testLeft
	
	; .tempRBridge - .x
	lr a, .x
	com
	inc
	as .tempRBridge
	; if(.tempRBridge >= .x), don't eject
	bnc .testLeft
	bz .testLeft
	
; We are underneath the bridge, so eject one way or another
	; set xbonk flag
	lr a, .flags
	oi XBONK_FLAG
	lr .flags, a
	
	; .X_CENTER - .x
	lr a, .x
	ci .X_CENTER
	; if(.X_CENTER >= .x), eject to the right
	bnc .ejectL	
	
	; else eject to the left
	lr a, .width
	com
	inc
	as .tempLBridge
	lr .x, a
	br .testLeft
	
.ejectL:
	lr a, .tempRBridge
	;inc
	;inc
	lr .x, a
	br .testLeft
	
; test if we are within the bridge on the x axis
.testBridge:
	
	; .tempLBridge - (.x+.width)
	lr a, .x
	as .width
	com
	inc
	as .tempLBridge	
	; if(.tempLBridge > (.x+.width)) don't eject
	bc .testLeft
	
	; .tempRBridge - .x
	lr a, .x
	com
	inc
	as .tempRBridge
	; if(.tempRBridge >= .x), don't eject
	bnc .testLeft

; We are inside the bridge, so eject up and set ybonk flag
	lr a, .height
	com
	inc
	ai .BRIDGE_Y
	lr .y, a
	; set ybonk flag
	lr a, .flags
	oi YBONK_FLAG
	lr .flags, a
	
; Bounds collision	
	
	; TODO: 
	;  if newpos is on the other side of the court
	;   and if the mode does not permit crossing that line, eject back into court

;  if newpos is left of the left goal, clamp to left goal, set xbonk flag
.testLeft:
	; .LEFT_WALL - .x
	lr a, .x
	ci .LEFT_WALL
	; if(.LEFT_WALL >= .x), don't eject
	bnc .testRight
	bz .testRight
	; eject
	li .LEFT_WALL
	lr .x, a
	; set xbonk flag
	lr a, .flags
	oi XBONK_FLAG
	lr .flags, a
	
	;  if newpos is right of the right goal, clamp to right goal, set xbonk flag
.testRight:
	; .RIGHT_WALL - (.x+.width)
	lr a, .x
	as .width
	ci .RIGHT_WALL
	; if(.RIGHT_WALL > (.x+.width)) don't eject
	bc .testCeiling
	; eject
	lr a, .width
	com
	inc
	ai .RIGHT_WALL
	lr .x, a
	; set xbonk flag
	lr a, .flags
	oi XBONK_FLAG
	lr .flags, a
	
	;  if newpos in above the ceiling, clamp to ceiling, set ybonk flag
.testCeiling:
	; .CEILING - .x
	lr a, .y
	ci .CEILING
	; if(.CEILING >= .y), don't eject
	bnc .testWater
	bz .testWater
	; eject
	li .CEILING
	lr .y, a
	; set ybonk flag
	lr a, .flags
	oi CEILING_FLAG ; TODO: change this to ceiling flag
	lr .flags, a
	
.testWater:
	;  if newpos is in the water, set death flag
	; .WATER_LEVEL - (.y+.height)
	lr a, .y
	as .height
	ci .WATER_LEVEL
	; if(.WATER_LEVEL > (.y+.height)) don't eject
	bc .exit
	; eject
	lr a, .height
	com
	inc
	ai .WATER_LEVEL
	lr .y, a
	; set water (death) flag
	lr a, .flags
	oi WATER_FLAG
	lr .flags, a

.exit:
	; reload IS
	lr a, .tempIS
	lr IS, a
	pop
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; readLeftHand() {
;  reads the left hand-controller
readLeftHand: subroutine
	clr
	outs 0
	outs 4
	ins 4
	com
	pop
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; readRightHand() {
readRightHand: subroutine
	clr
	outs 0
	outs 1
	ins 1
	com
	pop
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; readConsole() {
readConsole:
	clr
	outs 0
	ins 0
	com
	pop
; } ----------------------------------------------------------------------------
	
;-------------------------------------------------------------------------------
;redraw notes {
	; object processing functions should return new x, new y, and new char
	; a redraw flag should be bitpacked in there imo
	; undraw using old x, old y, and old char
	; check if redraw flag is set
	; redraw at new x, new y, new char
	; old x,y,char get assigned new x,y,char
; }

;-------------------------------------------------------------------------------
; delay loop {
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
; } ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; animateWaves() {
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
; } ----------------------------------------------------------------------------

endOfData:
	org cartStart + cartSize - 26
	dc "Copyright 2020 Alex West", 0
	dw endOfData
	
; EoF