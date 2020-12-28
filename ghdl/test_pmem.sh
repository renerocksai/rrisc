#!/usr/bin/env bash
mkdir -p work

# import all sources (note: could specifically only specify pmem related sources)
ghdl -i --workdir=work ../project_2.srcs/sources_1/new/*.vhd ../project_2.srcs/sim_1/new/*.vhd

# make: analyze and elaborate the pmem_tb testbench
ghdl -m --workdir=work pmem_tb

# simulate it
ghdl -r --workdir=work pmem_tb --stop-time=150ns --fst=pmem_tb.fst
