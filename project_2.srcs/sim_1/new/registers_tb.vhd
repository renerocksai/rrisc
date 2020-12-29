----------------------------------------------------------------------------------
-- Engineer: Rene Schallner
-- 
-- Create Date: 12/26/2020 01:11:36 PM
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- debug stuff
use work.debug.ALL;

entity registers_tb is
--  Port ( );
end registers_tb;

architecture Behavioral of registers_tb is
    component registers is
        port(
        -- reset and clock
        rst         :   IN    std_logic;    -- RESET
        clk         :   IN    std_logic;    -- clock

        reg_ld_val  :   IN   std_logic_vector (7 downto 0);
        reg_clock   :   IN   std_logic;
        reg_sel     :   IN   std_logic_vector (2 downto 0);
        reg_value   :   OUT  std_logic_vector (7 downto 0)
    );
    end component registers;

    signal rst, clk, reg_clk : std_logic := '0';
    signal reg_ld_val : std_logic_vector (7 downto 0) := "00000000";
    signal reg_value : std_logic_vector (7 downto 0);
    signal reg_sel : std_logic_vector(2 downto 0) := "000";
begin

    regs : registers port map (
                                rst => rst,
                                clk => clk,
                                reg_ld_val => reg_ld_val,
                                reg_clock => reg_clk,
                                reg_sel => reg_sel,
                                reg_value => reg_value
                              );

    -- concurrent stuff
    clk <= not clk after 5 ns ; -- gives us 10ns per cycle

    rst <= '1' after 0 ns, 
           '0' after 10 ns,
           '1' after 100 ns;

    process
    begin
        wait for 5 ns;
        reg_ld_val <= "00001111";
        reg_sel <= "001";   -- first reg! reg 0 would be PC
        reg_clk <= '1';
        wait for 10 ns;

        -- switch to initialized, unwritten reg
        reg_clk <= '0';
        reg_sel <= "100";
        wait for 15 ns;
        assert reg_value = "10101010" report "reg value not right after switching: " & integer'image(to_integer(unsigned(reg_value))) severity ERROR;

        -- switch back to reg we have written to
        reg_sel <= "001";   -- first reg! reg 0 would be PC
        wait for 10 ns;
        assert reg_value = "00001111" report "reg value not set after write, is " & integer'image(to_integer(unsigned(reg_value))) severity ERROR;

        wait for 10 ns;
        show_regs;

        assert false report "FINISHED OK" severity ERROR;
        wait;
    end process;

end Behavioral;
