---------------------------------------------------------------------
-- TITLE: Arithmetic Logic Unit
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/8/01
-- FILENAME: alu.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the ALU.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;

entity function_15 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_15 is
begin

	-------------------------------------------------------------------------
	computation : process (INPUT_1, INPUT_2)
		variable rTemp1  : SIGNED(7 downto 0);
		variable rTemp2  : SIGNED(7 downto 0);
		variable rTemp3  : SIGNED(7 downto 0);
		variable rTemp4  : SIGNED(7 downto 0);
		variable sTemp1  : STD_LOGIC;
		variable sTemp2  : STD_LOGIC;
		variable sTemp3  : STD_LOGIC;
		variable sTemp4  : STD_LOGIC;
	begin
		rTemp1 := SIGNED( INPUT_1( 7 downto  0) );
		rTemp2 := SIGNED( INPUT_1(15 downto  8) );
		rTemp3 := SIGNED( INPUT_1(23 downto 16) );
		rTemp4 := SIGNED( INPUT_1(31 downto 24) );

		IF rTemp1 <= TO_SIGNED(0, 8) THEN sTemp1 := INPUT_2( 0); ELSE sTemp1 := '0'; END IF;
		IF rTemp2 <= TO_SIGNED(0, 8) THEN sTemp2 := INPUT_2( 8); ELSE sTemp2 := '0'; END IF;
		IF rTemp3 <= TO_SIGNED(0, 8) THEN sTemp3 := INPUT_2(16); ELSE sTemp3 := '0'; END IF;
		IF rTemp4 <= TO_SIGNED(0, 8) THEN sTemp4 := INPUT_2(24); ELSE sTemp4 := '0'; END IF;

		OUTPUT_1 <= "0000000" & sTemp4 & "0000000" & sTemp3 & "0000000" & sTemp2 & "0000000" & sTemp1;
	end process;
	-------------------------------------------------------------------------

end; --architecture logic
