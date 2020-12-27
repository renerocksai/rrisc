include macros.inc

org 0

:start 
lda #$00  ; clear accu
:loop
sta $1300 : gt   ; if greater than
jmp loop  : eq   ; if equal
out b, $7f
in g, $80

