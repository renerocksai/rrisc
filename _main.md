# rrisc
VHDL implementation of my [RRISC](https://github.com/renerocksai/rrisc#btw-whats-so-special-about-rrisc) CPU

![image](https://user-images.githubusercontent.com/30892199/103395117-bad38280-4b2c-11eb-91b5-cb6f7a66f8ac.png)

<!--![image](https://user-images.githubusercontent.com/30892199/103373974-a2d11400-4ad6-11eb-8086-ad39d59cb9d3.png)-->

![image](https://user-images.githubusercontent.com/30892199/103374649-69010d00-4ad8-11eb-9507-7393e7f29b51.png)

> *In a hurry? See it work [here](https://github.com/renerocksai/rrisc/blob/main/_firstinstr.md)*

The code is organized as follows:

- [asm](https://github.com/renerocksai/rrisc/tree/main/asm) - contains the assembler and [simtest.asm](https://github.com/renerocksai/rrisc/blob/main/asm/simtest.asm) which is used for first tests of the CPU
- [ghdl](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the [->ghdl](https://github.com/ghdl/ghdl) testbench scripts: make and run tests
- [project_2.srcs](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the VHDL CPU and testbench sources. It's in Vivado style folders. But free [ghdl](https://github.com/ghdl/ghdl) can be used for simulations, Vivado is only required for programming your FPGA.

More info on the minimalistic [RRISC](https://github.com/renerocksai/rrisc/blob/main/_rrisc.md) CPU will follow as soon as I get to it. 

---

The following documents my journey developing the RRISC CPU, in a sort of blog like fashion:

1. [Background and why I built the RRISC CPU](https://github.com/renerocksai/rrisc/blob/main/_why.md)
2. [What's unique about the RRISC CPU](https://github.com/renerocksai/rrisc/blob/main/_rrisc.md)
3. [It's executing its first instruction](https://github.com/renerocksai/rrisc/blob/main/_firstinstr.md)
4. [It runs the whole test program](https://github.com/renerocksai/rrisc/blob/main/_firstprog.md)
5. **NEW!** [We have an ALU](https://github.com/renerocksai/rrisc/blob/main/_nineties.md)
6. [Radical RISC from the early nineties](https://github.com/renerocksai/rrisc/blob/main/_nineties.md)
7. [Open source, text-based VHDL design: vim, tmux, ghdl, gtkwave](https://github.com/renerocksai/rrisc/blob/main/_vimghdl.md)
8. [The FPGA](https://github.com/renerocksai/rrisc/blob/main/_fpga.md)

