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
           led 			: out  STD_LOGIC_VECTOR (3 downto 0)
       );
end top;

architecture Behavioral of top is

    component ram is
        port(
            -- reset and clock
            rst         :   IN    std_logic;    -- RESET
            clk         :   IN    std_logic;    -- clock

            ram_ld_val  :   IN   std_logic_vector (7 downto 0);
            write       :   IN   std_logic;
            addr        :   IN   std_logic_vector (15 downto 0);
            ram_out     :   OUT  std_logic_vector (7 downto 0)
        );
    end component ram;

    component alu is
        port(
        -- clock
        clk               :   IN    std_logic;    
        -- operands
        A_in, B_in        :   IN    std_logic_vector(7 downto 0);
        -- operation
        I                 :   IN    std_logic_vector(7 downto 0);
        -- flags
        cout_gt           :   OUT   std_logic;
        sign              :   OUT   std_logic;
        zero_equal        :   OUT   std_logic;
        sm                :   OUT   std_logic;
        -- result
        F                 :   out   std_logic_vector(7 downto 0)
    );
    end component;
    
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
            port_out      :   IN    std_logic_vector (7 downto 0);

            -- ALU flags
            alu_eq        :   IN    std_logic;
            alu_gt        :   IN    std_logic;
            alu_sm        :   IN    std_logic
        );
    end component cpu;

    signal    rst           :  std_logic := '0';    -- RESET

    signal    s_ram_ld_val    :  std_logic_vector (7 downto 0);
    signal    s_ram_write     :  std_logic;
    signal    s_ram_port_addr :  std_logic_vector (15 downto 0);
    signal    s_ram_out       :  std_logic_vector (7 downto 0);

    signal    s_port_ld_value : std_logic_vector (7 downto 0) := "00000000";
    signal    s_port_out : std_logic_vector (7 downto 0) := "00000000";
    signal    s_port_write : std_logic;

    signal    s_ram_addr :  std_logic_vector (15 downto 0);

    signal alu_A : std_logic_vector (7 downto 0) := "00000000";
    signal alu_B : std_logic_vector (7 downto 0) := "01111111";  -- make A != B initially
    signal alu_I : std_logic_vector (7 downto 0) := "00000000";
    signal alu_eq, alu_gt, alu_sm : std_logic := '0';
    signal alu_F : std_logic_vector (7 downto 0) := "00000000";

    -- 100,000,000 * 0.002 = 200,000 = clk cycles per 2 ms
    constant RESET_CNTR_MAX : unsigned(17 downto 0) := "110000110101000000";
    signal reset_cntr : unsigned(17 downto 0) := (others=>'0');
    signal s_leds : std_logic_vector(3 downto 0) := "1111";

begin
    iram : ram port map (
        rst => rst,
        clk => clk,
        ram_ld_val => s_ram_ld_val,
        write => s_ram_write,
        addr => s_ram_addr,
        ram_out => s_ram_out
    );

    ialu : alu port map (
        clk        =>   clk,
        A_in       =>   alu_A,
        B_in       =>   alu_B,
        I          =>   alu_I,
        cout_gt    =>   alu_gt,
        zero_equal =>   alu_eq,
        sm         =>   alu_sm,
        F          =>   alu_F
    );

    icpu : cpu port map (
        rst => rst,
        clk => clk,

        -- memory bus
        ram_out       => s_ram_out,
        ram_ld_value  => s_ram_ld_val,
        ram_port_addr => s_ram_port_addr,
        ram_write     => s_ram_write,

        -- port bus
        port_ld_value => s_port_ld_value,
        port_write    => s_port_write,
        port_out      => s_port_out,

        alu_gt    =>   alu_gt,
        alu_eq =>   alu_eq,
        alu_sm         =>   alu_sm
    );

    -- concurrent stuff
    s_ram_addr <= s_ram_port_addr(15  downto 0);
    rst <= '0' when reset_cntr = RESET_CNTR_MAX else '1';
--    led(2) <= '0' when reset_cntr = RESET_CNTR_MAX else '1';
--    led(3) <= '1' when reset_cntr = RESET_CNTR_MAX else '0';
    
    -- led <= "0101";
    led <= s_leds;
    
    clkrst : process(clk)
    begin
      if (rising_edge(clk)) then
        if reset_cntr = RESET_CNTR_MAX then
            null;  -- stay there
        else
          reset_cntr <= reset_cntr + 1;
        end if;
      end if;
    end process;

    ports : process(clk, s_ram_port_addr, s_port_ld_value, s_port_write)
    begin
        if rising_edge(clk) then
            if s_port_write = '1' then
                case s_ram_port_addr is
                    when "1111111111111010" =>
                        s_leds <= s_port_ld_value(3 downto 0);
                        report " ******* LEDS: " & integer'image(to_integer(unsigned(s_port_ld_value)));
                    when "1111111111111100" =>
                        alu_A <= s_port_ld_value;
                    when "1111111111111101" =>
                        alu_B <= s_port_ld_value;
                    when "1111111111111110" =>
                        alu_I <= s_port_ld_value;
                    when others => null;
                end case;
            else
                case s_ram_port_addr is
                    when "1111111111111000" =>
                        s_port_out <= "0000" & btn(3 downto 0);
                    when "1111111111111001" =>
                        s_port_out <= "0000" & sw(3 downto 0);
                    when "1111111111111111" =>
                        report " ******* ALU RESULT: " & integer'image(to_integer(unsigned(alu_F)));
                        s_port_out <= alu_F;
                    when others => null;
                end case;
            end if;
        end if;
    end process ports;
end Behavioral;
