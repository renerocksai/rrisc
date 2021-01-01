
MACRODEF testmacro
lda # @1    ; load a with 1st passed in parameter
sta @2      ; store to addr defined by 2nd param
ldb @2
ENDMACRO

MACRODEF loop_forever
:@label
jmp @label  ; jump to local label
ENDMACRO


