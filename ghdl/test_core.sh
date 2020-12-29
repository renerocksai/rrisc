#!/usr/bin/env bash

ghdl -m --workdir=core core_tb

# simulate it
ghdl -r --workdir=core core_tb --fst=core_tb.fst --assert-level=error #--disp-time 
