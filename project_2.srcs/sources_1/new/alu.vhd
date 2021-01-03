
----------------------------------------------------------------------------------
-- 
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


entity alu is 
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
    F                 :   OUT   std_logic_vector(7 downto 0)
);
end entity;
                
                
architecture calculation of alu is 

        signal A, B : unsigned (7 downto 0);
        signal F_i : unsigned(8 downto 0) := "011111111";    -- don't trigger zero flag right away 
        -- internal signal for calculation
        -- is assigned to F-output and carry-flag with concurrent statement
        
        signal cin : std_logic := '0';
        signal s_zero : std_logic := '0';
        signal c_gt : std_logic := '0';
        signal ssm : std_logic := '0';
        signal s_sign : std_logic := '0';
        signal s_equal : std_logic := '0';
         
        begin

--        councurrent statements

        -- sign-flag is determined by bit 7 of the result -> sign bit
        A <= unsigned((A_in));
        B <= unsigned((B_in));
        s_zero <= '1' when F_i(7 downto 0) = "00000000" else '0';
        zero_equal <= s_zero or s_equal;
        F <= std_logic_vector(F_i(7 downto 0)); 

        cout_gt <= c_gt;
        sm <= ssm;
        sign <= s_sign;

        debug_alu_eq <= s_zero or s_equal;
        debug_alu_gt <= c_gt;
        debug_alu_sm <= ssm;
        debug_alu_A <= A_in;
        debug_alu_B <= B_in;
        debug_alu_I <= I;
        debug_alu_F <= std_logic_vector(F_i(7 downto 0));
        
        
--        processes
        
        process(clk, c_gt) is
        begin
            cin <= c_gt;  -- carry in is carry out from last operation

            if rising_edge(clk) then 
                F_i <= "011111111";  -- careful, not triggering zero flag
                ssm <= '0';
                c_gt <= F_i(8);   -- carry 

                ssm <= '0';

                s_equal <= '0';


                case I(3 downto 0) is 
                    when "0000" =>                                         -- ADD
                        if cin = '1' then F_i <= ('0' & A) + ('0' & B) + 1;
                        else              F_i <= ('0' & A) + ('0' & B);
                        end if;
                            
                    when "0001" =>                                         -- SUB
                        if cin = '1' then 
                            F_i <= ('0' & A) - ('0' & B) - 1;
                        else              
                            F_i <= ('0' & A) - ('0' & B);
                        end if;
                            
                    when "0010" =>                                        -- SHL
                        -- shift left, into carry flag
                        F_i <= A & '0';

                    when "0011" =>                                        -- SHR
                        -- shift right, into carry flag
                        F_i <= A(0) & '0' & A(6 downto 0) ;

                    when "0100" =>                                        -- ROL
                        F_i <= '0' & A(6 downto 0) & A(7);
                        report "ROL" & integer'image(to_integer(unsigned(A))) & " -> " &  integer'image(to_integer(unsigned(A(6 downto 0) & A(7))));

                    when "0101" =>                                        -- ROR
                        F_i <= '0' & A(0)& A(7 downto 1) ;
                        report "ROR" & integer'image(to_integer(unsigned(A))) & " -> " &  integer'image(to_integer(unsigned(A(0)& A(7 downto 1))));

                    when "0110" => F_i <= '0' & (A OR B);                 -- OR
                    when "0111" => F_i <= '0' & (A AND B);                -- AND
                    when "1000" => F_i <= '0' & (NOT A AND B);            -- NAND
                    when "1001" => F_i <= '0' & (A XOR B);                -- XOR
                    when "1010" => F_i <= '0' & (A XNOR B);               -- XNOR

                    when "1011" =>                                        -- CMP
                        F_i <= "000000001"; -- prevent zero flag
                        if A = B then
                            s_equal <= '1';
                        end if;
                        if A > B then 
                            c_gt <= '1';
                        else
                            c_gt <= '0';
                        end if;
                        if A < B then
                            ssm <= '1';
                        else
                            ssm <= '0';
                        end if;

                    when "1100" =>                                        -- INC
                        F_i <= ('0' & A) + "00000001";

                    when "1101" =>                                        -- DEC
                        F_i <= ('0' & A) - "00000001";         

                    when others => null;

                s_sign <= F_i(7); 
                end case;
            end if;
        end process;
end architecture;

