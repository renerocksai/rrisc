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

entity cpu is
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
end cpu;

architecture Behavioral of cpu is
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

    component core is
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
    end component core;

    signal    s_ram_ld_val    :  std_logic_vector (7 downto 0);
    signal    s_ram_write     :  std_logic;
    signal    s_ram_port_addr :  std_logic_vector (15 downto 0);
    signal    s_ram_out       :  std_logic_vector (7 downto 0);

    signal    reg_ld_val    :  std_logic_vector (7 downto 0);
    signal    reg_write     :  std_logic;
    signal    reg_sel       :  std_logic_vector (2 downto 0);
    signal    reg_out       :  std_logic_vector (7 downto 0);

    signal    pc_load       :  std_logic := '0';
    signal    pc_clock      :  std_logic;
    signal    pc_ld_val     :  std_logic_vector (15 downto 0);
    signal    pc_addr       :  std_logic_vector (15 downto 0);

    signal    s_port_ld_value : std_logic_vector (7 downto 0) := "00000000";
    signal    s_port_out : std_logic_vector (7 downto 0) := "00000000";
    signal    s_port_write : std_logic;

    signal cpustate : state_t;
    signal helper : std_logic := '0';
    signal cpureg_A : std_logic_vector (7 downto 0);
    signal cpureg_B : std_logic_vector (7 downto 0);
    signal cpureg_C : std_logic_vector (7 downto 0);
    signal cpureg_D : std_logic_vector (7 downto 0);
    signal cpureg_E : std_logic_vector (7 downto 0);
    signal cpureg_F : std_logic_vector (7 downto 0);
    signal cpureg_G : std_logic_vector (7 downto 0);
    signal debug_ram : mem_t ;

begin
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

    icore : core port map (
        rst          => rst,
        clk          => clk,
        pc_write     => pc_load,
        pc_clock     => pc_clock,
        pc_ld_val    => pc_ld_val   ,
        pc_addr      => pc_addr     ,
        reg_ld_val   => reg_ld_val  ,
        reg_write    => reg_write   ,
        reg_sel      => reg_sel     ,
        reg_out      => reg_out     ,
        alu_eq       => alu_eq      ,
        alu_gr       => alu_gt      ,
        alu_sm       => alu_sm      ,
        ram_out      => s_ram_out     ,
        ram_ld_value => s_ram_ld_val,
        ram_port_addr => s_ram_port_addr,
        ram_write    => s_ram_write     ,
        port_ld_value => s_port_ld_value,
        port_write   => s_port_write    ,
        port_out     => s_port_out      
    );

    -- concurrent stuff
    ram_ld_value <= s_ram_ld_val;
    ram_port_addr <= s_ram_port_addr;
    ram_write    <= s_ram_write     ;
    s_ram_out <= ram_out;
    port_ld_value <= s_port_ld_value;
    port_write   <= s_port_write    ;
    ram_port_addr <= s_ram_port_addr;
    s_port_out     <= port_out     ; 

end Behavioral;

