---------------------------------------------------------------------
-- TITLE: Arithmetic Logic Unit
-- AUTHOR: Henri
-- DATE CREATED: 2/8/01
-- FILENAME: mux_7seg.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    8 to 1 Multiplexer.
---------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_7seg is
    Port ( cmd : in STD_LOGIC_VECTOR (2 downto 0);
           E0 : in STD_LOGIC_VECTOR (6 downto 0);
           E1 : in STD_LOGIC_VECTOR (6 downto 0);
           E2 : in STD_LOGIC_VECTOR (6 downto 0);
           E3 : in STD_LOGIC_VECTOR (6 downto 0);
           E4 : in STD_LOGIC_VECTOR (6 downto 0);
           E5 : in STD_LOGIC_VECTOR (6 downto 0);
           E6 : in STD_LOGIC_VECTOR (6 downto 0);
           E7 : in STD_LOGIC_VECTOR (6 downto 0);
           DP: out std_logic;
           S : out STD_LOGIC_VECTOR (6 downto 0)
           );
end mux_7seg;

architecture Behavioral of mux_7seg is

begin
    process(cmd,E0,E1,E2,E3,E4,E5,E6,E7)
        begin

            case cmd is
                when "000" => S <=E0;
                              DP <= '1';  
                when "001" => S <=E1;
                              DP <= '1';
                when "010" => S <=E2;
                              DP <= '1';
                when "011" => S <=E3;
                              DP <= '1';
                when "100" => S <=E4;
                              DP <= '1';
                when "101" => S <=E5;
                              DP <= '1';
                when "110" => S <=E6;
                              DP <= '0';
                when "111" => S <=E7;
                              DP <= '1';
                when others => S <=E1;
                               DP <= '1';
            end case;

    end process;
end Behavioral;
