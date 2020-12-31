----------------------------------------------------------------------------------
-- Engineer: Rene Schallner
-- 
-- Create Date: 12/31/2020 
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- debug stuff
use work.debug.ALL;

entity alu_tb is
--  Port ( );
end alu_tb;

architecture Behavioral of alu_tb is
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

    signal clk : std_logic := '0';
    signal A, B, I : std_logic_vector (7 downto 0) := "00000000";

    signal cout_gt, sign, zero_equal, sm : std_logic := '0';
    signal F : std_logic_vector (7 downto 0) := "00000000";

    constant  OP_ADD    : std_logic_vector (7 downto 0) := "00000000";
    constant  OP_SUB    : std_logic_vector (7 downto 0) := "00000001";
    constant  OP_SHL    : std_logic_vector (7 downto 0) := "00000010";
    constant  OP_SHR    : std_logic_vector (7 downto 0) := "00000011";
    constant  OP_ROL    : std_logic_vector (7 downto 0) := "00000100";
    constant  OP_ROR    : std_logic_vector (7 downto 0) := "00000101";
    constant  OP_OR     : std_logic_vector (7 downto 0) := "00000110";
    constant  OP_AND    : std_logic_vector (7 downto 0) := "00000111";
    constant  OP_NAND   : std_logic_vector (7 downto 0) := "00001000";
    constant  OP_XOR    : std_logic_vector (7 downto 0) := "00001001";
    constant  OP_XNOR   : std_logic_vector (7 downto 0) := "00001010";
    constant  OP_CMP    : std_logic_vector (7 downto 0) := "00001011";
    constant  OP_INC    : std_logic_vector (7 downto 0) := "00001100";
    constant  OP_DEC    : std_logic_vector (7 downto 0) := "00001101";

    constant v1 : std_logic_vector (7 downto 0) := "00000101"; -- 5
    constant v2 : std_logic_vector (7 downto 0) := "00000011"; -- 3

begin
    ialu : alu port map (
                            clk        =>   clk,
                            A_in       =>   A,
                            B_in       =>   B,
                            I          =>   I,
                            cout_gt    =>   cout_gt,
                            zero_equal =>   zero_equal,
                            sm         =>   sm,
                            F          =>   F
                        );

    
    -- concurrent stuff
    clk <= not clk after 5 ns ; -- gives us 10ns per cycle

    process
    begin
        -- test add
        A <= v1;
        B <= v2;
        I <= OP_ADD;
        wait for 15 ns;
        wait for 10 ns;
        assert F = "00001000" report "ADD result bad: " & integer'image((to_integer(unsigned(F)))) severity ERROR;
        assert cout_gt = '0' report "ADD carry bad" severity ERROR;
        assert zero_equal = '0' report "ADD zero_equal bad" severity ERROR;
        assert sm = '0' report "ADD sm bad" severity ERROR;

        -- test sub
        A <= v1;
        B <= v2;
        I <= OP_SUB;
        wait for 10 ns;
        wait for 10 ns;
        assert F = "00000010" report "SUB 1 result bad: " & integer'image((to_integer(unsigned(F)))) severity ERROR;
        assert cout_gt = '0' report "SUB carry bad" severity ERROR;
        assert zero_equal = '0' report "SUB zero_equal bad" severity ERROR;
        assert sm = '0' report "SUB sm bad" severity ERROR;

        -- test sub
        A <= v2;
        B <= v1;
        I <= OP_SUB;
        wait for 10 ns;
        wait for 10 ns;
        assert F = "11111110" report "SUB result bad: " & integer'image((to_integer(unsigned(F)))) severity ERROR;
        assert cout_gt = '0' report "SUB carry bad" severity ERROR;
        assert zero_equal = '0' report "SUB zero_equal bad" severity ERROR;
        assert sm = '0' report "SUB sm bad" severity ERROR;

        -- test shift left into carry
        A <= F;
        I <= OP_SHL;
        wait for 10 ns;
        wait for 10 ns;
        assert F = "11111100" report "SHL result bad: " & integer'image((to_integer(unsigned(F)))) severity ERROR;
        assert cout_gt = '1' report "SHL carry bad" severity ERROR;
        assert zero_equal = '0' report "SHL zero_equal bad" severity ERROR;
        assert sm = '0' report "SHL sm bad" severity ERROR;

        -- test shift left into carry
        A <= "00000001";
        I <= OP_DEC;
        wait for 10 ns;
        wait for 10 ns;
        wait for 10 ns;  -- give alu time to delete carry 
        assert F = "00000000" report "DEC result bad: " & integer'image((to_integer(unsigned(F)))) severity ERROR;
        assert cout_gt = '0' report "DEC carry bad" severity ERROR;
        assert zero_equal = '1' report "DEC zero_equal bad" severity ERROR;
        assert sm = '0' report "DEC sm bad" severity ERROR;

        assert false report "FINISHED OK" severity ERROR;
    end process;
    
end Behavioral;
