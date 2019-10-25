---------------------------------------------------------------------
-- TITLE: Arithmetic Logic Unit
-- AUTHOR: Henri
-- DATE CREATED: 2/8/01
-- FILENAME: trans_hexto7seg.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Transcode 8 hexadecimal characters (32 bit input -> 8 hexa characters of
--    4 bits each) into 8 seven segment characters.
---------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity trans_hexto7seg is
  Port ( input_mem : in STD_LOGIC_VECTOR (31 downto 0);
    e0 : out STD_LOGIC_VECTOR (6 downto 0);
    e1 : out STD_LOGIC_VECTOR (6 downto 0);
    e2 : out STD_LOGIC_VECTOR (6 downto 0);
    e3 : out STD_LOGIC_VECTOR (6 downto 0);
    e4 : out STD_LOGIC_VECTOR (6 downto 0);
    e5 : out STD_LOGIC_VECTOR (6 downto 0);
    e6 : out STD_LOGIC_VECTOR (6 downto 0);
    e7 : out STD_LOGIC_VECTOR (6 downto 0)
  );
end trans_hexto7seg;

architecture Behavioral of trans_hexto7seg is

  CONSTANT zero : STD_LOGIC_VECTOR (6 downto 0) := "1000000";
  CONSTANT one : STD_LOGIC_VECTOR (6 downto 0) := "1111001";
  CONSTANT two : STD_LOGIC_VECTOR (6 downto 0) := "0100100";
  CONSTANT three : STD_LOGIC_VECTOR (6 downto 0) := "0110000";
  CONSTANT four : STD_LOGIC_VECTOR (6 downto 0) := "0011001";
  CONSTANT five : STD_LOGIC_VECTOR (6 downto 0) := "0010010";
  CONSTANT six : STD_LOGIC_VECTOR (6 downto 0) := "0000010";
  CONSTANT seven : STD_LOGIC_VECTOR (6 downto 0) := "1111000";
  CONSTANT eight : STD_LOGIC_VECTOR (6 downto 0) := "0000000";
  CONSTANT nine : STD_LOGIC_VECTOR (6 downto 0) := "0010000";
  CONSTANT xA : STD_LOGIC_VECTOR (6 downto 0) := "0001000";
  CONSTANT xB : STD_LOGIC_VECTOR (6 downto 0) := "0000011";
  CONSTANT xC : STD_LOGIC_VECTOR (6 downto 0) := "1000110";
  CONSTANT xD : STD_LOGIC_VECTOR (6 downto 0) := "0100001";
  CONSTANT xE : STD_LOGIC_VECTOR (6 downto 0) := "0000110";
  CONSTANT xF : STD_LOGIC_VECTOR (6 downto 0) := "0001110";



  signal q0 : integer range 0 to 15 :=0;
  signal q1 : integer range 0 to 15 :=0;
  signal q2 : integer range 0 to 15 :=0;
  signal q3 : integer range 0 to 15 :=0;
  signal q4 : integer range 0 to 15 :=0;
  signal q5 : integer range 0 to 15 :=0;
  signal q6 : integer range 0 to 15 :=0;
  signal q7 : integer range 0 to 15 :=0;

