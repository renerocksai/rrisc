----------------------------------------------------------------------------------
-- 
-- Engineer: Rene Schallner
-- 
-- Create Date: 12/25/2020 12:37:32 PM
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- debug stuff
use work.debug.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    port (
           clk      	: in  STD_LOGIC;    -- configured to 100 MHz

           sw 			: in  STD_LOGIC_VECTOR (3 downto 0);
           btn 			: in  STD_LOGIC_VECTOR (3 downto 0);
           led 			: out  STD_LOGIC_VECTOR (3 downto 0);
       );
end top;

architecture Behavioral of top is

    component test_ram is
        port(
            -- reset and clock
            rst         :   IN    std_logic;    -- RESET
            clk         :   IN    std_logic;    -- clock

            ram_ld_val  :   IN   std_logic_vector (7 downto 0);
            write       :   IN   std_logic;
            addr        :   IN   std_logic_vector (5 downto 0);
            ram_out     :   OUT  std_logic_vector (7 downto 0)
        );
    end component test_ram;
    
    component cpu is
        Port (
            -- reset and clock
            rst         :   IN    std_logic;    -- RESET
            clk         :   IN    std_logic;    -- clock

            -- memory bus
            ram_out       :   IN    std_logic_vector (7 downto 0);
            ram_ld_value  :   OUT   std_logic_vector (7 downto 0);
            ram_port_addr :   OUT   std_logic_vector (15 downto 0);
            ram_write     :   OUT   std_logic;

            -- port bus
            port_ld_value :   OUT   std_logic_vector (7 downto 0);
            port_write    :   OUT   std_logic;
            port_out      :   IN    std_logic_vector (7 downto 0)
        );
    end component cpu;

    signal    rst           :  std_logic := '1';    -- RESET
    signal    ram_ld_val    :  std_logic_vector (7 downto 0);
    signal    ram_write     :  std_logic;
    signal    ram_port_addr :  std_logic_vector (15 downto 0);
    signal    ram_addr :  std_logic_vector (5 downto 0);
    signal    ram_out       :  std_logic_vector (7 downto 0);

    signal    port_ld_value : std_logic_vector (7 downto 0) := "00000000";
    signal    port_out : std_logic_vector (7 downto 0) := "00000000";
    signal    port_write : std_logic;

    -- 100,000,000 * 0.002 = 200,000 = clk cycles per 2 ms
    constant RESET_CNTR_MAX : std_logic_vector(17 downto 0) := "110000110101000000";
    signal reset_cntr : std_logic_vector (17 downto 0) := (others=>'0');

begin
    iram : test_ram port map (
        rst => rst,
        clk => clk,
        ram_ld_val => ram_ld_val,
        write => ram_write,
        addr => ram_addr,
        ram_out => ram_out
    );

    icpu : cpu port map (
        rst => rst,
        clk => clk,

        -- memory bus
        ram_out       => ram_out,
        ram_ld_value  => ram_ld_val,
        ram_port_addr => ram_port_addr,
        ram_write     => ram_write,

        -- port bus
        port_ld_value => port_ld_value,
        port_write    => port_write,
        port_out      => port_out
    );

    -- concurrent stuff
    ram_addr <= ram_port_addr(5 downto 0);
    rst <= '0' when reset_cntr = RESET_CNTR_MAX else '1';

    clkrst : process(clk)
    begin
      if (rising_edge(clk)) then
        if reset_cntr = RESET_CNTR_MAX then
            null  -- stay there
        else
          reset_cntr <= reset_cntr + 1;
        end if;
      end if;
    end process;

    artyports : process(clk, s_ram_port_addr, s_port_ld_value, s_port_out, s_port_write)
    begin
        if rising_edge(clk) then
            if s_port_write = '0' then
                case s_ram_port_addr is
                    when "1111111111111000" =>
                        s_port_out < "0000" & btn(3 downto 0);
                    when "1111111111111001" =>
                        s_port_out < "0000" & sw(3 downto 0);
                    when others => null;
                end case;
            else
                case s_ram_port_addr is
                    when "1111111111111010" =>
                        led <= s_port_ld_value(3 downto 0);
                    when others => null;
                end case;
            end if;
        end if;
    end process artyports;
end Behavioral;
