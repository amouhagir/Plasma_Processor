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

entity buttons_controller is
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		buttons_access : in  std_logic;

		btnC : in std_logic;
		btnU : in std_logic;
		btnD : in std_logic;
		btnL : in std_logic;
		btnR : in std_logic;

		buttons_values : out std_logic_vector(31 downto 0);
		buttons_change : out std_logic_vector(31 downto 0)
	);
end; --buttons_controller

architecture logic of buttons_controller is
	SIGNAL buttons_input  : std_logic_vector(31 downto 0);
	SIGNAL buttons_buffer : std_logic_vector(31 downto 0);
begin
	buttons_input(0) <= btnC;
	buttons_input(1) <= btnU;
	buttons_input(2) <= btnD;
	buttons_input(3) <= btnL;
	buttons_input(4) <= btnR;

	-------------------------------------------------------------------------
	process (clock, reset)
	begin
		IF reset = '1' THEN
			buttons_buffer <= (others => '0');
			buttons_change <= (others => '0');
		ELSIF clock'event AND clock = '1' THEN
			buttons_values <= buttons_input;

			IF buttons_access = '1' THEN
				buttons_buffer <= buttons_input;
				buttons_change <= buttons_input xor buttons_buffer;
			END IF;
		END IF;
	end process;
	-------------------------------------------------------------------------

end; --architecture logic