begin
  
  q0 <= to_integer( unsigned( input_mem( 31 downto 28 ) ) );
  q1 <= to_integer( unsigned( input_mem( 27 downto 24 ) ) );
  q2 <= to_integer( unsigned( input_mem( 23 downto 20 ) ) );
  q3 <= to_integer( unsigned( input_mem( 19 downto 16 ) ) );
  q4 <= to_integer( unsigned( input_mem( 15 downto 12 ) ) );
  q5 <= to_integer( unsigned( input_mem( 11 downto 8 ) ) );
  q6 <= to_integer( unsigned( input_mem( 7 downto 4 ) ) );
  q7 <= to_integer( unsigned( input_mem( 3 downto 0 ) ) );

  process(q0,q1,q2,q3,q4,q5,q6,q7)
  begin
    case q0 is
      when 0 => e0 <= zero;
      when 1 => e0 <= one;
      when 2 => e0 <= two;
      when 3 => e0 <= three;
      when 4 => e0 <= four;
      when 5 => e0 <= five;
      when 6 => e0 <= six;
      when 7 => e0 <= seven;
      when 8 => e0 <= eight;
      when 9 => e0 <= nine;
      when 10 => e0 <= xA;
      when 11 => e0 <= xB;
      when 12 => e0 <= xC;
      when 13 => e0 <= xD;
      when 14 => e0 <= xE;
      when 15 => e0 <= xF;
      when others => e0 <= zero;
    end case;

    case q1 is
      when 0 => e1 <= zero;
      when 1 => e1 <= one;
      when 2 => e1 <= two;
      when 3 => e1 <= three;
      when 4 => e1 <= four;
      when 5 => e1 <= five;
      when 6 => e1 <= six;
      when 7 => e1 <= seven;
      when 8 => e1 <= eight;
      when 9 => e1 <= nine;
      when 10 => e1 <= xA;
      when 11 => e1 <= xB;
      when 12 => e1 <= xC;
      when 13 => e1 <= xD;
      when 14 => e1 <= xE;
      when 15 => e1 <= xF;
      when others => e1 <= zero;
    end case;

    case q2 is
      when 0 => e2 <= zero;
      when 1 => e2 <= one;
      when 2 => e2 <= two;
      when 3 => e2 <= three;
      when 4 => e2 <= four;
      when 5 => e2 <= five;
      when 6 => e2 <= six;
      when 7 => e2 <= seven;
      when 8 => e2 <= eight;
      when 9 => e2 <= nine;
      when 10 => e2 <= xA;
      when 11 => e2 <= xB;
      when 12 => e2 <= xC;
      when 13 => e2 <= xD;
      when 14 => e2 <= xE;
      when 15 => e2 <= xF;
      when others => e2 <= zero;
    end case;

    case q3 is
      when 0 => e3 <= zero;
      when 1 => e3 <= one;
      when 2 => e3 <= two;
      when 3 => e3 <= three;
      when 4 => e3 <= four;
      when 5 => e3 <= five;
      when 6 => e3 <= six;
      when 7 => e3 <= seven;
      when 8 => e3 <= eight;
      when 9 => e3 <= nine;
      when 10 => e3 <= xA;
      when 11 => e3 <= xB;
      when 12 => e3 <= xC;
      when 13 => e3 <= xD;
      when 14 => e3 <= xE;
      when 15 => e3 <= xF;
      when others => e3 <= zero;
    end case;

    case q4 is
      when 0 => e4 <= zero;
      when 1 => e4 <= one;
      when 2 => e4 <= two;
      when 3 => e4 <= three;
      when 4 => e4 <= four;
      when 5 => e4 <= five;
      when 6 => e4 <= six;
      when 7 => e4 <= seven;
      when 8 => e4 <= eight;
      when 9 => e4 <= nine;
      when 10 => e4 <= xA;
      when 11 => e4 <= xB;
      when 12 => e4 <= xC;
      when 13 => e4 <= xD;
      when 14 => e4 <= xE;
      when 15 => e4 <= xF;
      when others => e4 <= zero;
    end case;

    case q5 is
      when 0 => e5 <= zero;
      when 1 => e5 <= one;
      when 2 => e5 <= two;
      when 3 => e5 <= three;
      when 4 => e5 <= four;
      when 5 => e5 <= five;
      when 6 => e5 <= six;
      when 7 => e5 <= seven;
      when 8 => e5 <= eight;
      when 9 => e5 <= nine;
      when 10 => e5 <= xA;
      when 11 => e5 <= xB;
      when 12 => e5 <= xC;
      when 13 => e5 <= xD;
      when 14 => e5 <= xE;
      when 15 => e5 <= xF;
      when others => e5 <= zero;
    end case;

    case q6 is
      when 0 => e6 <= zero;
      when 1 => e6 <= one;
      when 2 => e6 <= two;
      when 3 => e6 <= three;
      when 4 => e6 <= four;
      when 5 => e6 <= five;
      when 6 => e6 <= six;
      when 7 => e6 <= seven;
      when 8 => e6 <= eight;
      when 9 => e6 <= nine;
      when 10 => e6 <= xA;
      when 11 => e6 <= xB;
      when 12 => e6 <= xC;
      when 13 => e6 <= xD;
      when 14 => e6 <= xE;
      when 15 => e6 <= xF;
      when others => e6 <= zero;
    end case;

    case q7 is
      when 0 => e7 <= zero;
      when 1 => e7 <= one;
      when 2 => e7 <= two;
      when 3 => e7 <= three;
      when 4 => e7 <= four;
      when 5 => e7 <= five;
      when 6 => e7 <= six;
      when 7 => e7 <= seven;
      when 8 => e7 <= eight;
      when 9 => e7 <= nine;
      when 10 => e7 <= xA;
      when 11 => e7 <= xB;
      when 12 => e7 <= xC;
      when 13 => e7 <= xD;
      when 14 => e7 <= xE;
      when 15 => e7 <= xF;
      when others => e7 <= zero;
    end case;

  end process;

end Behavioral;
