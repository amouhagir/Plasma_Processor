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

entity function_2 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_2 is
begin
	-------------------------------------------------------------------------

	computation : process (INPUT_1, INPUT_2)
	begin
		if(INPUT_1 < INPUT_2) then
			OUTPUT_1 <= INPUT_1;
		else
			OUTPUT_1 <= INPUT_2;
		end if;
	end process;
	
	-------------------------------------------------------------------------

end; --architecture logic
