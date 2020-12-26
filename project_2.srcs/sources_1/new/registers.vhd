
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
    -- signals
    type regs_t is array (0 to 6) of std_logic_vector (7 downto 0);
    signal regs : regs_t;
    constant zero : std_logic_vector(7 downto 0) := "00000000";

begin
    regproc : process (rst, clk)
    begin
        if rst = '1' then
            reg_value <= zero;
        elsif rising_edge(clk) then
            if reg_clock = '1' then
                regs(to_integer(unsigned(reg_sel)-1)) <= reg_ld_val;
            end if;
        end if;
    end process regproc;

    reg_value <= regs(to_integer(unsigned(reg_sel)-1));
end Behavioral;
