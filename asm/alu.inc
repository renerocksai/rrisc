; -------------------
; -- ALU constants --
; -- for RRISC ALU --
; -------------------

const ALU_ADD  =  0    ; addition with carry, sets carry (gt)
const ALU_SUB  =  1    ; subtraction with carry, sets carry(gt)
const ALU_SHL  =  2    ; shift left into carry, sets carry(gt)
const ALU_SHR  =  3    ; shift right into carry, sets carry(gt)
const ALU_ROL  =  4    ; rotate left
const ALU_ROR  =  5    ; rotate right
const ALU_OR   =  6    ; binary or
const ALU_AND  =  7    ; binary and
const ALU_NAND =  8    ; binary not and
const ALU_XOR  =  9    ; binary exclusive or
const ALU_XNOR = 10    ; binary exclusive not or
const ALU_CMP  = 11    ; compare, sets carry (gt), sm, eq flags
const ALU_INC  = 12    ; increments A by 1, sets equal (zero) flag on zero
const ALU_DEC  = 13    ; decrements A by 1, sets equal (zero) flag on zero
