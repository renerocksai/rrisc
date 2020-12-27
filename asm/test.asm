org 0

:start 
lda #$00  ; clear accu
:loop
sta $1300
jmp loop
out b, $7f
in g, $80

