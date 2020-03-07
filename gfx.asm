;-------------------------------------------------------------------------------
; gfx.asm

; Color bitfields
; Color A
BKG_A   = %00 << 4
BLUE_A  = %01 << 4
RED_A   = %10 << 4
GREEN_A = %11 << 4
; Color B
BKG_B   = %00
BLUE_B  = %01
RED_B   = %10
GREEN_B = %11
; Row attributes for blitAttribute
BG_MONO  = %10000000 ;00 mono
BG_GRAY  = %10000010 ;01 gray
BG_BLUE  = %10100000 ;10 blue
BG_GREEN = %10100010 ;11 green

;-------------------------------------------------------------------------------
; blit(color, x, y, w, h, *gfx)
;
; This function blits a graphic based on parameters set in r2-r6,
; and the graphic data pointed to by DC0, onto the screen
; 
; Code taken and adapted from VESwiki, which took the code from videocart 26
;
; modifies: r2-r9, DC

; == Args
blit.color = 2 ; Holds 5 bitfields (FCAA-tbb)
blit.x = 3
blit.y = 4
blit.width = 5
blit.height = 6 ; and vertical counter
; DC = pointer to graphics

; Bitfields of blit.color
FILL     = %10000000
CLEAR_FG = %01000000
COLOR_FG = %00110000
CLEAR_BG = %00000100
COLOR_BG = %00000011

; == Entry
blit: subroutine

.hCount = 7
.pxData = 8
.bitCount = 9

	; load 1 into .bitCount so it'll be reset when we start
	lis	1
	lr	.bitCount, A
	; Load y and invert
	lr A, blit.y
	com

.doRow:
	; I/O write ypos
	outs 5

	; check vertical counter, exit if it rolls over
	ds	blit.height
	bnc	.exit

	; load the width into the horizontal counter
	lr	A, blit.width
	lr	.hCount, A

	; load x and invert
	lr	A, blit.x
	com
.doColumn:
	; I/O write xpos
	outs 4
	; check to see if this byte is finished
	ds	.bitCount
	bnz	.getPixel

;.getByte:
	; reset the bit counter
	lis	8
	lr	.bitCount, A
	; get the next graphics byte
	lm
	lr	.pxData, A
	
; DC += 0 or DC -= 1 depending on if the fill flag is set
	li FILL
	ns blit.color
	bz setFill
	li $FF
setFill:
	adc

.getPixel:
	; shift graphics byte
	lr	A, .pxData
	as	.pxData ; shift left one (with carry)
	lr	.pxData, A

	; check color to use
	lr	A, blit.color
	; if top bit of .pxData is set, draw the FG color
	bc	.setColor
	; else, get the BG color
	sl 4
.setColor:
	; skip write if clear flag is set for this color
	sl 1
	bm .checkColumn
	sl 1 ; put the color in place
	com ; invert the colors because i'm a monster
	; I/O write the color
	ni %11000000
	outs 1

;.blitTransferData:
; Activate the write
	li $60
	outs 0
	li $c0
	outs 0

; Loop 6 times
.delay:
	ai $60
	bnz .delay

.checkColumn:
	ds .hCount
	bz	.checkRow

; x--, do next column
	ins	4
	ai	$ff
	br	.doColumn

; y--
.checkRow:
	ins	5
	ai	$ff
	br	.doRow

.exit:
	; return from the subroutine
	pop
	
; end of blit()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; blitAttribute(color, y, h)
; 
; Alternate entry point for blit, to make drawing attributes easier.

; == Arguments
; blit.color
; blit.y
; blit.height

blitAttribute: subroutine
	li $7d
	lr blit.x, a
	li 2
	lr blit.width, a
	dci .BLIT_ATTR
	jmp blit

; Fill pattern
.BLIT_ATTR: db %10101010

; end of blitAttribute()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; blitNum(color,x,y,char)
;
; Alternate entry point for blit() to make drawing numbers easier.

; r2 = color - fg, bg, Fill (Ftaa-Tbb)
; r3 = x position
; r4 = y position
; r5 = char
; r6 = 
;
; r7 = horizontal counter
; r8 = graphics byte
; r9 = bit counter
;
; DC = pointer to graphics

; == Args
;blit.color
;blit.x
;blit.y
blit.char = 5

blitNum: subroutine
	; DC = NUMERALS + num*2
	dci NUMERALS
	lr a, blit.char
	sl 1
	adc
	; set width/height
	li 3
	lr blit.width, a
	li 5
	lr blit.height, a
	jmp blit

; end of blitNum()
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; blitGraphic(*params)
;
; Alternate entry point for blit() to make it easy to draw a bitmap
;
; Takes graphic parameters from ROM, stores them in r2-r6, changes the DC and
; calls the blit function with the parameters

blitGraphic: subroutine
	; load six bytes from the parameters into r2-r6
	setisar 002
.getParams:
	; load byte, increment DC and IS
	lm
	lr (IS)+, A
	; loop until IS=7
	br7	.getParams
	; load the graphics address
	lm
	lr	Qu, A
	lm
	lr	Ql, A
	lr	DC, Q

	jmp	blit
	
; EoF