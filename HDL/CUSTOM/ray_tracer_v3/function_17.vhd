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

entity function_17 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_17 is
begin
	
	-------------------------------------------------------------------------
	computation : process (INPUT_1, INPUT_2)
		variable vTemp1  : std_logic_vector(7 downto 0);
		variable vTemp2  : std_logic_vector(7 downto 0);
		variable vTemp3  : std_logic_vector(7 downto 0);
		variable vTemp4  : std_logic_vector(7 downto 0);
	begin
		IF INPUT_2( 0 ) = '0' THEN
			vTemp1 := INPUT_1( 7 downto  0);
		ELSE
			vTemp1 := STD_LOGIC_VECTOR( TO_SIGNED(0, 8) - SIGNED(INPUT_2( 7 downto  0)) );
		END IF;

		IF INPUT_2( 8 ) = '0' THEN
			vTemp1 := INPUT_1(15 downto  8);
		ELSE
			vTemp1 := STD_LOGIC_VECTOR( TO_SIGNED(0, 8) - SIGNED(INPUT_2(15 downto  8)) );
		END IF;

		IF INPUT_2( 16 ) = '0' THEN
			vTemp1 := INPUT_1(23 downto 16);
		ELSE
			vTemp1 := STD_LOGIC_VECTOR( TO_SIGNED(0, 8) - SIGNED(INPUT_2(23 downto 16)) );
		END IF;

		IF INPUT_2( 24 ) = '0' THEN
			vTemp1 := INPUT_1(31 downto 24);
		ELSE
			vTemp1 := STD_LOGIC_VECTOR( TO_SIGNED(0, 8) - SIGNED(INPUT_2(31 downto 24)) );
		END IF;

		OUTPUT_1 <= (vTemp4 & vTemp3 & vTemp2 & vTemp1);
	end process;

end; --architecture logic
