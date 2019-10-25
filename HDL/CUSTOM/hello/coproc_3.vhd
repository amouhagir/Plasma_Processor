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

entity coproc_3 is
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		INPUT_1        : in  std_logic_vector(31 downto 0);
		INPUT_1_valid  : in  std_logic;
		OUTPUT_1       : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of coproc_3 is
	SIGNAL mem : UNSIGNED(31 downto 0);
begin
	
	-------------------------------------------------------------------------
	process (clock, reset)
	begin
		IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				mem <= TO_UNSIGNED( 0, 32);
			ELSE
				IF INPUT_1_valid = '1' THEN
					mem <= UNSIGNED(INPUT_1) + TO_UNSIGNED( 3, 32);
				ELSE
					mem <= mem;
				END IF;
			END IF;
		END IF;
	end process;
	-------------------------------------------------------------------------

	OUTPUT_1 <= STD_LOGIC_VECTOR( mem );

end; --architecture logic
