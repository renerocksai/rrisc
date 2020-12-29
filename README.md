# rrisc
VHDL implementation of my RRISC CPU

I developed the RRISC CPU in 1992/93, with the intention to build it using just 74xx TTL logic circuits. After having drawn schematics, printed circuit boards, and implementing an assembler and simulator in Turbo Pascal, I got to play around with the CPU only in the simulator. This Christmas I thought I would revive the 30 years old project, but implement it in VHDL so I can program an FPGA with it in order to get my CPU up and running in the physical world.

This is the progress I've made so far:

1. [It's executing its first instruction](https://github.com/renerocksai/rrisc#its-executing-its-first-instruction)
2. [Radical RISC from the early nineties](https://github.com/renerocksai/rrisc#radical-risc-from-the-early-nineties)
3. [Open source, text-based VHDL design: vim, tmux, ghdl, gtkkwave](https://github.com/renerocksai/rrisc#vim-tmux-ghdl--gtkwave-workflow)

# It's executing its first instruction!!!

```
lda # $CA    ; load register A with immediate value 0xCA
```

![image](https://user-images.githubusercontent.com/30892199/103259340-3bfa1080-4999-11eb-84a3-6e24cd6d44a9.png)

---

- [asm](https://github.com/renerocksai/rrisc/tree/main/asm) - contains the assembler and [simtest.asm](https://github.com/renerocksai/rrisc/blob/main/asm/simtest.asm) which is used for first tests of the CPU
- [ghdl](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the [->ghdl](https://github.com/ghdl/ghdl) testbench scripts: make and run tests
- [project_2.srcs](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the VHDL CPU and testbench sources. It's in Vivado style folders. But free [ghdl](https://github.com/ghdl/ghdl) can be used for simulations, Vivado is only required for programming your FPGA.

More info on the minimalistic RRISC CPU will follow as soon as I get to it. 

# Radical RISC from the early nineties

Let's walk down memory lane. Here are a few design documents of the original RRISC CPU:

![cpu1](https://user-images.githubusercontent.com/30892199/103261827-2a1d6b00-49a3-11eb-9059-535dd5146852.jpg)

![cpu2](https://user-images.githubusercontent.com/30892199/103261847-39041d80-49a3-11eb-99c7-6f4847c922f6.jpg)

![image](https://user-images.githubusercontent.com/30892199/103262039-fd1d8800-49a3-11eb-8059-327ff2c138cd.png)
![image](https://user-images.githubusercontent.com/30892199/103262387-16730400-49a5-11eb-916a-6a68d457bb2c.png)

![Screenshot 2020-12-29 at 07 04 55](https://user-images.githubusercontent.com/30892199/103262189-6d2c0e00-49a4-11eb-9b6d-87ae2d60443e.png)

![Screenshot 2020-12-29 at 07 05 31](https://user-images.githubusercontent.com/30892199/103262201-73ba8580-49a4-11eb-8bb8-017ca3ad27c9.png)

![image](https://user-images.githubusercontent.com/30892199/103261975-c8a9cc00-49a3-11eb-9f9a-d641bbe29d50.png)

![Screenshot 2020-12-29 at 06 59 56](https://user-images.githubusercontent.com/30892199/103262046-07d81d00-49a4-11eb-8441-7309dff50104.png)

![Screenshot 2020-12-29 at 07 05 15](https://user-images.githubusercontent.com/30892199/103262216-859c2880-49a4-11eb-9e29-5961f979d903.png)

![load](https://user-images.githubusercontent.com/30892199/103262701-0f98c100-49a6-11eb-8735-f23eb3a40f4b.jpg)
![store](https://user-images.githubusercontent.com/30892199/103262710-158ea200-49a6-11eb-8eb0-9b5ac150c8b0.jpg)
![fetch](https://user-images.githubusercontent.com/30892199/103262716-19babf80-49a6-11eb-9e65-19c49d2f28c6.jpg)



---
<!--
This is where it will run: my Xilinx Spartan-7 FPGA board :

![image](https://user-images.githubusercontent.com/30892199/103259761-0c4c0800-499b-11eb-9c5e-8fb334655b68.png)

-->

# vim, tmux, ghdl & gtkwave workflow

Via ssh :)

It's super smooth, editing VHDL in vim, running ghdl in a separate tmux pane via vim-tmux, and using gtkwave to view the waveforms of the simulation. Textual simulaiton output and logging can be viewed as ghdl's output. I prefer this super quick 1-keystroke way of running my testbenches, compared to the Vivado workflow. Extra plus, vim and commandline work smoothly over ssh. 

![image](https://user-images.githubusercontent.com/30892199/103260189-22f35e80-499d-11eb-9a61-f724f4163be4.png)


