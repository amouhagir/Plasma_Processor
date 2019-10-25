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

entity function_4 is
   port(
		INPUT_1  : in  std_logic_vector(31 downto 0);
		INPUT_2  : in  std_logic_vector(31 downto 0);
		OUTPUT_1 : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of function_4 is

signal val0, val1, val2, val3, min, max , max_out, min_out: std_logic_vector(7 downto 0);
signal max01, max23, max0123, min01, min23, min0123: std_logic_vector(7 downto 0);
begin

	
val0 <= INPUT_1(31 downto 24 );
val1 <= INPUT_1(23 downto 16 );
val2 <= INPUT_1(15 downto 8 );
val3 <= INPUT_1(7 downto 0 );
min <= INPUT_2(15 downto 8);
max <= INPUT_2(7 downto 0);

compute_max : process(max, val0, val1, val2, val3, max01, max23, max0123)
begin
  if(val0 > val1) then
	 max01 <= val0;
  else 
	 max01 <= val1;
  end if;
  
  if(val2 > val3) then
	 max23 <= val2;
  else 
	 max23 <= val3;
  end if;
  
  if(max01 > max23) then
	 max0123 <= max01;
  else 
	 max0123 <= max23;
  end if;
  
  if(max0123 > max) then
	 max_out <= max0123;
  else 
	 max_out <= max;
  end if;
end process;

compute_min : process(min, val0, val1, val2, val3, min01, min23, min0123)
begin
  if(val0 < val1) then
	 min01 <= val0;
  else 
	 min01 <= val1;
  end if;
  
  if(val2 < val3) then
	 min23 <= val2;
  else 
	 min23 <= val3;
  end if;
  
  if(min01 < min23) then
	 min0123 <= min01;
  else 
	 min0123 <= min23;
  end if;
  
  if(min0123 < min) then
	 min_out <= min0123;
  else 
	 min_out <= min;
  end if;
end process;

OUTPUT_1 <= "0000000000000000"&min_out&max_out;

end; --architecture logic
