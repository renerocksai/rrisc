
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

entity registers is
    port(
    reg_ld_val  :   IN   std_logic_vector (7 downto 0);
    reg_clock   :   IN   std_logic;
    reg_sel     :   IN   std_logic_vector (3 downto 0);
    reg_value   :   OUT  std_logic_vector (7 downto 0);
);

architecture Behavioral of registers is
    -- signals
    signal regs : array (0 to 6) of std_logic_vector (7 downto 0);
    constant zero  : unsigned (7 downto 0) := (others => '0');

begin
    regproc : process (rst, clk)
    begin
        if rst = '1' then
            reg_value <= zero;
        elsif rising_edge(clk) then
            if reg_clock = '1' then
                regs(unsigned(reg_sel - 1)) <= reg_ld_val;
            end if;
        end if;
    end process regproc;

    reg_value <= regs(unsigned(reg_sel));
end Behavioral;
