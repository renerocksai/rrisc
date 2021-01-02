; -------------------------------
; --  Arty S7 board test prog  --
; --   for RRISC ALU on FPGA   --
; -------------------------------

include arty.inc
const my_delay = $0100 ; gives us 500ms

org 0

MACRODEF LEFT
out a, LED_PORT
macro DELAY my_delay
ldb # ALU_ROL
out a, ALU_PORT_A
out g, ALU_PORT_INSTR
in a, ALU_PORT_RESULT
ENDMACRO

MACRODEF RIGHT
out a, LED_PORT
macro DELAY my_delay
ldb # ALU_ROR
out a, ALU_PORT_A
out g, ALU_PORT_INSTR
in a, ALU_PORT_RESULT
ENDMACRO

; running light
:loop
lda #$01
macro LEFT
macro LEFT
macro LEFT
macro DELAY my_delay
macro RIGHT
macro RIGHT
macro RIGHT
macro DELAY my_delay
jmp loop

