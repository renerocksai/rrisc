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

---
^ [toc](./)        

< [What's unique about the RRISC CPU](rrisc.md)

\> [RRISC Assembly - introduction](rriscasm.md)
