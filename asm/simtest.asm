org 0

lda #$ca 
sta data
ldb data
:loop_forever

jmp loop_forever

:data
db $ff 

