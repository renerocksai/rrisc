# Background and why I built the RRISC CPU

In the early nineties, when I finally figured out how to do sequential digital circuits, I used the momentum of that heureka-moment to develop the [RRISC](https://github.com/renerocksai/rrisc#btw-whats-so-special-about-rrisc) CPU (Radically Reduced Instruction Set Computer), with the intention to build it using just 74xx TTL logic circuits. It was meant both as an educational and also instructive endeavor, as I figured such a simple CPU would be ideal for teaching the basics of CPU design. Being able to make an actual CPU from just two easy-to-build printed circuit boards would also free the whole topic from being a merely abstract one. If you put a bit of extra work in, you could actually see the CPU work.

After having drawn schematics, printed circuit boards, (and done it all again in P-CAD later), timing diagrams, and implementing an assembler and simulator in Turbo Pascal, I got to play around with the CPU only in the self-written simulator, displaying all CPU states and fancy 7-segment displays in DOS. 

Despite all my intentions, I never got around to actually build it. Part of what was stopping me was that I had no EPROM programmer for writing programs into an EPROM that I would then insert into the CPU board to give the CPU something to execute. Eventhough I designed a cool battery powered SRAM module with PC printer interface (there was no USB back then, on my 80386 PC!), which would eliminate the need for EPROMs, I never got to build that either. Instead I focused on replacing the EPROM containing the CPU microcode by a GAL, my first step towards using programmable logic. 

*This is what an EPROM programmer looked like in the nineties*

![image](https://user-images.githubusercontent.com/30892199/103368450-d7899f00-4ac7-11eb-903b-15f925cf28bb.png)

*On top of that, to erase an EPROM, you would need an UV light source and point it at the glass window of the IC:*

![image](https://user-images.githubusercontent.com/30892199/103368626-55e64100-4ac8-11eb-98c0-607b7c547336.png)

![image](https://user-images.githubusercontent.com/30892199/103368907-12400700-4ac9-11eb-9f63-73362f86b3ee.png)


This lead me down the path of minimizing combinatorial digital logic circuits (Quine McCluskey anyone?), creating CAD files for automating production of minimized circuits, ... Which all developed a life of its own, until I was past mere CPU design - I knew it worked, which was almost as good as seeing it work. And I moved on. 

30 years ago I went to school and had no money. I thought then, one day when I earn money, I'll get myself all the parts and programmers I need and build my CPU then. Which I almost forgot. Until now.

So, this Christmas, I thought I would revive the 30 years old project, but this time implement the CPU in VHDL so I can program an FPGA with it in order to get my CPU up and running in the physical world.

