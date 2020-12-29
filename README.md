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
2. [It runs the whole test program](https://github.com/renerocksai/rrisc#its-executing-the-whole-test-program)
2. [Radical RISC from the early nineties](https://github.com/renerocksai/rrisc#radical-risc-from-the-early-nineties)
3. [Open source, text-based VHDL design: vim, tmux, ghdl, gtkwave](https://github.com/renerocksai/rrisc#vim-tmux-ghdl--gtkwave-workflow)
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

The instruction `lda # $CA` does the following:
- it takes the value _$CA_ (_202_ in hexadecimal); the hexadecimal notation prefix `$` is taken from the good old 6502, C64 days
- it stores this value in register A

The image below shows the CPU going out of reset and then executing its first instruction, the instruction above, in 8 clock cycles.

The thin red vertical line to the right in the image is placed at ca. 90 nanoseconds, right after the _execute_ phase of the instruction. In the last, blue line of the diagram you can see *cpureg_a* (register A) receiving the value `CA` at the end of _execute_. 

If you look carefully, you can see that value travel from *ram_out* via *debug_inr2* (instruction register 2 containing the operand, the value `CA` in our case) to register A.

![image](https://user-images.githubusercontent.com/30892199/103280947-e4c46200-49d1-11eb-9e5f-1e69fb49baaf.png)


Here is what's going on in the core of the CPU:
- 0 .. 10 ns : reset, as indicated by the rst signal
  - *ram_addr* is reset to 0, so execution will start from there
  - the cpu is prepared to start with state *wakeup*
  - the RAM is in reset mode, too, outputting zeros 
- 10 .. 15 ns: 
  - cpu is active in *wakeup*, doing nothing until the next clock cycle
- 15 .. 25 ns: 
  - cpu enters *ram_wait_1* state, giving the RAM time to output the opcode
  - ram outputs the opcode at address 0, ready for the cpu to grab it in the next cycle
- 25 .. 35 ns:
  - now in *fetch_1*, the cpu loads *ram_out* into instruction register 1, shown as *debug_inr1*
  - it also sets *pc_clock* to 1, so the program counter will be incremented in the next cycle
  - program counter increments *ram_addr* to 1
- 35 .. 45 ns:
  - cpu in *ram_wait_2*
  - ram output is valid at the end of the cycle: *$CA*
- 45 .. 55 ns:
  - now in *fetch_2*, the cpu loads *ram_out* into instruction register 2, shown as *debug_inr2*
  - it also sets *pc_clock* to 1, so the program counter will be incremented in the next cycle
  - program counter increments *ram_addr* to 2
- 55 .. 65 ns:
  - cpu in *ram_wait_3*
  - ram output is valid at the end of the cycle: *$00*
- 65 .. 75 ns:
  - now in *fetch_3*, the cpu loads *ram_out* into instruction register 3, shown as *debug_inr3*
  - *(no program counter increment here)*
- 75 .. 85 ns:
  - cpu enters *decode* stage
  - it proactively disconnects *ram_addr* from the program counter and sets it to instruction registers 3 (00) and 2 (0A), just in case a ram load / store or jump operation is executed
  - hence, *ram_addr* changes to 0a
  - now the ram would have time to output the contents of address 0a in case it's needed
- 85 .. 95 ns:
  - in *execute*, the contents of instruction register 1 are loaded into register A
    - note: register A captures the value at the beginning of the next cycle
   - since it is not a jump instruction, *pc_clock* is raised again to increment the program counter to 3, where the next instruction will start
  - *ram_addr* is switched back to the program counter 
- 95 .. 100ns:
  - the cpu goes into *ram_wait_1* again, to give the ram time to output the next instruction

# It's executing the whole test program!!!

The test program:

```
org 0             ; start at address 0  (meta)
lda #$ca          ; A = $CA
sta data          ; Store A in RAM at address 'data'
ldb data          ; B = content of RAM at address 'data'
:loop_forever
jmp loop_forever  ; jump to this jmp instruction, repeating itself forever
:data
db $ff            ; <--- here the data will be stored, $ff will be overwritten 
                  ;      by $CA 
```

What we expect after running this:
- Both registers A and B containing the value $CA
  - that means writing to and reading from RAM works
- The program counter being set to address $0009 (where the jump is) as the jump instruction is executed
  - hence, the instruction repeating itself
  - instead of the program counter incrementing past address $000B

As you can see below, both registers contain the value $CA and the program counter falling back to $0009 after reaching $000B

![image](https://user-images.githubusercontent.com/30892199/103299193-4699c180-49fc-11eb-9313-7a4d1407bb4b.png)

Zooming in to the first jump:

![image](https://user-images.githubusercontent.com/30892199/103298890-94fa9080-49fb-11eb-90dd-5c4e36a62733.png)

Et voila! The CPU works as expected :-)

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

