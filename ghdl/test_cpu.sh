#!/usr/bin/env bash

ghdl -m --workdir=cpu cpu_tb

# simulate it
ghdl -r --workdir=cpu cpu_tb --fst=cpu_tb.fst --assert-level=error #--disp-time 
