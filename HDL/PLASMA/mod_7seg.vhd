---------------------------------------------------------------------
-- TITLE: Arithmetic Logic Unit
-- AUTHOR: Henri
-- DATE CREATED: 2/8/01
-- FILENAME: mod_7seg.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Counter modulo 8.
---------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_7seg is
	Port (
		    clk : in STD_LOGIC;
		    rst : in STD_LOGIC;
		    AN : out STD_LOGIC_VECTOR (7 downto 0);
        cmd_mux_7seg : out STD_LOGIC_VECTOR (2 downto 0));
end mod_7seg;


architecture Behavioral of mod_7seg is

signal counter: integer range 0 to 7;
signal freq_div : integer range 0 to 999;

begin

PRO_COUNTER : process (clk,rst)
begin

	if (rst = '1') then
    		counter <= 0;
	elsif (clk='1' and clk'event) then
        freq_div <= freq_div + 1;
        if (freq_div = 999) then
            freq_div <= 0;
            if (counter=7) then
        	   counter <= 0;
    	    else
        	   counter <= counter + 1;
    	    end if;
        end if;
	end if;


end process PRO_COUNTER;

PRO_ANODE : process (counter)
begin
    if (counter = 0) then
        AN <= "11111110";
        cmd_mux_7seg <= "111";

    elsif (counter = 1) then
        AN <= "11111101";
        cmd_mux_7seg <= "110";

    elsif (counter = 2) then
        AN <= "11111011";
        cmd_mux_7seg <= "101";

    elsif (counter = 3) then
        AN <= "11110111";
        cmd_mux_7seg <= "100";

    elsif (counter = 4) then
        AN <= "11101111";
        cmd_mux_7seg <= "011";

    elsif (counter = 5) then
        AN <= "11011111";
        cmd_mux_7seg <= "010";

    elsif (counter = 6) then
        AN <= "10111111";
        cmd_mux_7seg <= "001";

    elsif (counter = 7) then
        AN <= "01111111";
        cmd_mux_7seg <= "000";

    end if;

end process PRO_ANODE;
end Behavioral;
