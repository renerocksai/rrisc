----------------------------------------------------------------------------------
-- 
-- Engineer: Rene Schallner
-- 
-- Create Date: 12/21/2020 05:25:12 PM
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- debug stuff
use work.debug.ALL;

entity registers is
    port(
    -- reset and clock
    rst         :   IN    std_logic;    -- RESET
    clk         :   IN    std_logic;    -- clock

    reg_ld_val  :   IN   std_logic_vector (7 downto 0);
    reg_clock   :   IN   std_logic;
    reg_sel     :   IN   std_logic_vector (2 downto 0);
    reg_value   :   OUT  std_logic_vector (7 downto 0)
);
end registers;

architecture Behavioral of registers is
    type regs_t is array (0 to 6) of std_logic_vector (7 downto 0);

    -- signals
    signal regs : regs_t := (
        "10101010",
        "10101010",
        "10101010",
        "10101010",
        "10101010",
        "10101010",
        "10101010"
    );
    signal sel : std_logic_vector (2 downto 0) := "001";
    signal myval : std_logic_vector (7 downto 0) := "11111111";

    constant zero : std_logic_vector(7 downto 0) := "00000000";

begin
    regproc : process (rst, clk)
    begin
        if rst = '1' then
            myval <= zero;
        elsif rising_edge(clk) then
            if reg_clock = '1' then
                regs(to_integer(unsigned(sel)-1)) <= reg_ld_val;
                myval <= reg_ld_val;
                report "> reg " & integer'image(to_integer(unsigned(sel))) & " : " & integer'image(to_integer(unsigned(reg_ld_val))) ;
            else
                myval <= regs(to_integer(unsigned(sel)-1));
            end if;
        end if;
    end process regproc;

    selproc : process (reg_sel)
    begin
        case reg_sel is
            when "000" => sel <= "001";
            when others => 
                sel <= reg_sel;
                report "< reg " & integer'image(to_integer(unsigned(sel))) & " : " & integer'image(to_integer(unsigned(regs(to_integer(unsigned(sel)-1))))) ;
        end case;
    end process selproc;

    -- concurrent stuff
    reg_value <= myval;

    -- debug
    debug_regs(0) <= regs(0);
    debug_regs(1) <= regs(1);
    debug_regs(2) <= regs(2);
    debug_regs(3) <= regs(3);
    debug_regs(4) <= regs(4);
    debug_regs(5) <= regs(5);
    debug_regs(6) <= regs(6);
 
end Behavioral;
