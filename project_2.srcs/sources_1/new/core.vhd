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
    reg_sel       :   OUT   std_logic_vector (3 downto 0);
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
    port_out      :   IN    std_logic_vector (7 downto 0);

);
end core;

architecture Behavioral of core is
    type state_t is (ram_wait_1, fetch_1, ram_wait_2, fetch_2, ram_wait_3, fetch_3, decode, execute);
    signal state, nxstate : state_t;

    -- instruction registers
    signal inr1 : std_logic_vector (7 downto 0);
    signal inr2 : std_logic_vector (7 downto 0);
    signal inr3 : std_logic_vector (7 downto 0);

    signal the_addr : std_logic_vector (15 downto 0);

    -- signals without registers
    addr_mode : std_logic_vector (1 downto 0);
    condition : std_logic;

    data : std_logic_vector (7 downto 0);
    
    constant zero  : unsigned (7 downto 0) := (others => '0');
begin

    -- for INRI2 with OE: instead of OE we must use an async multiplexer? or do a proper data bus
    -- radu is not needed anymore
    
    -- bit 0 unit:
    -- instead of OE, select via tmux
    -- reg_clk possibly not needed, definitely not externally, probably only as an internal signal for later process
    -- von RPI_CLK und RPI_OEN brauchen wir nurmehr die PORT varianten
    
    -- AMDU
    -- ROED, IOED (not used, inri), POED
    -- RCD, ICD (not used, inri), PCD 
    
    
    -- data bus writers:
    --     inri2
    --     ram
    --     port

    -- data bus readers:
    --     inri1
    --     inri2
    --     inri3
    --     ram
    --     port

    -- fsm state register
    fsm_reg: process(rst, clk)
    begin
        if (rst='1') then
            state <= ram_wait_1;
        elsif rising_edge(clk) then
            state <= nxstate;
        end if;
    end process fsm_reg;

    -- next state logic for fsm
    fsm_next: process(state)
    begin
        case state is
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
    fsm_output : process(state, inr1)
    begin
        pc_load <= '0';
        pc_clock <= '0';
        reg_clock <= '0';
        addr_mode <= inr1(2 downto 1);
        reg_sel <= inr1(5 downto 3);
        data => 0;
        ram_port_addr <= pc_addr;

        case inr1(7 downto 6) is 
            when '00' => condition <= '1'; -- unconditional
            when '01' => condition <= alu_eq;  -- equal
            when '10' => condition <= alu_gr;  -- greater
            when '11' => condition <= alu_sm;  -- smaller
        end case;

        case state is
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
                ram_port_addr <= inr3 & inr2;

            when execute => 
                if condition = '0' then 
                    pc_clock <= '1';  -- nop
                else
                    -- real exec
                    if inr1(0) = '0' then
                        -- LD opearation (write to register, pc)
                        -- what to write
                        case addr_mode is 
                            when '00' => data <= ram_out;   -- absolute
                            when '01' => data <= inri2;     -- immediate
                            when '10' => data <= port_value; -- extern
                            others => null;
                        end case;

                        -- where to write
                        case reg_sel is 
                            when '000' => 
                                pc_load_val(7 downto 0) <= data;
                                pc_load <= '1';        -- jmp
                            others => 
                                reg_ld_val <= data;
                                reg_clock <= '1';
                                pc_clock <= '1';
                        end case;
                    else
                        pc_clock <= '1';

                        -- ST opearation 
                        -- what to store
                        case reg_sel is 
                            when '000' => 
                                null;          -- we cannot store PC value
                            others => 
                                data <= reg_value;
                        end case;

                        -- where to store
                        case addr_mode is 
                            when '00' => 
                                ram_ld_value <= data; -- absolute
                                ram_write <= 1;
                            when '01' => null;        -- immediate
                            when '10' => 
                                port_ld_value <= data;
                                port_write <= 1;
                            others => null;
                        end case;
                    end if;
                end if;
        end case;
    end process fsm_output;


    -- concurrent stuff
    pc_load_val(15 downto 8) <= inr3;
    pc_load_val(7 downto 0) <= inr2;

end Behavioral;
