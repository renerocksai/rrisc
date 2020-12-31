# 4. It's executing the whole test program!!!

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

As you can see below, both registers contain the value $CA and the program counter falling back to $0009 after reaching $000B.

The red vertical line marks the time of the first jump.

![image](https://user-images.githubusercontent.com/30892199/103299193-4699c180-49fc-11eb-9313-7a4d1407bb4b.png)

Zooming in to the first jump:

![image](https://user-images.githubusercontent.com/30892199/103298890-94fa9080-49fb-11eb-90dd-5c4e36a62733.png)

Et voila! The CPU works as expected :-)


---
^ [toc](https://github.com/renerocksai/rrisc/blob/main/_main.md)        

< [It's executing its first instruction](https://github.com/renerocksai/rrisc/blob/main/_firstinstr.md)

\> [We have an ALU](https://github.com/renerocksai/rrisc/blob/main/_alu.md)

