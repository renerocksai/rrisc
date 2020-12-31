#!/usr/bin/env bash

ghdl -m --workdir=alu alu_tb

# simulate it
ghdl -r --workdir=alu alu_tb --fst=alu_tb.fst --assert-level=error #--disp-time 
