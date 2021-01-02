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


entity core is
  Port (
    -- reset and clock
    rst           :   IN    std_logic;    -- RESET
    clk           :   IN    std_logic;    -- clock

    -- program counter
    pc_write      :   OUT   std_logic;
    pc_clock      :   OUT   std_logic; 
    pc_ld_val     :   OUT   std_logic_vector (15 downto 0);
    pc_addr       :   IN    std_logic_vector (15 downto 0);

    -- registers
    reg_ld_val    :   OUT   std_logic_vector (7 downto 0);
    reg_write     :   OUT   std_logic;
    reg_sel       :   OUT   std_logic_vector (2 downto 0);
    reg_out       :   IN    std_logic_vector (7 downto 0);
    
    -- ALU status: UC, EQ, GR, SM
    alu_eq        :   IN    std_logic;
    alu_gr        :   IN    std_logic;
    alu_sm        :   IN    std_logic;

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
end core;

architecture Behavioral of core is
    --type state_t is (ram_wait_1, fetch_1, ram_wait_2, fetch_2, ram_wait_3, fetch_3, decode, execute);
    signal state, nxstate : state_t;

    -- instruction registers
    signal inr1 : std_logic_vector (7 downto 0) := "00000000";
    signal inr2 : std_logic_vector (7 downto 0) := "00000000";
    signal inr3 : std_logic_vector (7 downto 0) := "00000000";

    -- signals without registers
    signal addr_mode : std_logic_vector (1 downto 0);
    signal condition : std_logic;
    signal selected_register : std_logic_vector(2 downto 0);

    signal data : std_logic_vector (7 downto 0) := "00000000";

    signal s_addr : std_logic_vector(15 downto 0) := "0000000000000000";
    signal s_pc_ld_val : std_logic_vector(15 downto 0) := "0000000000000000";
    signal s_ram_write : std_logic := '0';
    signal s_port_write : std_logic := '0';

    constant zero  : unsigned (7 downto 0) := (others => '0');

begin
    -- fsm state register
    fsm_reg: process(rst, clk)
    begin
        if (rst='1') then
            state <= wakeup;
        elsif rising_edge(clk) then
            state <= nxstate;
        end if;
    end process fsm_reg;

    -- next state logic for fsm
    fsm_next: process(state)
    begin
        case state is
            when wakeup     => nxstate <= ram_wait_1;     -- go out of reset gently
            when ram_wait_1 => nxstate <= fetch_1;        -- wait for RAM to output byte
            when fetch_1    => nxstate <= ram_wait_2;     -- clock data bus / ram into inr1 and increment PC
            when ram_wait_2 => nxstate <= fetch_2;        -- wait for RAM to output 2nd byte
            when fetch_2    => nxstate <= ram_wait_3;     -- clock data bus / ram into inr2 and increment PC
            when ram_wait_3 => nxstate <= fetch_3;        -- wait for RAM to output 3rd byte
            when fetch_3    => nxstate <= decode;         -- select data source, data destination and put them on data, address bus
            when decode     => nxstate <= execute;        -- clock data into destination
            when execute    => nxstate <= ram_wait_1;
        end case;
    end process fsm_next;

    -- fsm output decoder
    fsm_output : process(state, inr1, clk, pc_addr, inr3, inr2, alu_eq, alu_gr, alu_sm, ram_out, condition, selected_register, addr_mode,
                          port_out, reg_out)
    begin
        pc_write <= '0';
        pc_clock <= '0';
        reg_write <= '0';
        addr_mode <= inr1(2 downto 1);
        selected_register <= inr1(5 downto 3);
        data <= "00000000";
        s_addr <= pc_addr;
        s_pc_ld_val(15 downto 8) <= inr3;
        s_pc_ld_val(7 downto 0) <= inr2;

        s_ram_write <= '0';
        s_port_write <= '0';

        case inr1(7 downto 6) is 
            when "00" => condition <= '1'; -- unconditional
            when "01" => condition <= alu_eq;  -- equal
            when "10" => condition <= alu_gr;  -- greater
            when "11" => condition <= alu_sm;  -- smaller
            when others => null;                -- Z and shit
        end case;

        case state is
            when wakeup      => null;
            when ram_wait_1 => null;

            when fetch_1 => 
                inr1 <= ram_out;
                pc_clock <= '1';

            when ram_wait_2 => null;

            when fetch_2 => 
                inr2 <= ram_out;
                pc_clock <= '1';

            when ram_wait_3 => null;

            when fetch_3 => 
                inr3 <= ram_out;

            -- now work out what our source and destination should be
            when decode => 
                -- for addr mode absolute and extern
                s_addr <= inr3 & inr2;

            when execute => 
                report "condition " & integer'image(to_integer(unsigned(inr1(7 downto 6)))) & " = " & std_logic'image(condition);
                if condition = '0' then 
                    pc_clock <= '1';  -- nop
                else
                    s_addr <= inr3 & inr2;
                    -- real exec
                    if inr1(0) = '0' then
                        -- LD opearation (write to register, pc)

                        -- where to write
                        case selected_register is 
                            when "000" => 
                                -- what to write
                                case addr_mode is 
                                    when "00" => s_pc_ld_val(7 downto 0) <= ram_out;   -- absolute
                                    when "01" => s_pc_ld_val(7 downto 0) <= inr2;     -- immediate
                                    when "10" => s_pc_ld_val(7 downto 0) <= port_out; -- extern
                                    when others => null;
                                end case;
                                pc_write <= '1';        -- jmp
                            when others => 
                                -- what to write
                                case addr_mode is 
                                    when "00" => reg_ld_val <= ram_out;   -- absolute
                                    when "01" => reg_ld_val <= inr2;     -- immediate
                                    when "10" => 
                                        reg_ld_val <= port_out; -- extern
                                        report "<<<<<<<<<<<< Port read :" & integer'image(to_integer(unsigned(port_out))) & " from " & integer'image(to_integer(unsigned(s_addr)));
                                    when others => null;
                                end case;
                                reg_write <= '1';
                                pc_clock <= '1';
                        end case;
                    else
                        pc_clock <= '1';

                        -- ST opearation 
                        -- where to store
                        case addr_mode is 
                            when "00" => 
                                ram_ld_value <= reg_out; -- absolute
                                s_ram_write <= '1';
                            when "01" => null;        -- immediate
                            when "10" => 
                                port_ld_value <= reg_out;
                                s_port_write <= '1';
                            when others => null;
                        end case;
                    end if;
                end if;
        end case;
    end process fsm_output;


    -- concurrent stuff
    pc_ld_val <= s_pc_ld_val;
    reg_sel <= selected_register;
    ram_port_addr <= s_addr;
    ram_write <= s_ram_write;
    port_write <= s_port_write;

    -- debug
    debug_inr1 <= inr1;
    debug_inr2 <= inr2;
    debug_inr3 <= inr3;
    debug_cpu_state <= state;
    debug_cpu_nxstate <= nxstate;
end Behavioral;
