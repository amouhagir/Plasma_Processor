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

entity coproc_2 is
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		INPUT_1        : in  std_logic_vector(31 downto 0);
		INPUT_1_valid  : in  std_logic;
		OUTPUT_1       : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of coproc_2 is
	signal min_reg : unsigned(7 downto 0);
	signal beta_reg : unsigned(15 downto 0);
	signal beta_tmp : unsigned(15 downto 0);
	signal min_tmp, max_tmp : unsigned(7 downto 0);
	signal store_min_beta : std_logic;
	signal a,b : unsigned(15 downto 0);
	signal OUTPUT_1_tmp : std_logic_vector(31 downto 0);
begin

	-------------------------------------------------------------------------
	scaling_computation : process (INPUT_1, min_reg, beta_reg)
		variable mini  : UNSIGNED(7 downto 0);
		variable data1, data2, data3, data4  : UNSIGNED(7 downto 0);
		variable diff1, diff2, diff3, diff4 : UNSIGNED(7 downto 0);
		variable mult1, mult2, mult3, mult4 : UNSIGNED(23 downto 0);
	begin						 
--		data1 := UNSIGNED( INPUT_1(7 downto 0) );
--		data2 := UNSIGNED( INPUT_1(15 downto 8) );
--		data3 := UNSIGNED( INPUT_1(23 downto 16) );
--		data4 := UNSIGNED( INPUT_1(31 downto 24) );
--		diff1 := data1 - min_reg; -- 8
--		diff2 := data2 - min_reg; -- 8
--		diff3 := data3 - min_reg; -- 8
--		diff4 := data4 - min_reg; -- 8
--		mult1 := diff1 * beta_reg; -- 24
--		mult2 := diff2 * beta_reg; -- 24
--		mult3 := diff3 * beta_reg; -- 24
--		mult4 := diff4 * beta_reg; -- 24
--		OUTPUT_1_tmp(7 downto 0) <= std_logic_vector(mult1(15 downto 8));
--		OUTPUT_1_tmp(15 downto 8) <= std_logic_vector(mult2(15 downto 8));
--		OUTPUT_1_tmp(23 downto 16) <= std_logic_vector(mult3(15 downto 8));
--		OUTPUT_1_tmp(31 downto 24) <= std_logic_vector(mult4(15 downto 8));
	end process;
	-------------------------------------------------------------------------

	max_tmp <= UNSIGNED(INPUT_1(7 downto 0));
	min_tmp <= UNSIGNED(INPUT_1(15 downto 8));
	b <= "00000000"&(max_tmp-min_tmp);
	a <= TO_UNSIGNED( 255, 8)&"00000000";
	--beta_tmp <= divide(TO_UNSIGNED( 255, 8), (max_tmp-min_tmp));
	--beta_tmp <= divide(a,b); --(8,8)
	--beta_tmp <= "00000000"&max_tmp-min_tmp;
	beta_tmp <= (others => '0');
	-------------------------------------------------------------------------
	process (clock, reset)
	begin
		IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				store_min_beta <= '1';
				min_reg <= (others => '0');
				beta_reg <= (others => '0');
				OUTPUT_1 <= (others => '0');
			ELSE
				IF (INPUT_1_valid = '1' and store_min_beta ='1') THEN
					store_min_beta <= '0';
					min_reg <= UNSIGNED(INPUT_1(15 downto 8));
					beta_reg <= beta_tmp;
					OUTPUT_1 <= INPUT_1;
				ELSIF (INPUT_1_valid = '1' and store_min_beta = '0') THEN
				   store_min_beta <= '0';
				   min_reg <= min_reg;
				   beta_reg <= beta_reg;
				   OUTPUT_1 <= OUTPUT_1_tmp;
				   --OUTPUT_1 <= "000000000000000000000000"&std_logic_vector(min_reg);
				END IF;
			END IF;
		END IF;
	end process;
	-------------------------------------------------------------------------

end; --architecture logic
