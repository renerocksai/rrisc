; -------------------------------
; --  Arty S7 board test prog  --
; --   for RRISC ALU on FPGA   --
; -------------------------------

include arty.inc

const my_delay = $01ca ; $0100 gives us 500ms, this gives us 395.595 ms

org 0

; ---------------
; register usage:
; ---------------
; A : LED pattern (running light)
; B : Button, ALU instructions
; C : delay constant counter 500ms high byte
; D : delay constant counter 500ms low byte 
; E : delay factor counter 1 x 500ms high byte
; F : delay factor counter 1 x 500 ms low byte
; G : unused


MACRODEF LEFT                ; shifts led pattern to the left
out a, LED_PORT
out a, ALU_PORT_A
ldb # ALU_ROL
out b, ALU_PORT_INSTR
in a, ALU_PORT_RESULT
ENDMACRO

MACRODEF RIGHT                ; shifts led pattern to the rightk
out a, LED_PORT
out a, ALU_PORT_A
ldb # ALU_ROR
out b, ALU_PORT_INSTR
in a, ALU_PORT_RESULT
ENDMACRO

lda # $00      
out a, LED_PORT               ; initially, clear led pattern

:loop                         ; loop until button is pressed
in b, BTN_PORT
out b, ALU_PORT_A
ldb # $01
out b, ALU_PORT_B
ldb # ALU_AND 
out b, ALU_PORT_INSTR
in b, ALU_PORT_RESULT
jmp loop : EQ

; running light
lda #$01                      ; delay and shift 
macro LEFT
macro DELAY my_delay
macro LEFT
macro DELAY my_delay
macro LEFT
macro DELAY my_delay
macro LEFT
macro DELAY my_delay

macro RIGHT
macro RIGHT
macro RIGHT
macro DELAY my_delay
macro RIGHT
macro DELAY my_delay
macro RIGHT
jmp loop

