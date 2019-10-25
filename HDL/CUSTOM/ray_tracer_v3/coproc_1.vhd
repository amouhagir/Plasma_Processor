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

entity coproc_1 is
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		INPUT_1        : in  std_logic_vector(31 downto 0);
		INPUT_1_valid  : in  std_logic;
		OUTPUT_1       : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of coproc_1 is

  signal R0, R1, R2, R3, R4, R5 : std_logic_vector(31 downto 0);
  signal Temp01, Temp23, Temp45 : signed(63 downto 0);
  signal mul01, mul23, mul45 : std_logic_vector(31 downto 0);
  signal reg_mul01, reg_mul23, reg_mul45 : std_logic_vector(31 downto 0);
  signal sum1 : signed(32 downto 0);
  signal out_tmp : signed(33 downto 0);
  signal counter : integer range 0 to 1:= 0;
  signal pipe_enable : std_logic;
  
  	 attribute RAM_STYLE : string;
	 attribute RAM_STYLE of R0: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of R1: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of R2: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of R3: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of R4: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of R5: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of reg_mul01: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of reg_mul23: signal is "DISTRIBUTED";
	 attribute RAM_STYLE of reg_mul45: signal is "DISTRIBUTED";
	 
begin


	process (clock, reset)
	begin
		IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				R0 <= (others => '0');
				R1 <= (others => '0');
				R2 <= (others => '0');
				R3 <= (others => '0');
				R4 <= (others => '0');
				R5 <= (others => '0');				
			ELSE
				IF INPUT_1_valid = '1' THEN
					R5 <= R4;
					R4 <= R3;
					R3 <= R2;
					R2 <= R1;
					R1 <= R0;
					R0 <= INPUT_1;				
				END IF;
			END IF;
		END IF;
	end process;
	-------------------------------------------------------------------------

		Temp01 <= (signed(R0) * signed(R1));
		mul01  <= std_logic_vector(Temp01(42 downto 11));
		Temp23 <= (signed(R2) * signed(R3));
		mul23  <= std_logic_vector(Temp23(42 downto 11));
		Temp45 <= (signed(R4) * signed(R5));
		mul45  <= std_logic_vector(Temp45(42 downto 11));

register_mult : process(clock)
begin
		IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				reg_mul01 <= (others => '0');
				reg_mul23 <= (others => '0');
				reg_mul45 <= (others => '0');
			ELSIF pipe_enable = '1' THEN
				reg_mul01 <= mul01;
				reg_mul23 <= mul23;
				reg_mul45 <= mul45;
			END IF;
		END IF;
end process;

sum1 <= signed(reg_mul01(31)&reg_mul01) + signed(reg_mul23(31)&reg_mul23); -- 33 bits
out_tmp <= sum1(32)&sum1 + signed(reg_mul45(31)&reg_mul45(31)&reg_mul45); -- 34 bits

pipe_ctrl: process (clock)
begin
		IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				counter <= 0;
		   ELSIF INPUT_1_valid = '0' THEN
				IF counter = 1 THEN
					 counter <= 1;
				ELSE
					 counter <= counter + 1;
				END IF;
			ELSE	
				counter <= 0;
		  END IF;
	 END IF;
end process;

pipe_enable <= '0' when counter = 3 else '1';

output_reg: process(clock)
begin
	 IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				OUTPUT_1 <= (others => '0');
			ELSE
				OUTPUT_1 <= std_logic_vector(out_tmp(31 downto 0));
			END IF;
		END IF;
end process;

end; --architecture logic