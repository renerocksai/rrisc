----------------------------------------------------------------------------------
--
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

-- we will run the following program in our fake ram:
--
--    org 0
--    lda #$ca
--    sta data
--    ldb data
--    :loop_forever
--    jmp loop_forever
--    :data
--    db $ff
-- 
-- This translates to:
--     0a ca 00 09 0c 00 10 0c  00 02 09 00 ff

entity core_tb is
--  Port ( );
end core_tb;

architecture Behavioral of core_tb is
    component ram is
        port(
        -- reset and clock
        rst         :   IN    std_logic;    -- RESET
        clk         :   IN    std_logic;    -- clock

        ram_ld_val  :   IN   std_logic_vector (7 downto 0);
        write       :   IN   std_logic;
        addr        :   IN   std_logic_vector (4 downto 0);
        ram_out     :   OUT  std_logic_vector (7 downto 0)
    );
    end component ram;
    
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

    signal    rst           :  std_logic;    -- RESET
    signal    clk           :  std_logic;    -- clock
    signal    ram_ld_val    :  std_logic_vector (7 downto 0);
    signal    ram_write     :  std_logic;
    signal    ram_port_addr :  std_logic_vector (4 downto 0);
    signal    ram_out       :  std_logic_vector (7 downto 0);

    signal    reg_ld_val    :  std_logic_vector (7 downto 0);
    signal    reg_write     :  std_logic;
    signal    reg_sel       :  std_logic_vector (2 downto 0);
    signal    reg_out       :  std_logic_vector (7 downto 0);

    signal    pc_load       :  std_logic;
    signal    pc_clock      :  std_logic;
    signal    pc_ld_val     :  std_logic_vector (15 downto 0);
    signal    pc_addr       :  std_logic_vector (15 downto 0);

begin

    iram : ram port map (
        rst => rst,
        clk => clk,
        ram_ld_val => ram_ld_val,
        write => ram_write,
        addr => ram_port_addr,
        ram_out => ram_out
    );

    iregs : registers port map (
        rst => rst,
        clk => clk,
        reg_ld_val => reg_ld_val,
        reg_clock => reg_write,
        reg_sel => reg_sel,
        reg_value => reg_out
    );

    ipc : pmem port map (
        rst => rst, 
        clk => clk,
        pc_load => pc_load,
        pc_clock => pc_clock,
        pc_ld_val => pc_ld_val,
        pc_addr => pc_addr
    );

    -- concurrent stuff
    clk <= not clk after 5 ns ; -- gives us 10ns per cycle

    rst <= '1' after 0 ns, 
           '0' after 10 ns,
           '1' after 100 ns;
end Behavioral;
