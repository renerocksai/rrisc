- [x] macros 
    - with parameters
    - internal labels will be postfixed with instantiation counter
- [x] binary output

```
MACRODEF macroname
text
text @1
:@localaddr
jmp @localaddr
ENDMACRO

; @1 will be substituted for first param
MACRO  macronane 27 ; $1 will be replaced by 27
```
