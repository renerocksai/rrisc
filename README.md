# rrisc
VHDL implementation of my RRISC CPU

I developed the RRISC CPU in 1990/91, with the intention to build it using just 74xx TTL logic circuits. After having drawn schematics, printed circuit boards, and implementing an assembler and simulator in Turbo Pascal, I got to play around with the CPU only in the simulator. This Christmas I thought I would revive the 30 years old project, but implement it in VHDL so I can program an FPGA with it in order to get my CPU up and running in the physical world.

This is the progress I've made so far:

# It's executing its first instruction!!!

```
lda # $CA    ; load register A with immediate value 0xCA
```

![image](https://user-images.githubusercontent.com/30892199/103259340-3bfa1080-4999-11eb-84a3-6e24cd6d44a9.png)

---

[asm](https://github.com/renerocksai/rrisc/tree/main/asm) - contains the assembler and `simtest.asm` which is used for first tests of the CPU

[ghdl](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the [->ghdl](https://github.com/ghdl/ghdl) testbench scripts: make and run tests

[project_2.srcs](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the VHDL CPU and testbench sources. It's in Vivado style folders. But free [ghdl](https://github.com/ghdl/ghdl) can be used for simulations, Vivado is only required for programming your FPGA.

More info on the minimalistic RRISC CPU will follow as soon as I get to it. 

---

This is where it will run: my Xilinx Spartan-7 FPGA board :

![image](https://user-images.githubusercontent.com/30892199/103259761-0c4c0800-499b-11eb-9c5e-8fb334655b68.png)


# vim, tmux, ghdl & gtkwave workflow

Via ssh :)

It's super smooth, editing VHDL in vim, running ghdl in a separate tmux pane via vim-tmux, and using gtkwave to view the waveforms of the simulation. Textual simulaiton output and logging can be viewed as ghdl's output. I prefer this super quick 1-keystroke way of running my testbenches, compared to the Vivado workflow. Extra plus, vim and commandline work smoothly over ssh. 

![image](https://user-images.githubusercontent.com/30892199/103260189-22f35e80-499d-11eb-9a61-f724f4163be4.png)


