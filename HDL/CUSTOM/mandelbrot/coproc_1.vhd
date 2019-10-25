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

component Iterator is
    Port ( go : in STD_LOGIC;
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;
		x0_y0 : STD_LOGIC_VECTOR (31 downto 0);
		x0 : in STD_LOGIC_VECTOR (31 downto 0);
		y0 : in STD_LOGIC_VECTOR (31 downto 0);
		itermax : in std_logic_vector(11 downto 0);
		iters : out STD_LOGIC_VECTOR (11 downto 0);
		done : out STD_LOGIC);
end component;

signal iters : STD_LOGIC_VECTOR (11 downto 0);
signal done : std_logic;

begin

inst_iterator : Iterator port map(
go => INPUT_1_valid,
clock => clock,
reset => reset,
x0_y0 => INPUT_1,
x0 => (others => '0'),
y0 => (others => '0'),
itermax => x"0FF",
iters => iters,
done => done);

OUTPUT_1 <= done&"0000000000000000000"&iters;

end; --architecture logic
