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

begin
	
	-------------------------------------------------------------------------
	computation : process (INPUT_1, INPUT_2)
		variable data  : UNSIGNED(7 downto 0);
		variable mini  : UNSIGNED(7 downto 0);
		variable diff : UNSIGNED(7 downto 0);
		variable mult : UNSIGNED(23 downto 0);
		variable beta  : UNSIGNED(15 downto 0);
	begin
		data := UNSIGNED( INPUT_1(7 downto 0) ); 
		mini := UNSIGNED( INPUT_2(7 downto 0) );
		beta := UNSIGNED( INPUT_2(31 downto 16) );
		diff := data - mini; -- 8
		mult := diff * beta; -- 24
		OUTPUT_1(7 downto 0) <= std_logic_vector(mult(15 downto 8));
		OUTPUT_1(31 downto 8) <= (others => '0');
		
	end process;
	-------------------------------------------------------------------------

end; --architecture logic
