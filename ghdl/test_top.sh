#!/usr/bin/env bash

ghdl -m --workdir=top top_tb

# simulate it
ghdl -r --workdir=top top_tb --fst=top_tb.fst --assert-level=error #--disp-time 
