----------------------------------------------------------------------------------
--
-- Engineer: Rene Schallner
-- 
-- Create Date: 12/29/2020 
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

entity ram is
    port(
    -- reset and clock
    rst         :   IN    std_logic;    -- RESET
    clk         :   IN    std_logic;    -- clock

    ram_ld_val  :   IN   std_logic_vector (7 downto 0);
    write       :   IN   std_logic;
    addr        :   IN   std_logic_vector (5 downto 0);
    ram_out     :   OUT  std_logic_vector (7 downto 0)
);
end ram;

architecture Behavioral of ram is
    -- type mem_t is array (0 to 15) of std_logic_vector (7 downto 0);

    -- signals
    signal mem : mem_t := (
        "00001010",
        "00000001",
        "00000000",
        "00010010",
        "00000101",
        "00000000",
        "01010010",
        "00000011",
        "00000000",
        "00001101",
        "11111100",
        "11111111",
        "00010101",
        "11111101",
        "11111111",
        "00111010",
        "00000000",
        "00000000",
        "00111101",
        "11111110",
        "11111111",
        "00001100",
        "11111111",
        "11111111",
        "00010010",
        "00000110",
        "00000000",
        "00011010",
        "11111111",
        "00000000",
        "00001101",
        "11111100",
        "11111111",
        "00010101",
        "11111101",
        "11111111",
        "00111010",
        "00001011",
        "00000000",
        "00111101",
        "11111110",
        "11111111",
        "01011010",
        "00000001",
        "00000000",
        "00000010",
        "00101101",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000"
    );
    signal myval : std_logic_vector (7 downto 0) := "11111111";
    constant zero : std_logic_vector(7 downto 0) := "00000000";

begin
    regproc : process (rst, clk)
    begin
        if rst = '1' then
            myval <= zero;
        elsif rising_edge(clk) then
            if write = '1' then
                mem(to_integer(unsigned(addr))) <= ram_ld_val;
                myval <= ram_ld_val;
                report "> ram " & integer'image(to_integer(unsigned(addr))) & " : " & integer'image(to_integer(unsigned(ram_ld_val))) ;
            else
                report "< ram " & integer'image(to_integer(unsigned(addr))); --  & " : " & integer'image(to_integer(unsigned(ram_ld_val))) ;
                myval <= mem(to_integer(unsigned(addr)));
            end if;
        end if;
    end process regproc;

    -- concurrent stuff
    ram_out <= myval;

    -- debug
    debug_mem(0) <= mem(0);
    debug_mem(1) <= mem(1);
    debug_mem(2) <= mem(2);
    debug_mem(3) <= mem(3);
    debug_mem(4) <= mem(4);
    debug_mem(5) <= mem(5);
    debug_mem(6) <= mem(6);
    debug_mem(7) <= mem(7);
    debug_mem(8) <= mem(8);
    debug_mem(9) <= mem(9);
    debug_mem(10) <= mem(10);
    debug_mem(11) <= mem(11);
    debug_mem(12) <= mem(12);
    debug_mem(13) <= mem(13);
    debug_mem(14) <= mem(14);
    debug_mem(15) <= mem(15);
    debug_mem(16) <= mem(16);
    debug_mem(17) <= mem(17);
    debug_mem(18) <= mem(18);
    debug_mem(19) <= mem(19);
    debug_mem(20) <= mem(20);
    debug_mem(21) <= mem(21);
    debug_mem(22) <= mem(22);
    debug_mem(23) <= mem(23);
    debug_mem(24) <= mem(24);
    debug_mem(25) <= mem(25);
    debug_mem(26) <= mem(26);
    debug_mem(27) <= mem(27);
    debug_mem(27) <= mem(27);
    debug_mem(28) <= mem(28);
    debug_mem(29) <= mem(29);
    debug_mem(30) <= mem(30);
    debug_mem(31) <= mem(31);
end Behavioral;


