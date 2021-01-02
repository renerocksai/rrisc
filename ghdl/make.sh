#!/usr/bin/env bash
mkdir -p pmem
mkdir -p regs
mkdir -p core
mkdir -p alu
mkdir -p cpu
mkdir -p top

# import all sources (note: could specifically only specify pmem related sources)
ghdl -i --workdir=pmem ../project_2.srcs/sources_1/new/pmem*.vhd ../project_2.srcs/sim_1/new/pmem*.vhd
ghdl -i --workdir=regs ../project_2.srcs/sources_1/new/*.vhd ../project_2.srcs/sim_1/new/reg*.vhd
ghdl -i --workdir=core ../project_2.srcs/sources_1/new/*.vhd ../project_2.srcs/sim_1/new/*.vhd
ghdl -i --workdir=alu ../project_2.srcs/sources_1/new/*.vhd ../project_2.srcs/sim_1/new/alu*.vhd
ghdl -i --workdir=cpu ../project_2.srcs/sources_1/new/*.vhd ../project_2.srcs/sim_1/new/cpu_tb.vhd ../project_2.srcs/sim_1/new/test_ram.vhd
ghdl -i --workdir=top ../project_2.srcs/sources_1/new/*.vhd ../project_2.srcs/sim_1/new/top_tb.vhd 

# make: analyze and elaborate the pmem_tb testbench
ghdl -m --workdir=pmem pmem_tb
ghdl -m --workdir=regs registers_tb
ghdl -m --workdir=alu alu_tb
ghdl -m --workdir=core core_tb
ghdl -m --workdir=cpu cpu_tb
ghdl -m --workdir=top top_tb
