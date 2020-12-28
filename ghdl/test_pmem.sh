#!/usr/bin/env bash

# simulate it
ghdl -r --workdir=work pmem_tb --stop-time=150ns --fst=pmem_tb.fst
