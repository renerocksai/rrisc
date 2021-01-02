; -------------------------------
; -- Arty S7 board definitions --
; --   for RRISC ALU on FPGA   --
; -------------------------------

include alu.inc

const BTN_PORT = $fff8;
const SW_PORT  = $fff9;
const LED_PORT = $fffa;

; 8us per instruction
; --> 125k instructions per 1ms

const arty_delay = $10da  ; gives us 500ms

; a simple constant delay
; pollutes c, d, e, f, g
MACRODEF DELAY
ldf # < @1
lde # > @1

:@loop_delay                 ; loop over 16bit const
ldd # <arty_delay
ldc # >arty_delay
:@loop_low                   ; loop over low byte of const
out d, ALU_PORT_A
ldg # ALU_DEC
out g, ALU_PORT_INSTR
in d, ALU_PORT_RESULT
jmp @break_low : EQ
jmp @loop_low
:@break_low                    ; loop over high byte of const
out c, ALU_PORT_A
in c, ALU_PORT_RESULT
jmp @break_high : EQ
jmp @loop_low
:@break_high                  ; loop over low byte of param
out f, ALU_PORT_A
in f, ALU_PORT_RESULT
jmp @break_param_hi : EQ
jmp @loop_delay
:@break_param_hi               ; loop over high byte of param
out e, ALU_PORT_A
in e, ALU_PORT_RESULT
jmp @end : EQ
jmp @loop_delay
:@end
ENDMACRO



