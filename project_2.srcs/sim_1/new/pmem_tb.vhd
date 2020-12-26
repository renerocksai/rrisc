----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/26/2020 01:11:36 PM
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pmem_tb is
--  Port ( );
end pmem_tb;

architecture Behavioral of pmem_tb is
    component pmem is
      port (
        -- reset and clock
        rst         :   IN    std_logic;    -- RESET
        clk         :   IN    std_logic;    -- clock

        pc_load     :   IN    std_logic;
        pc_clock    :   IN    std_logic;
        pc_ld_val   :   IN    std_logic_vector (15 downto 0);

        pc_addr     :   OUT   std_logic_vector (15 downto 0)
    );
    end component pmem;

    signal rst, clk, pc_load, pc_clock : std_logic := '0';
    signal pc_ld_val, pc_addr : std_logic_vector (15 downto 0);

    constant load_value : std_logic_vector(15 downto 0) := "1111111111111000";

begin

    pc : pmem port map (
                           rst => rst, 
                           clk => clk,
                           pc_load => pc_load,
                           pc_clock => pc_clock,
                           pc_ld_val => pc_ld_val,
                           pc_addr => pc_addr
                       );
    -- concurrent stuff, stimuli
    pc_ld_val <= load_value;

    clk <= not clk after 1 ns;

    rst <= '1' after 0 ns, 
           '0' after 10 ns,
           '1' after 100 ns;
    
    -- counter is out of reset from ns 10 .. 99
    pc_clock <= '1' after 15 ns,
                '0' after 16 ns,
                '1' after 25 ns,
                '0' after 26 ns,
                '1' after 35 ns,
                '0' after 36 ns;

    pc_load <= '0' after 1 ns, 
               '1' after 51 ns,
               '0' after 52 ns;

    process
    begin
        wait for 1 ns;
        assert pc_addr = "0000000000000000" report "Counter not zero at reset" severity ERROR;

        wait for 16 ns;
        assert pc_addr = "0000000000000001" report "Counter not 1 after 1 clock" severity ERROR;

        wait for 10 ns;
        assert pc_addr = "0000000000000010" report "Counter not 2 after 2 clock" severity ERROR;

        wait for 10 ns;
        assert pc_addr = "0000000000000011" report "Counter not 3 after 3 clock" severity ERROR;


        wait for 22 ns;
        assert pc_addr = load_value report "Counter not loaded" severity ERROR;


    wait for 1 ns;
    assert false report "FINISHED OK" severity ERROR;
    wait;
    end process;
end Behavioral;
