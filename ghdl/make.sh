#!/usr/bin/env bash
mkdir -p pmem
mkdir -p regs


# import all sources (note: could specifically only specify pmem related sources)
ghdl -i --workdir=pmem ../project_2.srcs/sources_1/new/pmem*.vhd ../project_2.srcs/sim_1/new/pmem*.vhd
ghdl -i --workdir=regs ../project_2.srcs/sources_1/new/reg*.vhd ../project_2.srcs/sim_1/new/reg*.vhd

# make: analyze and elaborate the pmem_tb testbench
ghdl -m --workdir=pmem pmem_tb
ghdl -m --workdir=regs registers_tb
