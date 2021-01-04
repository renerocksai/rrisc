# What's unique about RRISC:

- the instruction set is truly minimal:
  - load register from RAM / IO port / immediately
  - store register to RAM / IO port
  - jump
- there is no stack!
- all instructions take exactly 8 clock cycles, enabling easy deterministic timing behavior
- ALL instructions can be executed conditionally
    - e.g. `LDA #$00 : EQ` will clear register A only if the EQUAL flag is set
    - this reduces the need for conditional jumps
- the ALU is intended to be port mapped:
  - making the CPU independent from a specific ALU allows for upgradability
  - see example below for adding:
- an interesting indirect jump mode:
  - `jmp HI[LO]`  will jump to HI * 256 + [HI * 256 + LO]
  - HIGH byte is specified directly
  - LOW byte is read from memory at address HI * 256 + LO
  - this allows for jmp tables
- above jumps can also be indirected by external port data:
  - `jmpp HI[LO]` will take the LOW byte of the address from **port** HI*256+LO

Example of using the port-mapped ALU to add two values:

```
     lda #value1          ; first value to add
     out a, ALU_OPERAND1  ; --> into ALU register
     lda #value2          ; second value to add
     out a, ALU_OPERAND2  ; --> into ALU
     lda #ALU_ADD         ; add command
     out a, ALU_CMD       ; --> into ALU
     in a, ALU_RESULT     ; read result
```

---

^ [toc](./)        

< [Radical RISC from the early nineties](nineties.md)

\> [It's executing its first instruction](firstinstr.md)
