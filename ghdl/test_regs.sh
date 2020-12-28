#!/usr/bin/env bash

ghdl -m --workdir=regs registers_tb

# simulate it
ghdl -r --workdir=regs registers_tb --stop-time=150ns --fst=registers_tb.fst --assert-level=error #--disp-time 
