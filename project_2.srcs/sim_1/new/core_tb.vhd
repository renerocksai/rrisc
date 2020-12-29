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

-- debug stuff
use work.debug.ALL;

entity ram is
    port(
    -- reset and clock
    rst         :   IN    std_logic;    -- RESET
    clk         :   IN    std_logic;    -- clock

    ram_ld_val  :   IN   std_logic_vector (7 downto 0);
    write       :   IN   std_logic;
    addr        :   IN   std_logic_vector (4 downto 0);
    ram_out     :   OUT  std_logic_vector (7 downto 0)
);
end ram;

architecture Behavioral of ram is
    type mem_t is array (0 to 15) of std_logic_vector (7 downto 0);

    -- signals
    signal mem : mem_t := (
        "00001010",
        "11001010",
        "00000000",
        "00001001",
        "00001100",
        "00000000",
        "00010000",
        "00001100",
        "00000000",
        "00000010",
        "00001001",
        "00000000",
        "11111111",
        "11111111",
        "11111111",
        "11111111"
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
                myval <= mem(to_integer(unsigned(addr)));
            end if;
        end if;
    end process regproc;

    -- concurrent stuff
    ram_out <= myval;

    -- debug
 
end Behavioral;



entity core_tb is
--  Port ( );
end core_tb;

architecture Behavioral of core_tb is

begin


end Behavioral;
