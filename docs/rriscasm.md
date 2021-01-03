# RRISC Assebmly - introduction

The RRISC CPU can address the following:

- the 16bit program counter 
- 7 registers (A..G) 
- 64k of RAM
- 64k port addresses


## Basic commands

The RRISC CPU understands the following basic commands, that are all based on the read / write principle:

- LD _register_
- ST _register_
- JMP _address_

`LD` stands for _load_ and is used for loading values into a register _reg_.

`ST` stands for _store_ and is used for writing the value of a register to the RAM (or external ports).

Each of the above commands causes a transaction between elements of two groups: The first group consists of the 7 registers and the second group is is comprised of RAM, ports and instruction register 2 ('operand' of the instruction).

The following types of transactions are valid:

- register ---> RAM
- register ---> port
- register <--- RAM
- register <--- port
- register <--- operand (instruction register 2)

`JMP` stans for _jump_ and is used to continue program execution at a defined address. Strictly speaking, a jump is nothing else but an `LD` of the program counter - but because of its side effect, it is considered a distinct command.

`LD` and `ST` can be applied to 7 registers. The registers are named A, B, C, D, E, F, G.

---

## Conditions
In addition, **all** commands can be executed under four different conditions:

- unconditional : instruction is always executed
- EQ (equal) : instruction is executed if the ALU's EQ/zero flag is set
- GT (greater than) : instruction is executed if the ALU's GT/carry flag is set
- LT (less than) : instruction is executed if the ALU's LT flag is set

The [ALU](alu.md) is the CPU's arithmetic logical unit, and used to perform calculations and comparisons. The result of an ALU operation can be non-numerical, e.g. in a comparison operation. In that case, above-mentioned ALU flags are set instead. 

---

## Adressing modes

The RRISC CPU has the following addressing modes:

- immediate: loading a constant directly into a register or the program counter (jump)
- absolute : the source or destination is an address in memory
- external : the source or destination is a port address
- indirect : the source or destination address has a constant high byte, but the low byte will be fetched from RAM / port at the given address

### Immediate addressing mode

This is the simplest of them all. A register is loaded with an immediate value, a constant specified by the programmer. 

Example: `LDA # $01` - loads the value `$01` into register A

### Absolute addressing mode

In absolute addressing mode, the operand is a 16-bit address to the RAM.

Examples:

```
LDA $1300   ; load byte from RAM at address $1300
STA $1301   ; store byte into RAM at address $1301
```

### External addressing mode

In external addressing mode, the operand is a 16-bit address of an external port. External ports are used to communicate with periphery. In our case, the ALU is external periphery.

Examples:

```
IN A,  $0000   ; read from port 0
OUT A, $0001   ; write to port 1
```

### Indirect addressing mode

This mode is only applicable to `JMP`. It involves an indirection and is both interesting and also a bit more complicated. Indirect addressing can be used for both RAM and port access. It is best described by example:

Consider `JMP $1300` - here the address is `1300` and can be split into a HIGH byte `$13` and a LOW byte `$00`. The 16-bit address `$1300` can be calculated from HIGH and LOW bytes as follows:

```
addr = HIGH * 256 + LOW
```

In _indirect_ mode addressing, we write the instruction:

```
JMP $13[$00]  ; HIGH[LOW]
```

... and calculate the address as follows:


```
temp_addr := $1300
LOW := byte at address $1300
HIGH:= $13

addr = HIGH * 256 +LOW
```

So first we look up the LOW byte of the address at the given address and then use the HIGH byte and the new LOW byte as address.

We can write the address calculation without using a temporary, using square brackets as 'look into address' indirection operator:

```
addr = HIGH * 256 + [HIGH * 256 + LOW]
```

This mode can be used for jump tables.

---

## Assembler commands

Based on:

- read / write
- condition
- register / program counter
- addressing mode

the following assembler command set of the RRISC CPU is derived.

**Note:** the condition 'unconditional' is implicit. Unconditional commands do not have a condition clause.

Example:

```
lDA # $00         ; unconditional
LDA # $00 : EQ    ; only if EQ flag is set
```
---

### LD(_reg_) _Addr_ : _condition_
Loads register _reg_ with the RAM contents at address _addr_ if the given condition is true.

Example:

```
LDA $1300   ; loads A with value at $1300
``` 

---

### ST(_reg_) _Addr_ : _condition_
Stores value of register _reg_ into RAM at address _addr_ if the given condition is true.

Example:

```
STA $1300   ; stores a into RAM at $1300
```

---


### LD(_reg_) # _val_ : _condition_
Loads the value _val_ into register _reg_ if the given condition is true.

Example:

```
LDA # $00   ; loads A with value $00
``` 

---

### IN _reg_, _port_ : _condition_
Loads the value at external port _port_ into register _reg_ if the given condition is true.

Examole:

```
IN A, $0003 ; read from port 3
```

---

### OUT _reg_, _port_ : _condition_
Writes the value of register _reg_ to external port _port_ if the given condition is true.

Example:

```
OUT A, $05 ; write to port 5
```

---

### JMP _addr_ : _condition_
Jump to address _addr_ if the given condition is true.

Example:

```
JMP $C000 : EQ ; if equal, jump to $c000
```

---

### JMP HI[LO] : _condition_
Jump to RAM address HI * 256 + [HI * 256 + LO] if the given condition is true.

Example:

```
JMP $C0[00] : EQ ; if equal, jump to $c000 + [$c0000]
```

---

### JMPP HI[LO] : _condition_
Jump to address HI * 256 + ports[HI * 256 + LO] if the given condition is true. The difference to `JMP` is that here the LO byte is read from the specified port.

Example:

```
JMPP $C0[$00] : EQ ; if equal, jump to $c000 + port[$c000]
```

---

^ [toc](./)        

< [It's executing its first instruction](firstinstr.md)

\> [RRISC Assembler - writing programs](asm.md)


