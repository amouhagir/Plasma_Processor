-- Top-level design for ipbus demo
--
-- This version is for xc6vlx240t on Xilinx ML605 eval board
-- Uses the v6 hard EMAC core with GMII interface to an external Gb PHY
--
-- You must edit this file to set the IP and MAC addresses
--
-- Dave Newbold, May 2011

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use work.ipbus.ALL;
--use work.bus_arb_decl.all;
--use work.mac_arbiter_decl.all;

library unisim;
use unisim.VComponents.all;

entity top_plasma is
   generic(ethernet    : std_logic  := '0';
           eUart       : std_logic  := '1';
           eButtons    : std_logic  := '1';
           eRGBOLED    : std_logic  := '1';
           eSwitchLED  : std_logic  := '1';
           eSevenSegments : std_logic  := '1';
	   ePWM        : std_logic := '1';
           eI2C        : std_logic  := '1';
           eCoproc     : std_logic  := '1';
           eVGA        : std_logic  := '1';
           use_cache   : std_logic  := '0';
           DATA_BITS: integer range 0 to 32 := 8;
           MAX_ADDR: integer := 38423;
           FREQ: integer := 1134);
    port(
	clk100: in std_logic;
	--rst: in std_logic;
	--led: out std_logic_vector(7 downto 0);
   i_uart : in std_logic;
   o_uart : out std_logic;
	VGA_hs       : out std_logic;   -- horisontal vga syncr.
   VGA_vs       : out std_logic;   -- vertical vga syncr.
   VGA_red      : out std_logic_vector(3 downto 0);   -- red output
   VGA_green    : out std_logic_vector(3 downto 0);   -- green output
   VGA_blue     : out std_logic_vector(3 downto 0);   -- blue output
   sw           : in  std_logic_vector(15 downto 0);
   led          : out std_logic_vector(15 downto 0);

   RGB1_Red     : out std_logic;
   RGB1_Green   : out std_logic;
   RGB1_Blue    : out std_logic;
   RGB2_Red     : out std_logic;
   RGB2_Green   : out std_logic;
   RGB2_Blue    : out std_logic;

   seg          : out std_logic_vector(6 downto 0);
   DP           : out std_logic;
   an           : out std_logic_vector(7 downto 0);



   btnCpuReset  : in std_logic;
   btnC         : in std_logic;
   btnU         : in std_logic;
   btnL         : in std_logic;
   btnR         : in std_logic;
   btnD         : in std_logic;

i2c_sda_tmp  : inout std_logic;
i2c_scl_tmp  : inout std_logic;
i2c_sda_pmod : inout std_logic;
i2c_scl_pmod : inout std_logic;

OLED_PMOD_CS      	: out STD_LOGIC;
OLED_PMOD_MOSI    	: out STD_LOGIC;
OLED_PMOD_SCK     	: out STD_LOGIC;
OLED_PMOD_DC      	: out STD_LOGIC;
OLED_PMOD_RES     	: out STD_LOGIC;
OLED_PMOD_VCCEN   	: out STD_LOGIC;
OLED_PMOD_EN      	: out STD_LOGIC;
	    
	ampSD: out STD_LOGIC;
        odata: out STD_LOGIC
	);
end top_plasma;

architecture rtl of top_plasma is
		signal clk50, clk100_sig: std_logic;
		signal rst : std_logic;

   signal led_tmp          : std_logic_vector(15 downto 0);

   signal RGB1_Red_tmp     : std_logic;
   signal RGB1_Green_tmp   : std_logic;
   signal RGB1_Blue_tmp    : std_logic;
   signal RGB2_Red_tmp     : std_logic;
   signal RGB2_Green_tmp   : std_logic;
   signal RGB2_Blue_tmp    : std_logic;

   signal seg_tmp          : std_logic_vector(6 downto 0);
   signal an_tmp           : std_logic_vector(7 downto 0);

begin

   rst <= not btnCpuReset;



--	DCM clock generation for internal bus, ethernet
--clock_gen : clk_wiz_0 -- vivado
--clock_gen : clkgen -- ise
--  port map
--   (-- Clock in ports
--    CLK_IN1 => clk100,
--    -- Clock out ports
--    CLK_OUT1 => clk50,
--	 CLK_OUT2 => clk100_sig);


clk_div : process(clk100, rst)
begin
	if(rst='1') then
		clk50 <= '0';
	elsif(clk100'event and clk100 = '1') then
		clk50 <= not(clk50);
	end if;
end process;



	Inst_plasma: entity work.plasma
	GENERIC MAP (
		memory_type => "XILINX_16X",
		log_file    => "UNUSED",
		ethernet    => ethernet,
		eUart       => eUart,
		eButtons    => eButtons,
		eRGBOLED    => eRGBOLED,
		eSwitchLED  => eSwitchLED,
		eSevenSegments => eSevenSegments,
	        ePWM        => ePWM,
		eI2C        => eI2C,
		eCoproc     => eCoproc,
		eVGA        => eVGA,
		use_cache   => use_cache,
		DATA_BITS => DATA_BITS, 
		MAX_ADDR => MAX_ADDR,
		FREQ => FREQ
	)
	PORT MAP(
		clk           => clk50,
		clk_VGA       => clk100,
		reset         => rst,
		uart_write    => o_uart,
		uart_read     => i_uart,
		fifo_1_out_data  => x"00000000",
		fifo_1_read_en   => open,
		fifo_1_empty     => '1',
		fifo_2_in_data   => open,
		fifo_1_write_en  => open,
		fifo_2_full      => '0',

		fifo_1_full      => '0',
		fifo_1_valid     => '0',
		fifo_2_empty     => '1',
		fifo_2_valid     => '0',
		fifo_1_compteur  => x"00000000",
		fifo_2_compteur  => x"00000000",

		VGA_hs => VGA_hs,
		VGA_vs => VGA_vs,
		VGA_red => VGA_red,
		VGA_green => VGA_green,
		VGA_blue => VGA_blue,

		sw        => sw,
		led       => led,

		RGB1_Red => RGB1_Red,
		RGB1_Green => RGB1_Green,
		RGB1_Blue => RGB1_Blue,
		RGB2_Red => RGB2_Red,
 		RGB2_Green => RGB2_Green,
       		RGB2_Blue => RGB2_Blue,

		seg         => seg,
		DP          => DP,
		an          => an,

		btnCpuReset => btnCpuReset,
		btnC => btnC,
		btnU => btnU,
		btnL => btnL,
		btnR => btnR,
		btnD => btnD,

		i2c_sda_tmp => i2c_sda_tmp,
		i2c_scl_tmp => i2c_scl_tmp,
		i2c_sda_pmod => i2c_sda_pmod,
		i2c_scl_pmod => i2c_scl_pmod,

		OLED_PMOD_CS	=> OLED_PMOD_CS,
		OLED_PMOD_MOSI  => OLED_PMOD_MOSI,
		OLED_PMOD_SCK   => OLED_PMOD_SCK,
		OLED_PMOD_DC    => OLED_PMOD_DC,
		OLED_PMOD_RES   => OLED_PMOD_RES,
		OLED_PMOD_VCCEN => OLED_PMOD_VCCEN,
		OLED_PMOD_EN    => OLED_PMOD_EN,

		gpio0_out       => open,
		gpioA_in        => x"00000000", --open
		
		ampSD           => ampSD, 
		odata           => odata
	);


end rtl;
