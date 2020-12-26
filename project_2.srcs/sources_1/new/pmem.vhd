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

entity pmem is
  port (
    -- reset and clock
    rst         :   IN    std_logic;    -- RESET
    clk         :   IN    std_logic;    -- clock

    pc_load     :   IN    std_logic;
    pc_clock    :   IN    std_logic;
    pc_ld_val   :   IN    std_logic;

    pc_addr     :   OUT   std_logic_vector (15 downto 0);
);
end pmem;

architecture Behavioral of pmem is
    signal counter : unsigned (15 downto 0);
    constant zero  : unsigned (15 downto 0) := (others => '0');
begin
    pc: process (rst, clk)
    begin
        if rst = '1' then 
            counter <= zero;
        elsif rising_edge(clk) then
            if pc_clock = '1' then
                counter <= counter + 1;
            elsif pc_load = '1' then
                counter <= unsigned(pc_ld_val);
        end if 
    end process pc;

    pc_addr <= std_logic_vector(counter);
end Behavioral;



