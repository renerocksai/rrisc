# The CPU in action on the FPGA board

All the RRISC CPU's components and the RRISC assembler have now reached a level where they can be used to write real programs and run them on real hardware, utilizing a Xilinx FPGA. 

As described in the [previous section](fpga), I use a Xilinx Spartan-7 on the Arty S7 board from Digilent. The FPGA is programmed to contain:

- The RRISC CPU core
- The RRISC ALU (arithmetic logical unit)
- 1 kB of RAM for testing, initialized with an example program
- 3 ports connected to the Arty board peripherals:
  - 4 LEDs
  - 4 switches
  - 4 buttons

## The example program

The example program is a simple LED running light demo, activated by pressing the button. Once the button is pressed, the light runs from right to left and then back to right, where it remains until the button is pressed again.

Here is the code consisting of the main assembly file [runninglight.asm](https://github.com/renerocksai/rrisc/blob/main/asm/arty_runninglight.asm) and an include file [arty.inc](https://github.com/renerocksai/rrisc/blob/main/asm/arty.inc) containing macro definitions for the Arty board and timing constants:

![](runninglight.asm.png)

A simulation run shows (in the 1st line), that the LEDs are activated in the correct pattern:

![](runlight.timing.png)

So, let's see it in action!

<div class="embed-container">
  <iframe
      src="https://youtube.com/embed/Ecf-VYi4tbY"
      width="700"
      height="480"
      frameborder="0"
      allowfullscreen="">
  </iframe>
</div>


---

^ [toc](./)        

< [The FPGA](fpga.md)

