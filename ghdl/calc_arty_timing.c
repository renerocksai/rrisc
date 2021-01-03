#include <stdio.h>

int main(){
    unsigned char  artylo = 0xda;
    unsigned char  artyhi = 0x10; 
    unsigned char  paramlo = 0xca;
    unsigned char  paramhi = 0x01;

    unsigned int ret = 0;
    unsigned char c,d,e,f;

    f = paramlo;
    e = paramhi;
loop_delay:
    ret += 2;
    d = artylo;
    c = artyhi;
loop_low:
    d--;
    ret += 6;
    if(d == 0) goto break_low;
    goto loop_low;
break_low:
    ret += 4;
    c--;
    if(c==0) goto break_high;
    goto loop_low;
break_high:
    ret +=4;
    f--;
    if (f==0) goto break_param_hi;
    goto loop_delay;
break_param_hi:
    ret += 4;
    e--;
    if(e==0) goto end;
    goto loop_delay;
end:
    printf("%u\n", ret);
    printf("%f\n", ret * 80e-9);
   return 0; 
}
