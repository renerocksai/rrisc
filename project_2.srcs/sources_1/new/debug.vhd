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
    signal debug_regs : regs_t ;

    procedure show_regs;
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
end package body;

