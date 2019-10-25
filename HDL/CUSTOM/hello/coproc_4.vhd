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

entity coproc_4 is
   port(
		clock          : in  std_logic;
		clock_vga      : in  std_logic;
		reset          : in  std_logic;
		INPUT_1        : in  std_logic_vector(31 downto 0);
		INPUT_1_valid  : in  std_logic;
		OUTPUT_1       : out std_logic_vector(31 downto 0);
		VGA_hs       	: out std_logic;   -- horisontal vga syncr.
      VGA_vs       	: out std_logic;   -- vertical vga syncr.
      VGA_red      	: out std_logic_vector(3 downto 0);   -- red output
      VGA_green    	: out std_logic_vector(3 downto 0);   -- green output
      VGA_blue    	 : out std_logic_vector(3 downto 0)   -- blue output
	);
end; --comb_alu_1

architecture logic of coproc_4 is

component VGA_bitmap_640x480 is
  generic(bit_per_pixel : integer range 1 to 12:=1;    -- number of bits per pixel
          grayscale     : boolean := false);           -- should data be displayed in grayscale
  port(clk          : in  std_logic;
		 clk_VGA      : in  std_logic;
       reset        : in  std_logic;
       VGA_hs       : out std_logic;   -- horisontal vga syncr.
       VGA_vs       : out std_logic;   -- vertical vga syncr.
       VGA_red      : out std_logic_vector(3 downto 0);   -- red output
       VGA_green    : out std_logic_vector(3 downto 0);   -- green output
       VGA_blue     : out std_logic_vector(3 downto 0);   -- blue output

       ADDR         : in  std_logic_vector(18 downto 0);
       data_in      : in  std_logic_vector(bit_per_pixel - 1 downto 0);
       data_write   : in  std_logic;
       data_out     : out std_logic_vector(bit_per_pixel - 1 downto 0));
end component;

	SIGNAL mem : UNSIGNED(31 downto 0);
	signal tmp_addr : std_logic_vector(18 downto 0);
	signal pixel : std_logic_vector(7 downto 0);
	--signal tmp_out : std_logic_vector(10 downto 0);
	signal data_write : std_logic;
	signal counter : integer range 0 to 307199:= 0;
begin
	
	
	
	
	--tmp_addr <= INPUT_1(31 downto 13);
	--pixel <= INPUT_1(7 downto 0);
--	
	process (clock)
	begin
		IF clock'event AND clock = '1' THEN
			IF reset = '1' THEN
				counter <= 0;
			ELSE
				IF INPUT_1_valid = '1' THEN
					IF counter < 307199 THEN
						counter <= counter + 1;
					ELSE
						counter <= 0;
					END IF;
				END IF;
			END IF;
		END IF;
	end process;
--	
--
--	process (clock, reset)
--	begin
--		IF clock'event AND clock = '1' THEN
--			IF reset = '1' THEN
--				tmp_addr <= (others => '1');
--				pixel <= (others => '0');
--				data_write <= '0';
--			ELSE
--				IF INPUT_1_valid = '1' THEN
--					tmp_addr <= INPUT_1(31 downto 13);
--					pixel <= INPUT_1(7 downto 0);
--					data_write <= '1';
--				else
--					data_write <= '0';
--				END IF;
--			END IF;
--		END IF;
--	end process;
--	
	tmp_addr <= std_logic_vector(to_signed(counter, 19));
--	
--		vga : VGA_bitmap_640x480 generic map(12, false)           -- should data be displayed in grayscale
--		port map(
--				clk        => clock,
--				clk_vga    => clock_vga,
--				reset      => reset,
--				VGA_hs     => VGA_hs,
--				VGA_vs     => VGA_vs,
--				VGA_red    => VGA_red,
--				VGA_green  => VGA_green,
--				VGA_blue   => VGA_blue,
--				ADDR       => tmp_addr, 
--				data_in    => INPUT_1(11 downto 0),
--				data_write => INPUT_1_valid,
--				data_out   => open);
	
		OUTPUT_1 <= "0000000000000"&tmp_addr;

	
	
	
--	process (clock)
--	begin
--		IF clock'event AND clock = '1' THEN
--			IF reset = '1' THEN
--				mem <= TO_UNSIGNED( 0, 32);
--			ELSE
--				IF INPUT_1_valid = '1' THEN
----					   assert INPUT_1_valid /= '1' severity failure;
--					mem <= UNSIGNED(INPUT_1) + TO_UNSIGNED( 3, 32);
--				ELSE
--					mem <= mem;					
--				END IF;
--			END IF;
--		END IF;
--	end process;
	-------------------------------------------------------------------------

--	OUTPUT_1 <= STD_LOGIC_VECTOR( mem );
	-------------------------------------------------------------------------
--	process (clock, reset)
--	begin
--		IF clock'event AND clock = '1' THEN
--			IF reset = '1' THEN
--				mem <= TO_UNSIGNED( 0, 32);
--			ELSE
--				IF INPUT_1_valid = '1' THEN
--					mem <= UNSIGNED(INPUT_1) + TO_UNSIGNED( 4, 32);
--				ELSE
--					mem <= mem;
--				END IF;
--			END IF;
--		END IF;
--	end process;
--	-------------------------------------------------------------------------
--
--	OUTPUT_1 <= STD_LOGIC_VECTOR( mem );

end; --architecture logic

