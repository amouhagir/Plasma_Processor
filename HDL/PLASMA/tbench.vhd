---------------------------------------------------------------------
-- TITLE: Test Bench
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 4/21/01
-- FILENAME: tbench.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity provides a test bench for testing the Plasma CPU core.
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.mlite_pack.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY tbench IS
END;  --entity tbench

ARCHITECTURE logic OF tbench IS
    CONSTANT memory_type : STRING :=
--   "TRI_PORT_X";   
	"DUAL_PORT_";
--   "ALTERA_LPM";
--   "XILINX_16X";

    CONSTANT log_file : STRING :=
--   "UNUSED";
	"output.txt";

    SIGNAL clk		: STD_LOGIC			:= '1';
    SIGNAL reset	: STD_LOGIC			:= '1';
    SIGNAL interrupt	: STD_LOGIC			:= '0';
    --signal mem_write	 : std_logic;
    SIGNAL address	: STD_LOGIC_VECTOR(31 DOWNTO 2);
    SIGNAL data_write	: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL data_read	: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pause1	: STD_LOGIC			:= '0';
    SIGNAL pause2	: STD_LOGIC			:= '0';
    SIGNAL pause	: STD_LOGIC;
    SIGNAL no_ddr_start : STD_LOGIC;
    SIGNAL no_ddr_stop	: STD_LOGIC;
    SIGNAL byte_we	: STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL uart_write	: STD_LOGIC;
    SIGNAL gpioA_in	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    --
    -- SIGNAUX PERMETTANT D'INTERCONNECTER LE PROCESSEUR AVEC LE BUS PCIe
    -- EN SIMULATION CES DERNIERS SONT CABLES A LA MASSE (PAS DE PCIe)
    --
    SIGNAL fifo_1_out_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL fifo_1_compteur : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL fifo_2_compteur : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL fifo_2_in_data  : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL fifo_1_read_en  : STD_LOGIC;
    SIGNAL fifo_1_empty	   : STD_LOGIC;
    SIGNAL fifo_2_write_en : STD_LOGIC;
    SIGNAL fifo_2_full	   : STD_LOGIC;
    SIGNAL fifo_1_full	   : STD_LOGIC;
    SIGNAL fifo_1_valid	   : STD_LOGIC;
    SIGNAL fifo_2_empty	   : STD_LOGIC;
    SIGNAL fifo_2_valid	   : STD_LOGIC;
    
    SIGNAL clk_VGA : STD_LOGIC:='0';
    
    signal led          : std_logic_vector(15 downto 0);
    signal sw           : std_logic_vector(15 downto 0);
    
    signal RGB1_Red     : std_logic;
    signal RGB1_Green   : std_logic;
    signal RGB1_Blue    : std_logic;
    signal RGB2_Red     : std_logic;
    signal RGB2_Green   : std_logic;
    signal RGB2_Blue    : std_logic;
    
    signal btnCpuReset : std_logic;
    signal btnC  : std_logic;
    signal btnU  : std_logic;
    signal btnL  : std_logic;
    signal btnR  : std_logic;
    signal btnD  : std_logic;
    
    signal seg          : std_logic_vector(6 downto 0);
    signal DP           : std_logic;
    signal an           : std_logic_vector(7 downto 0);
    
signal i2c_sda_tmp  : std_logic;
signal i2c_scl_tmp  : std_logic;
signal i2c_sda_pmod : std_logic;
signal i2c_scl_pmod : std_logic;

signal OLED_PMOD_CS      	: STD_LOGIC;
signal OLED_PMOD_MOSI    	: STD_LOGIC;
signal OLED_PMOD_SCK     	: STD_LOGIC;
signal OLED_PMOD_DC      	: STD_LOGIC;
signal OLED_PMOD_RES     	: STD_LOGIC;
signal OLED_PMOD_VCCEN   	: STD_LOGIC;
signal OLED_PMOD_EN      	: STD_LOGIC;
signal ampSD           : std_logic;    
signal odata           : std_logic;

