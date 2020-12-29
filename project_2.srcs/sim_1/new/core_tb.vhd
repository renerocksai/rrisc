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

    signal    rst           :  std_logic := '0';    -- RESET
    signal    clk           :  std_logic := '0';    -- clock
    signal    ram_ld_val    :  std_logic_vector (7 downto 0);
    signal    ram_write     :  std_logic;
    signal    ram_port_addr :  std_logic_vector (15 downto 0);
    signal    ram_addr :  std_logic_vector (4 downto 0);
    signal    ram_out       :  std_logic_vector (7 downto 0);

    signal    reg_ld_val    :  std_logic_vector (7 downto 0);
    signal    reg_write     :  std_logic;
    signal    reg_sel       :  std_logic_vector (2 downto 0);
    signal    reg_out       :  std_logic_vector (7 downto 0);

    signal    pc_load       :  std_logic;
    signal    pc_clock      :  std_logic;
    signal    pc_ld_val     :  std_logic_vector (15 downto 0);
    signal    pc_addr       :  std_logic_vector (15 downto 0);

    signal    alu_eq, alu_gr, alu_sm : std_logic := '0';
    signal    port_ld_value : std_logic_vector (7 downto 0) := "00000000";
    signal    port_out : std_logic_vector (7 downto 0) := "00000000";
    signal    port_write : std_logic;
    signal    pc_write : std_logic;

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

    iram : ram port map (
        rst => rst,
        clk => clk,
        ram_ld_val => ram_ld_val,
        write => ram_write,
        addr => ram_addr,
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

    icore : core port map (
        rst          => rst,
        clk          => clk,
        pc_write     => pc_write,
        pc_clock     => pc_clock,
        pc_ld_val    => pc_ld_val   ,
        pc_addr      => pc_addr     ,
        reg_ld_val   => reg_ld_val  ,
        reg_write    => reg_write   ,
        reg_sel      => reg_sel     ,
        reg_out      => reg_out     ,
        alu_eq       => alu_eq      ,
        alu_gr       => alu_gr      ,
        alu_sm       => alu_sm      ,
        ram_out      => ram_out     ,
        ram_ld_value => ram_ld_val,
        ram_port_addr => ram_port_addr,
        ram_write    => ram_write     ,
        port_ld_value => port_ld_value,
        port_write   => port_write    ,
        port_out     => port_out      
    );


    -- concurrent stuff
    clk <= not clk after 5 ns ; -- gives us 10ns per cycle

    ram_addr <= ram_port_addr(4 downto 0);

    rst <= '1' after 0 ns, 
           '0' after 10 ns,
           '1' after 100 ns;

    cpustate <= debug_cpu_state;
    cpureg_A <= debug_regs(0);
    cpureg_B <= debug_regs(1);
    cpureg_C <= debug_regs(2);
    cpureg_D <= debug_regs(3);
    cpureg_E <= debug_regs(4);
    cpureg_F <= debug_regs(5);
    cpureg_G <= debug_regs(6);

    clkrst : process(rst, clk)
    begin
        if rst = '0' then
            if rising_edge(clk) then
                report "_______________ CLOCK";
            end if;
        end if;
    end process clkrst;

    process
    begin
        wait for 5 ns;

        wait for 10 ns; -- reset
        wait for 10 ns; -- ram wait
        wait for 10 ns; -- fetch 1 
        show_iregs;
        helper <= '1';
        wait for 10 ns; -- ram wait 2
        wait for 10 ns; -- fetch 2 
        show_iregs;

        wait for 10 ns; -- ram wait 3
        wait for 10 ns; -- fetch 3
        show_iregs;
        wait for 10 ns; -- decode 
        wait for 10 ns; -- execute 
        assert debug_inr1 = "00001010" report "inr1 wrong" severity error;
        assert debug_inr2 = "11001010" report "inr2 wrong" severity error;
        assert debug_inr3 = "00000000" report "inr3 wrong" severity error;

        wait for 10 ns;
        assert false report "FINISHED OK" severity error;
    end process;

end Behavioral;
