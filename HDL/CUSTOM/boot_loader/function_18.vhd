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

entity function_18 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_18 is
begin
	
	-------------------------------------------------------------------------
	computation : process (INPUT_1, INPUT_2)
		variable rTemp1  : SIGNED(8 downto 0);
		variable rTemp2  : SIGNED(8 downto 0);
		variable rTemp3  : SIGNED(8 downto 0);
		variable rTemp4  : SIGNED(8 downto 0);
		variable vTemp1  : std_logic_vector(7 downto 0);
		variable vTemp2  : std_logic_vector(7 downto 0);
		variable vTemp3  : std_logic_vector(7 downto 0);
		variable vTemp4  : std_logic_vector(7 downto 0);
	begin
		rTemp1 := RESIZE( SIGNED(INPUT_1( 7 downto  0)), 9) + RESIZE( SIGNED(INPUT_2( 7 downto  0)), 9);
		rTemp2 := RESIZE( SIGNED(INPUT_1(15 downto  8)), 9) + RESIZE( SIGNED(INPUT_2(15 downto  8)), 9);
		rTemp3 := RESIZE( SIGNED(INPUT_1(23 downto 16)), 9) + RESIZE( SIGNED(INPUT_2(23 downto 16)), 9);
		rTemp4 := RESIZE( SIGNED(INPUT_1(31 downto 24)), 9) + RESIZE( SIGNED(INPUT_2(31 downto 24)), 9);

		if    ( rTemp1 > TO_SIGNED(+127, 8) ) then vTemp1 := STD_LOGIC_VECTOR( TO_SIGNED(+127, 8) );
		elsif ( rTemp1 < TO_SIGNED(-127, 8) ) then vTemp1 := STD_LOGIC_VECTOR( TO_SIGNED(-127, 8) );
		else                                    vTemp1 := STD_LOGIC_VECTOR(rTemp1(7 downto 0));
		end if;
		
		if    ( rTemp2 > TO_SIGNED(+127, 8) ) then vTemp2 := STD_LOGIC_VECTOR( TO_SIGNED(+127, 8) );
		elsif ( rTemp2 < TO_SIGNED(-127, 8) ) then vTemp2 := STD_LOGIC_VECTOR( TO_SIGNED(-127, 8) );
		else                                    vTemp2 := STD_LOGIC_VECTOR(rTemp2(7 downto 0));
		end if;

		if    ( rTemp3 > TO_SIGNED(+127, 8) ) then vTemp3 := STD_LOGIC_VECTOR( TO_SIGNED(+127, 8) );
		elsif ( rTemp3 < TO_SIGNED(-127, 8) ) then vTemp3 := STD_LOGIC_VECTOR( TO_SIGNED(-127, 8) );
		else                                    vTemp3 := STD_LOGIC_VECTOR(rTemp3(7 downto 0));
		end if;

		if    ( rTemp3 > TO_SIGNED(+127, 8) ) then vTemp4 := STD_LOGIC_VECTOR( TO_SIGNED(+127, 8) );
		elsif ( rTemp3 < TO_SIGNED(-127, 8) ) then vTemp4 := STD_LOGIC_VECTOR( TO_SIGNED(-127, 8) );
		else                                    vTemp4 := STD_LOGIC_VECTOR(rTemp4(7 downto 0));
		end if;

		OUTPUT_1 <= (vTemp4 & vTemp3 & vTemp2 & vTemp1);
	end process;
	-------------------------------------------------------------------------

end; --architecture logic
