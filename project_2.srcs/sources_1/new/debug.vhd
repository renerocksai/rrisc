----------------------------------------------------------------------------------
-- 
-- Engineer: Rene Schallner
-- 
-- Create Date: 12/29/2020 
-- Description: global debug symbols
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package debug is
    type regs_t is array (0 to 6) of std_logic_vector (7 downto 0);
    type mem_t is array (0 to 63) of std_logic_vector (7 downto 0);
    signal debug_regs : regs_t ;
    signal debug_mem : mem_t ;
    type state_t is (wakeup, ram_wait_1, fetch_1, ram_wait_2, fetch_2, ram_wait_3, fetch_3, decode, execute);
    signal debug_cpu_state, debug_cpu_nxstate : state_t;

    signal debug_inr1 : std_logic_vector (7 downto 0);
    signal debug_inr2 : std_logic_vector (7 downto 0);
    signal debug_inr3 : std_logic_vector (7 downto 0);

    signal debug_alu_eq, debug_alu_gt, debug_alu_sm : std_logic;
    signal debug_alu_A, debug_alu_B, debug_alu_I, debug_alu_F : std_logic_vector(7 downto 0);

    procedure show_regs;
    procedure show_iregs;
    procedure show_regs_and_alu;
end package debug;

package body debug is
    procedure show_regs is
    begin
        report "*** Registers: ***";
        report "     A: " & integer'image(to_integer(unsigned(debug_regs(0)))) ;
        report "     B: " & integer'image(to_integer(unsigned(debug_regs(1)))) ;
        report "     C: " & integer'image(to_integer(unsigned(debug_regs(2)))) ;
        report "     D: " & integer'image(to_integer(unsigned(debug_regs(3)))) ;
        report "     E: " & integer'image(to_integer(unsigned(debug_regs(4)))) ;
        report "     F: " & integer'image(to_integer(unsigned(debug_regs(5)))) ;
        report "     G: " & integer'image(to_integer(unsigned(debug_regs(6)))) ;
    end show_regs;


    procedure show_iregs is
    begin
        report "*** Instruction Registers: ***";
        report "     INR1: " & integer'image(to_integer(unsigned(debug_inr1))) ;
        report "     INR2: " & integer'image(to_integer(unsigned(debug_inr2))) ;
        report "     INR3: " & integer'image(to_integer(unsigned(debug_inr3))) ;
    end show_iregs;

    procedure show_regs_and_alu is
    begin
        report "*** Registers: ***";
        report "     A: " & integer'image(to_integer(unsigned(debug_regs(0)))) ;
        report "     B: " & integer'image(to_integer(unsigned(debug_regs(1)))) ;
        report "     C: " & integer'image(to_integer(unsigned(debug_regs(2)))) ;
        report "     D: " & integer'image(to_integer(unsigned(debug_regs(3)))) ;
        report "     E: " & integer'image(to_integer(unsigned(debug_regs(4)))) ;
        report "     F: " & integer'image(to_integer(unsigned(debug_regs(5)))) ;
        report "     G: " & integer'image(to_integer(unsigned(debug_regs(6)))) ;
        report "ALU_A : " & integer'image(to_integer(unsigned(debug_alu_A))) ;
        report "ALU_B : " & integer'image(to_integer(unsigned(debug_alu_B))) ;
        report "ALU_I : " & integer'image(to_integer(unsigned(debug_alu_I))) ;
        report "ALU_F : " & integer'image(to_integer(unsigned(debug_alu_F))) ;
        report "   EQ : " & std_logic'image(debug_alu_eq) ;
        report "   GT : " & std_logic'image(debug_alu_gt) ;
        report "   SM : " & std_logic'image(debug_alu_sm) ;
    end show_regs_and_alu;
end package body;

