org 16
lda #$cc

MACRODEF testmacro
db $A0 $a1 $a2
db $b0 $b1 $b2

:@label
lda # @1    ; load a with 1st passed in parameter
sta @2      ; store to addr defined by 2nd param
jmp @label  ; jump to local label
ENDMACRO



