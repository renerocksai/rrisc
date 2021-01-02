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

entity cpu_tb is
--  Port ( );
end cpu_tb;

architecture Behavioral of cpu_tb is
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
            port_out      :   IN    std_logic_vector (7 downto 0);

            -- ALU flags
            alu_eq        :   IN    std_logic;
            alu_gt        :   IN    std_logic;
            alu_sm        :   IN    std_logic
        );
    end component cpu;

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

    signal    port_ld_value : std_logic_vector (7 downto 0) := "00000000";
    signal    port_out : std_logic_vector (7 downto 0) := "00000000";
    signal    port_write : std_logic;


    signal alu_A : std_logic_vector (7 downto 0) := "00000000";
    signal alu_B : std_logic_vector (7 downto 0) := "01111111";  -- make A != B initially
    signal alu_I : std_logic_vector (7 downto 0) := "00000000";
    signal alu_eq, alu_gt, alu_sm : std_logic := '0';
    signal alu_F : std_logic_vector (7 downto 0) := "00000000";

begin
    iram : test_ram port map (
        rst => rst,
        clk => clk,
        ram_ld_val => ram_ld_val,
        write => ram_write,
        addr => ram_addr,
        ram_out => ram_out
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
        ram_out       => ram_out,
        ram_ld_value  => ram_ld_val,
        ram_port_addr => ram_port_addr,
        ram_write     => ram_write,

        -- port bus
        port_ld_value => port_ld_value,
        port_write    => port_write,
        port_out      => port_out,

        alu_gt    =>   alu_gt,
        alu_eq =>   alu_eq,
        alu_sm         =>   alu_sm
    );


    -- concurrent stuff
    clk <= not clk after 5 ns ; -- gives us 10ns per cycle

    ram_addr <= ram_port_addr(5 downto 0);

    rst <= '1' after 0 ns, 
           '0' after 10 ns;

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

