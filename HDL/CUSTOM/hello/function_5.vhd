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
use work.cam_pkg.all;

entity function_5 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_5 is
begin
	
	-------------------------------------------------------------------------
	computation : process (INPUT_1, INPUT_2)
		variable data1, data2, data3, data4  : UNSIGNED(7 downto 0);
		variable mini  : UNSIGNED(7 downto 0);
		variable diff1, diff2, diff3, diff4 : UNSIGNED(7 downto 0);
		variable mult1, mult2, mult3, mult4 : UNSIGNED(23 downto 0);
		variable beta  : UNSIGNED(15 downto 0);
	begin
		data1 := UNSIGNED( INPUT_1(7 downto 0) );
		data2 := UNSIGNED( INPUT_1(15 downto 8) );
		data3 := UNSIGNED( INPUT_1(23 downto 16) );
		data4 := UNSIGNED( INPUT_1(31 downto 24) );
							 
		mini := UNSIGNED( INPUT_2(7 downto 0) );
		beta := UNSIGNED( INPUT_2(31 downto 16) );
		diff1 := data1 - mini; -- 8
		diff2 := data2 - mini; -- 8
		diff3 := data3 - mini; -- 8
		diff4 := data4 - mini; -- 8
		mult1 := diff1 * beta; -- 24
		mult2 := diff2 * beta; -- 24
		mult3 := diff3 * beta; -- 24
		mult4 := diff4 * beta; -- 24
		OUTPUT_1(7 downto 0) <= std_logic_vector(mult1(15 downto 8));
		OUTPUT_1(15 downto 8) <= std_logic_vector(mult2(15 downto 8));
		OUTPUT_1(23 downto 16) <= std_logic_vector(mult3(15 downto 8));
		OUTPUT_1(31 downto 24) <= std_logic_vector(mult4(15 downto 8));
	end process;
	--OUTPUT_1 <= INPUT_1;
	-------------------------------------------------------------------------

end; --architecture logic
