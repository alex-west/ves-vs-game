;--------------------------------
; gfx.h
;
; Code adapted from veswiki, which in turn was adapted from videocart 26

;===========;
; Blit Code ;
;===========;

;
; Blit Attribute
;
; Args
; r2 = color - fg, bg, Fill (aa--bb-F)
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
; r2 = color - fg, bg, Fill (aa--bb-F)
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

BLIT_FILL = %00000001

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
	lis BLIT_FILL
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
	sl 4                        ; load bg color
	;lr	A, blit.colorA			; load color 2
.setColor:
	; ??
	;inc
	;bc .checkColumn				; branch if the color is "clear"
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

SMILE:
	db %01010010
	db %10000001
	db %00010111
	db 0

; Fill patterns
SOLID: db %11111111
CHECKER: db %10101010

CLEAR_SCREEN:
	db %00001100 | BLIT_FILL
	db 0,0
	db $7b, $40
	dw SOLID

; EoF