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


