---------------------------------------------------------------------
-- TITLE: Seven segment display controller
-- AUTHOR: Henri
-- DATE CREATED: 2/8/01
-- FILENAME: ctrl_7seg.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Display 32 bit data formatted in hexadecimal
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;

entity ctrl_7seg is
  port(
    clock          : in  std_logic;
    reset          : in  std_logic;
    INPUT_1        : in  std_logic_vector(31 downto 0);
    INPUT_1_valid  : in  std_logic;
    OUTPUT_7s      : out std_logic_vector(6 downto 0);
    DP             : out std_logic;
    AN             : out std_logic_vector(7 downto 0)
  );
end;

architecture logic of ctrl_7seg is
  signal mem : STD_LOGIC_VECTOR(31 downto 0);
  signal s_e0 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e1 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e2 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e3 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e4 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e5 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e6 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_e7 : STD_LOGIC_VECTOR (6 downto 0);
  signal s_cmd : std_logic_vector (2 downto 0);

begin
  process (clock, reset)
  begin
    if reset = '1' then
        mem <= "00000000000000000000000000000000";
    elsif clock'event and clock = '1' then
      if INPUT_1_valid = '1' then
        mem <= INPUT_1;
      end if;
    end if;
  end process;
    -------------------------------------------------------------------------

  trans_hexto7seg_1: entity WORK.trans_hexto7seg port map(
    input_mem => mem,
    e0 => s_e0,
    e1 => s_e1,
    e2 => s_e2,
    e3 => s_e3,
    e4 => s_e4,
    e5 => s_e5,
    e6 => s_e6,
    e7 => s_e7
  );

  mux_7seg_1: entity WORK.mux_7seg port map(
    cmd => s_cmd,
    E0 => s_e0,
    E1 => s_e1,
    E2 => s_e2,
    E3 => s_e3,
    E4 => s_e4,
    E5 => s_e5,
    E6 => s_e6,
    E7 => s_e7,
    DP => DP,
    S => OUTPUT_7s
  );

  mod_7seg_1: entity WORK.mod_7seg port map(
    clk => clock,
    rst => reset,
    AN => AN,
    cmd_mux_7seg => s_cmd
  );

end; --architecture logic
