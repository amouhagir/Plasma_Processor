
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

entity function_3 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_3 is

constant Nf : INTEGER := 18;

begin
	
	-------------------------------------------------------------------------
	computation : process (INPUT_1, INPUT_2)
		variable rTemp1  : SIGNED(63 downto 0);
		variable rTemp2  : SIGNED(63 downto 0);
		variable rTemp3  : SIGNED(63 downto 0);
	begin
		rTemp1 := (signed(INPUT_1) * signed(INPUT_1));
		rTemp2 := (signed(INPUT_2) * signed(INPUT_2));
		rTemp3 := rTemp1+rTemp2;
		OUTPUT_1 <= std_logic_vector(rTemp3(32+(Nf-1) downto Nf));  --x1²+y1²
	end process;
	
	-------------------------------------------------------------------------

end; --architecture logic
