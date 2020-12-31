# 6. Vim, tmux, ghdl & gtkwave workflow

Via ssh. On a Chromebook :)

It's super smooth, editing VHDL in vim (neovim), running ghdl in a separate tmux pane via vim-tmux, and using gtkwave to view the waveforms of the simulation. Textual simulation output and logging can be viewed as ghdl's output. I prefer this super quick 1-keystroke way of running my testbenches, compared to the sluggish Vivado GUI workflow. 

As an extra plus, vim and commandline work smoothly over ssh. With X-forwarding enabled, gtkwave works via ssh, too.
![image](https://user-images.githubusercontent.com/30892199/103270890-4debab80-49b9-11eb-8c8a-1308093d7b4c.png)

![image](https://user-images.githubusercontent.com/30892199/103263325-d2353300-49a7-11eb-8fa0-b168ecc6ae0d.png)
![image](https://user-images.githubusercontent.com/30892199/103263490-55568900-49a8-11eb-9b65-84b423a1a7b3.png)

While all that software runs in the Linux container of my Chromebook, too, I got used to the habit of SSH-ing into my stationary Linux box, making it my main devlopment machine. So when I'm not at my desk, I use my Chromebook to attach to the tmux session of the PC and seemlessly continue work there.

---
^ [toc](https://github.com/renerocksai/rrisc/blob/main/_main.md)        

< [Radical RISC from the early nineties](https://github.com/renerocksai/rrisc/blob/main/_nineties.md)

\> [The FPGA](https://github.com/renerocksai/rrisc/blob/main/_fpga.md)

