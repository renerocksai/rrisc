# It's executing the whole test program!!!

The test program:

![](simtest.asm.png)

What we expect after running this:
- Both registers A and B containing the value $CA
  - that means writing to and reading from RAM works
- The program counter being set to address $0009 (where the jump is) as the jump instruction is executed
  - hence, the instruction repeating itself
  - instead of the program counter incrementing past address $000B

As you can see below, both registers contain the value $CA and the program counter falling back to $0009 after reaching $000B.

The red vertical line marks the time of the first jump.

![image](https://user-images.githubusercontent.com/30892199/103299193-4699c180-49fc-11eb-9313-7a4d1407bb4b.png)

Zooming in to the first jump:

![image](https://user-images.githubusercontent.com/30892199/103298890-94fa9080-49fb-11eb-90dd-5c4e36a62733.png)

Et voila! The CPU works as expected :-)


---
^ [toc](./)        

< [RRISC Assembler - writing programs](asm.md)

\> [We have an ALU](alu.md)

