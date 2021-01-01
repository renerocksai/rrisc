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
-- 
--      include alu.inc
--      
--      org 0
--      
--      lda #$01
--      ldb #$05 
--      
--      ldb #$03 : EQ  ; should not execute
--                     ; because EQ (zero)
--      			   ; flag isn't set
--      
--      macro ADD_A_B        ; A + B => A
--                     ; (A = 6)
--      ldb #$06       ; B = 6
--      
--      ; if A == B -> C = $01 else C = $ff
--      ldc #$ff       ; C = $ff
--      macro CMP_A_B        ; test A == B
--      ldc #$01 : EQ  ; C = $01 if EQual
--      
--      :forever
--      jmp forever
--      
--      ; we expect:
--      ; A = 6
--      ; B = 6
--      ; C = 1
--  
-- This translates to:
--    0a 01 00 12 05 00 52 03 
--    00 0d fc ff 15 fd ff 3a  
--    00 00 3d fe ff 0c ff ff
--    12 06 00 1a ff 00 0d fc 
--    ff 15 fd ff 3a 0b 00 3d

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
        addr        :   IN   std_logic_vector (5 downto 0);
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

    signal    rst           :  std_logic := '0';    -- RESET
    signal    clk           :  std_logic := '0';    -- clock
    signal    ram_ld_val    :  std_logic_vector (7 downto 0);
    signal    ram_write     :  std_logic;
    signal    ram_port_addr :  std_logic_vector (15 downto 0);
    signal    ram_addr :  std_logic_vector (5 downto 0);
    signal    ram_out       :  std_logic_vector (7 downto 0);

    signal    reg_ld_val    :  std_logic_vector (7 downto 0);
    signal    reg_write     :  std_logic;
    signal    reg_sel       :  std_logic_vector (2 downto 0);
    signal    reg_out       :  std_logic_vector (7 downto 0);

    signal    pc_load       :  std_logic := '0';
    signal    pc_clock      :  std_logic;
    signal    pc_ld_val     :  std_logic_vector (15 downto 0);
    signal    pc_addr       :  std_logic_vector (15 downto 0);

    signal    port_ld_value : std_logic_vector (7 downto 0) := "00000000";
    signal    port_out : std_logic_vector (7 downto 0) := "00000000";
    signal    port_write : std_logic;

    signal alu_A : std_logic_vector (7 downto 0) := "00000000";
    signal alu_B : std_logic_vector (7 downto 0) := "01111111";  -- make A != B initially
    signal alu_I : std_logic_vector (7 downto 0) := "00000000";
    signal alu_eq, alu_gt, alu_sm : std_logic := '0';
    signal alu_F : std_logic_vector (7 downto 0) := "00000000";

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

    procedure show_regs_and_alu is
    begin
        report "*** Registers: ***";
        report "     A: " & integer'image(to_integer(unsigned(debug_regs(0)))) ;
        report "     B: " & integer'image(to_integer(unsigned(debug_regs(1)))) ;
        report "     C: " & integer'image(to_integer(unsigned(debug_regs(2)))) ;
        report "     D: " & integer'image(to_integer(unsigned(debug_regs(3)))) ;
        report "     E: " & integer'image(to_integer(unsigned(debug_regs(4)))) ;
        report "     F: " & integer'image(to_integer(unsigned(debug_regs(5)))) ;
        report "     G: " & integer'image(to_integer(unsigned(debug_regs(6)))) ;
        report "ALU_A : " & integer'image(to_integer(unsigned(alu_A))) ;
        report "ALU_B : " & integer'image(to_integer(unsigned(alu_B))) ;
        report "ALU_I : " & integer'image(to_integer(unsigned(alu_I))) ;
        report "ALU_F : " & integer'image(to_integer(unsigned(alu_F))) ;
        report "   EQ : " & std_logic'image(alu_eq) ;
        report "   GT : " & std_logic'image(alu_gt) ;
        report "   SM : " & std_logic'image(alu_sm) ;
    end show_regs_and_alu;
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

    ram_addr <= ram_port_addr(5 downto 0);

    rst <= '1' after 0 ns, 
           '0' after 10 ns;

    cpustate <= debug_cpu_state;
    cpureg_A <= debug_regs(0);
    cpureg_B <= debug_regs(1);
    cpureg_C <= debug_regs(2);
    cpureg_D <= debug_regs(3);
    cpureg_E <= debug_regs(4);
    cpureg_F <= debug_regs(5);
    cpureg_G <= debug_regs(6);

    debug_ram(0) <= debug_mem(0);
    debug_ram(1) <= debug_mem(1);
    debug_ram(2) <= debug_mem(2);
    debug_ram(3) <= debug_mem(3);
    debug_ram(4) <= debug_mem(4);
    debug_ram(5) <= debug_mem(5);
    debug_ram(6) <= debug_mem(6);
    debug_ram(7) <= debug_mem(7);
    debug_ram(8) <= debug_mem(8);
    debug_ram(9) <= debug_mem(9);
    debug_ram(10) <= debug_mem(10);
    debug_ram(11) <= debug_mem(11);
    debug_ram(12) <= debug_mem(12);
    debug_ram(13) <= debug_mem(13);
    debug_ram(14) <= debug_mem(14);
    debug_ram(15) <= debug_mem(15);

    clkrst : process(rst, clk)
    begin
        if rst = '0' then
            if rising_edge(clk) then
                report "_______________ CLOCK";
            end if;
        end if;
    end process clkrst;

    aluports : process(clk, ram_port_addr, port_ld_value, port_out, port_write)
    begin
        if rising_edge(clk) then
            if port_write = '1' then
                report ":PORT WRiTE";
                case ram_port_addr is
                    when "1111111111111100" =>
                        alu_A <= port_ld_value;
                        report "> ALU A: " & integer'image(to_integer(unsigned(port_ld_value)));
                    when "1111111111111101" =>
                        alu_B <= port_ld_value;
                        report "> ALU B: " & integer'image(to_integer(unsigned(port_ld_value)));
                    when "1111111111111110" =>
                        alu_I <= port_ld_value;
                        report "> ALU I: " & integer'image(to_integer(unsigned(port_ld_value)));
                    when others => null;
                end case;
            else
                case ram_port_addr is
                    when "1111111111111111" =>
                        port_out <= alu_F;
                        report "< ALU F: " & integer'image(to_integer(unsigned(alu_F)));
                    when others => null;
                end case;
            end if;
        end if;
    end process aluports;

    process
    begin
        wait for 5 ns;

        wait for 10 ns; -- reset
        wait for 10 ns; -- ram wait
        wait for 10 ns; -- fetch 1 
        wait for 10 ns; -- ram wait 2
        wait for 10 ns; -- fetch 2 

        wait for 10 ns; -- ram wait 3
        wait for 10 ns; -- fetch 3
        wait for 10 ns; -- decode 
        wait for 10 ns; -- execute 
        show_regs_and_alu;

        wait for 10 ns; -- past execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;


        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;


        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;
        
        wait for 90 ns; -- execute 
        show_regs_and_alu;

        wait for 90 ns; -- execute 
        show_regs_and_alu;
        wait for 10 ns;

        assert debug_regs(0) = "00000110" report "Reg A wrong" severity ERROR;
        assert debug_regs(1) = "00000110" report "Reg A wrong" severity ERROR;
        assert debug_regs(2) = "00000001" report "Reg A wrong" severity ERROR;

        assert false report "FINISHED OK" severity error;
    end process;

end Behavioral;
