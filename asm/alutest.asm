; -------------------
; -- ALU test prog --
; -- for RRISC ALU --
; -------------------

include alu.inc

org 0

lda #$01
ldb #$05 

ldb #$03 : EQ  ; should not execute
               ; because EQ (zero)
			   ; flag isn't set

macro ADD_A_B        ; A + B => A
               ; (A = 6)
ldb #$06       ; B = 6

; if A == B -> C = $01 else C = $ff
ldc #$ff       ; C = $ff
macro CMP_A_B        ; test A == B
ldc #$01 : EQ  ; C = $01 if EQual

:forever
jmp forever

; we expect:
; A = 6
; B = 6
; C = 1

