----------------------------------------------------------------------------------
--
-- Engineer: Rene Schallner
-- 
-- Create Date: 01/01/2021
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- debug stuff
use work.debug.ALL;

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is
    component top is
        port (
               clk      	: in  STD_LOGIC;    -- configured to 100 MHz

               sw 			: in  STD_LOGIC_VECTOR (3 downto 0);
               btn 			: in  STD_LOGIC_VECTOR (3 downto 0);
               led 			: out  STD_LOGIC_VECTOR (3 downto 0)
           );
    end component top;

    signal s_clk : std_logic := '0';
    signal s_sw : std_logic_vector (3 downto 0) := "0000";
    signal s_btn : std_logic_vector (3 downto 0) := "0000";
    signal s_led : std_logic_vector (3 downto 0) := "0000";

    signal cpustate : state_t;
    signal helper : std_logic := '0';
    signal cpureg_A : std_logic_vector (7 downto 0);
    signal cpureg_B : std_logic_vector (7 downto 0);
    signal cpureg_C : std_logic_vector (7 downto 0);
    signal cpureg_D : std_logic_vector (7 downto 0);
    signal cpureg_E : std_logic_vector (7 downto 0);
    signal cpureg_F : std_logic_vector (7 downto 0);
    signal cpureg_G : std_logic_vector (7 downto 0);

begin

    itop : top port map (
        clk => s_clk,
        sw => s_sw,
        btn => s_btn,
        led => s_led
    );

    -- concurrent stuff
    s_clk <= not s_clk after 5 ns;

    cpustate <= debug_cpu_state;
    cpureg_A <= debug_regs(0);
    cpureg_B <= debug_regs(1);
    cpureg_C <= debug_regs(2);
    cpureg_D <= debug_regs(3);
    cpureg_E <= debug_regs(4);
    cpureg_F <= debug_regs(5);
    cpureg_G <= debug_regs(6);

    process begin
        wait for 2 ms;
        wait for 10 ms;

        assert false report "stopping after 3 ms." severity ERROR;
    end process;

end Behavioral;

