#!/usr/bin/env bash

ghdl -m --workdir=pmem pmem_tb

# simulate it
ghdl -r --workdir=pmem pmem_tb --stop-time=150ns --fst=pmem_tb.fst
