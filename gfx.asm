;--------------------------------
; gfx.h
;
; Code adapted from veswiki, which in turn was adapted from videocart 26

;===========;
; Blit Code ;
;===========;

;--------------------;
; Blit Attribute     ;
;--------------------;
; Args
; r2 = color - fg, bg, Fill (aa--bbCF)
; r4 = y position
; r6 = height (and vertical counter)

blitAttribute:
	;lr a,blit.color
	;oi BLIT_FILL
	;lr blit.color,a
	li $7d
	lr blit.x, a
	li 2
	lr blit.width, a
	dci .BLIT_ATTR
	jmp blit

.BLIT_ATTR: db %10101010
;db %10101010

;---------------
; BlitNum
;---------------
; args
; r2 = color - fg, bg, Fill (aa--bbCF)
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
blit.num = 5

blitNum:
	; DC = NUMERALS + num*2
	dci NUMERALS
	lr a, blit.num
	sl 1
	adc
	; set width/height
	li 3
	lr blit.width, a
	li 5
	lr blit.height, a
	;blit()
	jmp blit
	

;--------------;
; Blit Graphic ;
;--------------;


; takes graphic parameters from ROM, stores them in r1-r6, 
; changes the DC and calls the blit function with the parameters
;
; modifies: r1-r6, Q, DC

blitGraphic:
	; load six bytes from the parameters into r0-r5
	lisu	0
	lisl	2
.blitGraphicGetParms:
	lm   
	lr	I, A						; store byte and increase ISAR
	br7	.blitGraphicGetParms				; not finished with the registers, loop

	; load the graphics address
	lm
	lr	Qu, A						; into Q
	lm
	lr	Ql, A
	lr	DC, Q						; load it into the DC

	; call the blit function
	jmp	blit

;---------------;
; Blit Function ;
;---------------;

; this function blits a graphic based on parameters set in r1-r6,
; and the graphic data pointed to by DC0, onto the screen
; originally from cart 26, modified and annotated
;
; modifies: r2-r9, DC

; register reference:
; -------------------
; r2 = color - fg, bg, Fill (aa--bbCF)
; (Ftaa-Tbb)
; r3 = x position
; r4 = y position
; r5 = width
; r6 = height (and vertical counter)
;
; r7 = horizontal counter
; r8 = graphics byte
; r9 = bit counter
;
; DC = pointer to graphics
;blit.colorA = 1
;blit.colorB = 2
blit.color = 2
blit.x = 3
blit.y = 4
blit.width = 5
blit.height = 6

;BLIT_FILL  = %00000001
;BLIT_CLEAR = %00000010
BLIT_FILL  = %10000000
BLIT_CLEAR = %01000000
BLIT_CLEAR2 = %00000100

blit: subroutine

.hCount = 7
.pxData = 8
.bitCount = 9


	lis	1
	lr	.bitCount, A						; load #1 into r9 so it'll be reset when we start
	lr A, blit.y ; load the y offset
	com							; invert it
.doRow:
	outs 5						; load accumulator into port 5 (row)

	; check vertical counter
	ds	blit.height	; decrease r6 (vertical counter)
	bnc	.exit ; if it rolls over exit

	; load the width into the horizontal counter
	lr	A, blit.width
	lr	.hCount, A

	lr	A, blit.x ; load the x position
	com	 ; complement it
.doColumn:
	outs 4						; use the accumulator as our initial column
	; check to see if this byte is finished
	ds	.bitCount						; decrease r9 (bit counter)
	bnz	.getPixel					; if we aren't done with this byte, branch

;.getByte:
	; get the next graphics byte and set related registers
	lis	8
	lr	.bitCount, A						; load #8 into r9 (bit counter)
	lm
	lr	.pxData, A ; load a graphics byte into r8
	
; DC += -1 or DC-=1
	li BLIT_FILL
	ns blit.color
	bz setFill
	li $FF
setFill:
	adc

.getPixel:
	; shift graphics byte
	lr	A, .pxData ; load r8 (graphics byte)
	as	.pxData						; shift left one (with carry)
	lr	.pxData, A						; save it

	; check color to use
	lr	A, blit.color			; load fg color
	bc	.setColor					; if this bit is on, draw the color
	; skip write if bg color is clear
;	ni BLIT_CLEAR
;	bnz .checkColumn
	; load bg color
;	lr a, blit.color
	sl 4
.setColor:
	sl 1
	bm .checkColumn
	sl 1
	com
	ni %11000000
	outs 1						; output A in p1 (color)

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

; x--
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
;---------------------------

SMILE:
	db %01010010
	db %10000001
	db %00010111
	db 0

SMILE_A:
	db %00110100
	db 10,10,5,5
	dw SMILE
	
SMILE_B:
	db %01000001
	db 20,18,5,5
	dw SMILE	
	
; Fill patterns
SOLID: db %11111111
CHECKER: db %10101010
SPARSE: db %10000000

; color,x,y,w,h,dc

CLEAR_SCREEN:
	;db %00001100 | BLIT_FILL
	db %00000011 | BLIT_FILL
	db 0,0
	db $7b, $40
	dw SOLID
	
CHECKER_OVERLAY:
	;db %10000010 | BLIT_FILL
	db %00100100 | BLIT_FILL
	db 0,0
	db $7b, $40
	dw SPARSE

WATER_ATTR_PX:
	db %10011010, %01101010
	
water_attr:
	;db %10000000
	db %00100000
	db $7d, 64-10
	db 2,8
	dw WATER_ATTR_PX
	
;; Numerals 3x5 - self-made - 2 bytes each
NUMERALS:
	db %11110110, %11011110 ; 0
	db %01011001, %00101110 ; 1
	db %11000101, %01001110 ; 2
	db %11100101, %10011110 ; 3
	db %10110111, %10010010 ; 4
	db %11110011, %00011100 ; 5
	db %01110011, %11011110 ; 6
	db %11100100, %10100100 ; 7
	db %11110111, %11011110 ; 8
	db %11110111, %10010010 ; 9
	db %01010111, %11011010 ; A
	db %11010111, %01011100 ; B
	db %01110010, %01000110 ; C
	db %11010110, %11011100 ; D
	db %11110011, %01001110 ; E
	db %11110011, %01001000 ; F
	
FLAG_BG:
	db %00000011 | BLIT_FILL
	db 0,0
	db 27, $40
	dw SOLID
FLAG_B:
	db %00010011 | BLIT_FILL
	db 27,0
	db 27, $40
	dw SOLID
FLAG_G:
	db %00100011 | BLIT_FILL
	db 27*2,0
	db 27, $40
	dw SOLID
FLAG_R:
	db %00110011 | BLIT_FILL
	db 27*3,0
	db 27, $40
	dw SOLID

FLAG_ATTR_GRAY:
	db %10000010
	db $7d, 0
	db 2,16
	dw CHECKER

FLAG_ATTR_BLUE:
	db %10100000
	db $7d, 16
	db 2,16
	dw CHECKER
	
FLAG_ATTR_GREEN:
	db %10100010
	db $7d, 32
	db 2,16
	dw CHECKER
	
FLAG_ATTR_BW:
	db %10000000
	db $7d, 48
	db 2,16
	dw CHECKER
	
; %10000000 ;bw
; %10000010 ;gray
; %10100000 ;blue
; %10100010 ;green
; EoF