include macros.inc

org 0
jmp start

const K = $efe

db $43 $41 $52 $4f   ; -- CARO

:start 
lda #$00  ; clear accu
ldb #K
:loop
sta $1300 : gt   ; if greater than
jmp loop  : eq   ; if equal
out b, $7f
in g, $80

