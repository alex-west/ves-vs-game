
;SMILE:
;	db %01010010
;	db %10000001
;	db %00010111
;	db 0
;
;; color,x,y,w,h,dc
;	
;SMILE_A:
;	db GREEN_A|CLEAR_BG
;;	db %00110100
;	db 10,10,5,5
;	dw SMILE
;	
;SMILE_B:
;	db %01000001
;	db 20,18,5,5
;	dw SMILE	
	
; Fill patterns
SOLID: db %11111111
CHECKER: db %10101010
SPARSE: db %10000000

CLEAR_SCREEN:
	db %00000011 | FILL
	db 0,0
	db $7b, $40
	dw SOLID
	
CHECKER_OVERLAY:
	db %00100100 | FILL
	db 0,0
	db $7b, $40
	dw SPARSE
	
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
	
	; Special characters
CHR_BRIDGE_L = $10
	db %11111011, %00000000 ; $11 - Left bridge
CHR_BRIDGE_R = $11
	db %11101101, %10000000 ; $12 - Right bridge
	
	
;FLAG_BG:
;	db BKG_A | FILL
;	db 0,0
;	db 27, $40
;	dw SOLID
;FLAG_B:
;	db BLUE_A | FILL
;	db 27,0
;	db 27, $40
;	dw SOLID
;FLAG_R:
;	db RED_A | FILL
;	db 27*2,0
;	db 27, $40
;	dw SOLID
;FLAG_G:
;	db GREEN_A | FILL
;	db 27*3,0
;	db 27, $40
;	dw SOLID
;
;FLAG_ATTR_GRAY:
;	db BG_GRAY
;	db $7d, 0
;	db 2,16
;	dw CHECKER
;
;FLAG_ATTR_BLUE:
;	db BG_BLUE
;	db $7d, 16
;	db 2,16
;	dw CHECKER
;	
;FLAG_ATTR_GREEN:
;	db BG_GREEN
;	db $7d, 32
;	db 2,16
;	dw CHECKER
;	
;FLAG_ATTR_BW:
;	db BG_MONO
;	db $7d, 48
;	db 2,16
;	dw CHECKER

; EoF