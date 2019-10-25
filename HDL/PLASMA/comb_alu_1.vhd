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

entity comb_alu_1 is
   port(
		clk       	 : in  std_logic;
		reset_in  	 : in  std_logic;
		a_in         : in  std_logic_vector(31 downto 0);
		b_in         : in  std_logic_vector(31 downto 0);
		alu_function : in  std_logic_vector( 5 downto 0);
		c_alu        : out std_logic_vector(31 downto 0)
	);
end; --comb_alu_1

architecture logic of comb_alu_1 is
	signal HOLDN    		: STD_LOGIC;
	signal CLK_LDPC 		: STD_LOGIC;
	signal ldpc_instruction : STD_LOGIC_VECTOR(12 downto 0);
	signal OUTPUT_LDPC 		: STD_LOGIC_VECTOR(31 downto 0);
	signal sDESIGN_ID 		: STD_LOGIC_VECTOR(31 downto 0);
	signal INTPUT_LDPC 		: STD_LOGIC_VECTOR(31 downto 0);

	SIGNAL RESULT_1  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_2  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_3  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_4  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_5  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_6  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_7  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_8  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_9  : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_10 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_11 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_12 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_13 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_14 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_15 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_16 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_17 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_18 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL RESULT_19 : STD_LOGIC_VECTOR(31 downto 0);
begin

	FX1  : ENTITY WORK.function_1  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_1 );
	FX2  : ENTITY WORK.function_2  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_2 );
	FX3  : ENTITY WORK.function_3  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_3 );
	FX4  : ENTITY WORK.function_4  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_4 );
	FX5  : ENTITY WORK.function_5  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_5 );
	FX6  : ENTITY WORK.function_6  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_6 );
	FX7  : ENTITY WORK.function_7  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_7 );
	FX8  : ENTITY WORK.function_8  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_8 );
	FX9  : ENTITY WORK.function_9  PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_9 );
	FX10 : ENTITY WORK.function_10 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_10 );	
	FX11 : ENTITY WORK.function_11 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_11 );	
	FX12 : ENTITY WORK.function_12 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_12 );
	FX13 : ENTITY WORK.function_13 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_13 );
	FX14 : ENTITY WORK.function_14 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_14 );
	FX15 : ENTITY WORK.function_15 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_15 );
	FX16 : ENTITY WORK.function_16 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_16 );
	FX17 : ENTITY WORK.function_17 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_17 );
	FX18 : ENTITY WORK.function_18 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_18 );
	FX19 : ENTITY WORK.function_19 PORT MAP( INPUT_1  => a_in, INPUT_2  => b_in, OUTPUT_1 => RESULT_19 );
	
	with alu_function select
	c_alu <=
			RESULT_1  WHEN "000001",-- (01)
			RESULT_2  WHEN "000101",-- (05)
			RESULT_3  WHEN "001010",-- (0A)
			RESULT_4  WHEN "011110",-- (1E)
			RESULT_5  WHEN "011111",-- (1F)
			RESULT_6  WHEN "101001",-- (29)
			RESULT_7  WHEN "101100",-- (2C)
			RESULT_8  WHEN "101110",-- (2E)
			RESULT_9  WHEN "101111",-- (2F)
			RESULT_10 WHEN "110000",-- (30)
			RESULT_11 WHEN "110101",-- (35)
			RESULT_12 WHEN "110111",-- (37)
			RESULT_13 WHEN "111000",-- (38)
			RESULT_14 WHEN "111001",-- (39)
			RESULT_15 WHEN "111010",-- (3A)
			RESULT_16 WHEN "111011",-- (3B)
			RESULT_17 WHEN "111100",-- (3C)
			RESULT_18 WHEN "111101",-- (3D)
			RESULT_19 WHEN "111110",-- (3E)
			"00000000000000000000000000000000" WHEN OTHERS;  -- nop

end; --architecture logic
