# rrisc
VHDL implementation of my [RRISC](https://github.com/renerocksai/rrisc#btw-whats-so-special-about-rrisc) CPU

> *In a hurry? See it work [here](https://github.com/renerocksai/rrisc#its-executing-its-first-instruction)*


In the early nineties, when I finally figured out how to do sequential digital circuits, I used the momentum of that heureka-moment to develop the [RRISC](https://github.com/renerocksai/rrisc#btw-whats-so-special-about-rrisc) CPU (Radically Reduced Instruction Set Computer), with the intention to build it using just 74xx TTL logic circuits. It was meant both as an educational and also instructive endeavor, as I figured such a simple CPU would be ideal for teaching the basics of CPU design. Being able to make an actual CPU from just two easy-to-build printed circuit boards would also free the whole topic from being a merely abstract one. If you put a bit of extra work in, you could actually see the CPU work.

After having drawn schematics, printed circuit boards, (and done it all again in P-CAD later), timing diagrams, and implementing an assembler and simulator in Turbo Pascal, I got to play around with the CPU only in the self-written simulator, displaying all CPU states and fancy 7-segment displays in DOS. 

Despite all my intentions, I never got around to actually build it. Part of what was stopping me was that I had no EPROM programmer for writing programs into an EPROM that I would then insert into the CPU board to give the CPU something to execute. Eventhough I designed a cool battery powered SRAM module with PC printer interface (there was no USB back then, on my 80386 PC!), which would eliminate the need for EPROMs, I never got to build that either. Instead I focused on replacing the EPROM containing the CPU microcode by a GAL, my first step towards using programmable logic. 

This lead me down the path of minimizing combinatorial digital logic circuits (Quine McCluskey anyone?), creating CAD files for automating production of minimized circuits, ... Which all developed a life of its own, until I was past mere CPU design - I knew it worked, which was almost as good as seeing it work. And I moved on. 

30 years ago I went to school and had no money. I thought then, one day when I earn money, I'll get myself all the parts and programmers I need and build my CPU then. Which I almost forgot. Until now.

So, this Christmas, I thought I would revive the 30 years old project, but this time implement the CPU in VHDL so I can program an FPGA with it in order to get my CPU up and running in the physical world.

This is the progress I've made so far:

1. [It's executing its first instruction](https://github.com/renerocksai/rrisc#its-executing-its-first-instruction)
2. [Radical RISC from the early nineties](https://github.com/renerocksai/rrisc#radical-risc-from-the-early-nineties)
3. [Open source, text-based VHDL design: vim, tmux, ghdl, gtkkwave](https://github.com/renerocksai/rrisc#vim-tmux-ghdl--gtkwave-workflow)
4. [The FPGA](https://github.com/renerocksai/rrisc#the-fpga)

The code is organized as follows:

- [asm](https://github.com/renerocksai/rrisc/tree/main/asm) - contains the assembler and [simtest.asm](https://github.com/renerocksai/rrisc/blob/main/asm/simtest.asm) which is used for first tests of the CPU
- [ghdl](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the [->ghdl](https://github.com/ghdl/ghdl) testbench scripts: make and run tests
- [project_2.srcs](https://github.com/renerocksai/rrisc/tree/main/ghdl) - contains the VHDL CPU and testbench sources. It's in Vivado style folders. But free [ghdl](https://github.com/ghdl/ghdl) can be used for simulations, Vivado is only required for programming your FPGA.

More info on the minimalistic [RRISC](https://github.com/renerocksai/rrisc#btw-whats-so-special-about-rrisc) CPU will follow as soon as I get to it. 

#### BTW, what's so special about RRISC:

- the instruction set is truly minimal:
  - load register from RAM / IO port / immediately
  - store register to RAM / IO port
  - jump
- an interesting indirect jump mode:
  - `jmp HI[LO]`  will jump to HI * 256 + [HI * 256 + LO]
  - HIGH byte is specified directly
  - LOW byte is read from memory at address HI * 256 + LO
  - this allows for jmp tables
- above jumps can also be indirected by external port data:
  - `jmpp HI[LO]` will take the LOW byte of the address from **port** HI*256+LO
- ALL instructions can be executed conditionally
    - e.g. `LDA #$00 : EQ` will clear register A only if the EQUAL flag is set
    - this reduces the need for conditional jumps
- the ALU is intended to be port mapped:
  - making the CPU independent from a specific ALU allows for upgradability
  - see example below for adding:

```
     lda #value1          ; first value to add
     out a, ALU_OPERAND1  ; --> into ALU register
     lda #value2          ; second value to add
     out a, ALU_OPERAND2  ; --> into ALU
     lda #ALU_ADD         ; add command
     out a, ALU_CMD       ; --> into ALU
     in a, ALU_RESULT     ; read result
  ```
  


# It's executing its first instruction!!!

```
lda # $CA    ; load register A with immediate value 0xCA
```
The image below shows the CPU going out of reset and then executing its first instruction in 7 clock cycles.

The thin red marker to the right in the image is placed at ca. 90 nanoseconds, after the _execute_ phase of the instruction. In the last line you can see *cpureg_a* (register A) receiving the value `CA` at the end of _execute_. 

If you look carefully, you can see that value travel from *ram_out* via *debug_inr2* (instruction register 2 containing the operand, the value `CA` in our case) to register A.

![image](https://user-images.githubusercontent.com/30892199/103259340-3bfa1080-4999-11eb-84a3-6e24cd6d44a9.png)


# Radical RISC from the early nineties

Let's walk down memory lane. Here are a few design documents of the original RRISC CPU:

![cpu1](https://user-images.githubusercontent.com/30892199/103261827-2a1d6b00-49a3-11eb-9059-535dd5146852.jpg)

![cpu2](https://user-images.githubusercontent.com/30892199/103261847-39041d80-49a3-11eb-99c7-6f4847c922f6.jpg)

Microcode
![image](https://user-images.githubusercontent.com/30892199/103268856-918fe680-49b4-11eb-8e19-69d7a5e85080.png)

![image](https://user-images.githubusercontent.com/30892199/103262039-fd1d8800-49a3-11eb-8059-327ff2c138cd.png)

![image](https://user-images.githubusercontent.com/30892199/103262387-16730400-49a5-11eb-916a-6a68d457bb2c.png)

![Screenshot 2020-12-29 at 07 04 55](https://user-images.githubusercontent.com/30892199/103262189-6d2c0e00-49a4-11eb-9b6d-87ae2d60443e.png)

![Screenshot 2020-12-29 at 07 05 31](https://user-images.githubusercontent.com/30892199/103262201-73ba8580-49a4-11eb-8bb8-017ca3ad27c9.png)

![Screenshot 2020-12-29 at 06 59 56](https://user-images.githubusercontent.com/30892199/103262046-07d81d00-49a4-11eb-8441-7309dff50104.png)

![Screenshot 2020-12-29 at 07 05 15](https://user-images.githubusercontent.com/30892199/103262216-859c2880-49a4-11eb-9e29-5961f979d903.png)

![load](https://user-images.githubusercontent.com/30892199/103262701-0f98c100-49a6-11eb-8735-f23eb3a40f4b.jpg)

![store](https://user-images.githubusercontent.com/30892199/103262710-158ea200-49a6-11eb-8eb0-9b5ac150c8b0.jpg)

![fetch](https://user-images.githubusercontent.com/30892199/103262716-19babf80-49a6-11eb-9e65-19c49d2f28c6.jpg)



---

# vim, tmux, ghdl & gtkwave workflow

Via ssh :)

It's super smooth, editing VHDL in vim, running ghdl in a separate tmux pane via vim-tmux, and using gtkwave to view the waveforms of the simulation. Textual simulation output and logging can be viewed as ghdl's output. I prefer this super quick 1-keystroke way of running my testbenches, compared to the sluggish Vivado GUI workflow. 

As an extra plus, vim and commandline work smoothly over ssh. With X-forwarding enabled, gtkwave works via ssh, too.
![image](https://user-images.githubusercontent.com/30892199/103270890-4debab80-49b9-11eb-8c8a-1308093d7b4c.png)

![image](https://user-images.githubusercontent.com/30892199/103263325-d2353300-49a7-11eb-8fa0-b168ecc6ae0d.png)
![image](https://user-images.githubusercontent.com/30892199/103263490-55568900-49a8-11eb-9b65-84b423a1a7b3.png)


# The FPGA

This is where it will run: on my Xilinx Spartan-7 FPGA board "Arty S7":

![image](https://user-images.githubusercontent.com/30892199/103259761-0c4c0800-499b-11eb-9c5e-8fb334655b68.png)

The FPGA will contain:

- the RRISC core
- a port mapped ALU
- 8k of SRAM for code and data

## Going independent

As the Spartan-7 is far too under-utilized with just the RRISC CPU and RAM, I am contemplating putting a MicroBlaze CPU on there as well, running an microsd card boot loader. This will turn the board into a RRISC development board. Programs can then be run from SD-card, without having to re-program the FPGA.

All it takes, is a little microSD card slot and a bit of code.

![image](https://user-images.githubusercontent.com/30892199/103264497-24c41e80-49ab-11eb-956e-8f3ce4ea0793.png)

