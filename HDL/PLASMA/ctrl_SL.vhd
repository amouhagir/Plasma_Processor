---------------------------------------------------------------------
-- TITLE: CONTROLLER sig_swITCH sig_led
-- AUTHOR: Igor
-- DATE CREATED: 17/11/17
-- FILENAME: ctrl_SL.vhd
-- PROJECT: Plasma CPU
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the ctrl_SL.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;

entity ctrl_SL is
   port(
   		clock			: in  std_logic;
		reset			: in  std_logic;
		INPUT_1			: in  std_logic_vector(31 downto 0);
		INPUT_1_valid	: in  std_logic;
		OUTPUT_1		: out std_logic_vector(31 downto 0);
		SW				: in std_logic_vector(15 downto 0);
		LED				: out std_logic_vector(15 downto 0);
		RGB1_Red		: out  std_logic;
		RGB2_Red		: out  std_logic;
		RGB1_Green		: out  std_logic;
		RGB2_Green		: out  std_logic;
		RGB1_Blue		: out  std_logic;
		RGB2_Blue		: out  std_logic
	);
end ctrl_SL;

architecture Behavioral of ctrl_SL is

SIGNAL input_coproc 	: std_logic_vector(31 downto 0);

begin
	
	OUTPUT_1 <= "0000000000000000"&SW;

   process (clock)
      begin
      IF clock'event AND clock = '1' THEN
         IF ( reset = '1' ) THEN
            input_coproc    <= x"0000FFFF";
         ELSIF INPUT_1_valid = '1' THEN
            input_coproc 	<= INPUT_1;--x"ABCDEF12";
         ELSE
            input_coproc 	<= input_coproc;--x"01234567";--input_coproc;
         END IF;
      END IF;
   end process;

	LED <= 	input_coproc(15 downto 0);

	RGB1_Red <= input_coproc(21);
	RGB1_Green <= input_coproc(20);
	RGB1_Blue <= input_coproc(19);		
	
	RGB2_Red <= input_coproc(18);
	RGB2_Green <= input_coproc(17);		
	RGB2_Blue <= input_coproc(16);


end Behavioral; --architecture logic