--component plasma is
--   generic(memory_type : string := "XILINX_16X"; --"DUAL_PORT_" "ALTERA_LPM";
--           log_file    : string := "UNUSED";
--           ethernet    : std_logic  := '0';
--           eUart       : std_logic  := '0';
--           use_cache   : std_logic  := '0');
--   port(clk          : in std_logic;
--   				clk_VGA : in std_logic;
--				reset        : in std_logic;

--				uart_write   : out std_logic;
--				uart_read    : in std_logic;

--				address      : out std_logic_vector(31 downto 2);
--				byte_we      : out std_logic_vector(3  downto 0); 
--				--data_write   : out std_logic_vector(31 downto 0);
--				--data_read    : in  std_logic_vector(31 downto 0);
--				---mem_pause_in : in std_logic;
--				no_ddr_start : out std_logic;
--				no_ddr_stop  : out std_logic;
        
--				-- BLG START
--				fifo_1_out_data  : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
--				fifo_1_read_en   : OUT STD_LOGIC;
--				fifo_1_empty     : IN  STD_LOGIC;
--				fifo_2_in_data   : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
--				fifo_1_write_en  : OUT STD_LOGIC;
--				fifo_2_full      : IN  STD_LOGIC;
	 
--				fifo_1_full      : IN STD_LOGIC;
--				fifo_1_valid     : IN STD_LOGIC;
--				fifo_2_empty     : IN STD_LOGIC;
--				fifo_2_valid     : IN STD_LOGIC;
--				fifo_1_compteur  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
--				fifo_2_compteur  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				
--                                VGA_hs       : out std_logic;   -- horisontal vga syncr.
--                                VGA_vs       : out std_logic;   -- vertical vga syncr.
--                                VGA_red      : out std_logic_vector(3 downto 0);   -- red output
--                                VGA_green    : out std_logic_vector(3 downto 0);   -- green output
--                                VGA_blue     : out std_logic_vector(3 downto 0);   -- blue output

--				-- BLG END

--				gpio0_out    : out std_logic_vector(31 downto 0);
--				gpioA_in     : in  std_logic_vector(31 downto 0));
--end component; --entity plasma


BEGIN  --architecture
    --Uncomment the line below to test interrupts
    interrupt <= '1' AFTER 20 us WHEN interrupt = '0' ELSE '0' AFTER 445 ns;

    clk	   <= NOT clk AFTER 50 ns;
    clk_VGA	   <= NOT clk_VGA AFTER 25 ns;
    reset  <= '0'     AFTER 500 ns;
    pause1 <= '1'     AFTER 700 ns WHEN pause1 = '0' ELSE '0' AFTER 200 ns;
    pause2 <= '1'     AFTER 300 ns WHEN pause2 = '0' ELSE '0' AFTER 200 ns;
    pause  <= pause1 OR pause2;


    gpioA_in(7 DOWNTO 0) <= "00000010";

    u1_plasma : entity work.plasma
	GENERIC MAP (
	    memory_type => memory_type,
	    ethernet	=> '1',
	    eUart	=> '1',
	    eButtons    => '1',
	    eRGBOLED    => '1',
	    eSwitchLED  => '1',
	    eSevenSegments => '1',
	    eI2C        => '1',
	    use_cache	=> '0',
	    log_file	=> log_file
	    )
	PORT MAP (
	    clk		    => clk,
	    clk_VGA 	    => clk_VGA,
	    reset	    => reset,
	    uart_read	    => uart_write,
	    uart_write	    => uart_write,
	    address	    => open,
	    byte_we	    => open,
	    --data_write	    => open,
	    --data_read	    => data_read,
	   -- mem_pause_in    => pause,
	    -- BLG START
	    fifo_1_out_data => fifo_1_out_data,
	    fifo_1_read_en  => fifo_1_read_en,
	    fifo_1_empty    => fifo_1_empty,
	    fifo_2_in_data  => fifo_2_in_data,
	    fifo_1_write_en => fifo_2_write_en,
	    fifo_2_full	    => fifo_2_full,
	    fifo_1_full	    => fifo_1_full,
	    fifo_1_valid    => fifo_1_valid,
	    fifo_2_empty    => fifo_2_empty,
	    fifo_2_valid    => fifo_2_valid,
	    fifo_1_compteur => fifo_1_compteur,
	    fifo_2_compteur => fifo_2_compteur,
	    
	    VGA_hs => open,
		VGA_vs => open,
		VGA_red => open,
		VGA_green => open,
		VGA_blue => open,
	    
	    sw        => sw,
        led       => led,
        
        RGB1_Red => RGB1_Red,
        RGB1_Green => RGB1_Green,
        RGB1_Blue => RGB1_Blue,
        RGB2_Red => RGB2_Red,
        RGB2_Green => RGB2_Green,
        RGB2_Blue => RGB2_Blue,
        
        seg         => seg,
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

	    -- BLG END
	   -- no_ddr_start    => no_ddr_start,
	    --no_ddr_stop	    => no_ddr_stop,
	    gpio0_out	    => OPEN,
	    gpioA_in	    => gpioA_in,
		ampSD           => ampSD, 
		odata           => odata
	    );

	sw <= x"2818";

END;  --architecture logic
