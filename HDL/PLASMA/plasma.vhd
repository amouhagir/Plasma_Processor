---------------------------------------------------------------------
-- TITLE: Plasma (CPU core with memory)
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 6/4/02
-- FILENAME: plasma.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity combines the CPU core with memory and a UART.
--
-- Memory Map:
--   0x00000000 - 0x0000ffff   Internal RAM (8KB) - 0000 0000 0000
--   0x10000000 - 0x100fffff   External RAM (1MB) - 0001 0000 0000

--   Access all Misc registers with 32-bit accesses
--   0x20000000  Uart Write (will pause CPU if busy)
--   0x20000000  Uart Read
--   0x20000010  IRQ Mask
--   0x20000020  IRQ Status
--   0x20000030  GPIO0 Out Set bits
--   0x20000040  GPIO0 Out Clear bits
--   0x20000050  GPIOA In
--   0x20000060  Counter
--   0x20000070  Ethernet transmit count
--   IRQ bits:
--      7   GPIO31
--      6  ^GPIO31
--      5   EthernetSendDone
--      4   EthernetReceive
--      3   Counter(18)
--      2  ^Counter(18)
--      1  ^UartWriteBusy
--      0   UartDataAvailable
--   0x30000000  FIFO IN  EMPTY
--   0x30000010  FIFO OUT EMPTY
--   0x30000020  FIFO IN  VALID
--   0x30000030  FIFO OUT VALID
--   0x30000040  FIFO IN  FULL
--   0x30000050  FIFO IN  FULL
--   0x30000060  FIFO IN  COUNTER
--   0x30000070  FIFO OUT COUNTER
--   0x30000080  FIFO IN  READ DATA
--   0x30000090  FIFO OUT WRITE DATA
--   0x40000000  COPROCESSOR 1 (reset)
--   0x40000010  COPROCESSOR 1 (input/output)

--   0x40000030  COPROCESSOR 2 (reset)
--   0x40000040  COPROCESSOR 2 (input/output)

--   0x40000060  COPROCESSOR 3 (reset)
--   0x40000070  COPROCESSOR 3 (input/output)

--   0x40000090  COPROCESSOR 4 (reset)
--   0x400000A0  COPROCESSOR 4 (input/output)

--   0x40000090  OLED (reset)
--   0x400000A0  OLED (input/output)

--   0x400000C0  CONTROLLER SWITCH LED (reset)
--   0x400000D0  CONTROLLER SWITCH LED (input/output)

--   0x40000100  Buttons controller values
--   0x40000104  Buttons controller change

--   0x40000200  Seven segment display input
--   0x40000204  Seven segment display reset

--   0x80000000  DMA ENGINE (NOT WORKING YET)
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.mlite_pack.all;

entity plasma is
   generic(memory_type : string := "XILINX_16X"; --"DUAL_PORT_" "ALTERA_LPM";
           log_file    : string := "UNUSED";
           ethernet    : std_logic;
           eUart       : std_logic;
           eButtons    : std_logic;
           eRGBOLED    : std_logic;
           eSwitchLED  : std_logic;
           eSevenSegments : std_logic;
	   ePWM        : std_logic;
           eI2C        : std_logic;
           eCoproc     : std_logic;
           eVGA        : std_logic;
           use_cache   : std_logic;
           CLK_FREQ_HZ : integer := 100000000;        -- by default, we run at 100MHz
           BPP         : integer range 1 to 16 := 16; -- bits per pixel
           GREYSCALE   : boolean := False;			-- color or greyscale ? (only for BPP>6)
           MAX_ON_TOP  : boolean := True;
           LEFT_SIDE   : boolean := False;
           DATA_BITS: integer range 0 to 32 := 8;
           MAX_ADDR: integer := 38423;
           FREQ: integer := 1134 );
   port(clk          : in std_logic;
			clk_VGA			: in std_logic;
				reset        : in std_logic;

				uart_write   : out std_logic;
				uart_read    : in std_logic;

				address      : out std_logic_vector(31 downto 2);
				byte_we      : out std_logic_vector(3  downto 0);
				--data_write   : out std_logic_vector(31 downto 0);
				--data_read    : in  std_logic_vector(31 downto 0);
				---mem_pause_in : in std_logic;
				no_ddr_start : out std_logic;
				no_ddr_stop  : out std_logic;

				-- BLG START
				fifo_1_out_data  : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
				fifo_1_read_en   : OUT STD_LOGIC;
				fifo_1_empty     : IN  STD_LOGIC;
				fifo_2_in_data   : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
				fifo_1_write_en  : OUT STD_LOGIC;
				fifo_2_full      : IN  STD_LOGIC;

				fifo_1_full      : IN STD_LOGIC;
				fifo_1_valid     : IN STD_LOGIC;
				fifo_2_empty     : IN STD_LOGIC;
				fifo_2_valid     : IN STD_LOGIC;
				fifo_1_compteur  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				fifo_2_compteur  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				-- BLG END

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

				OLED_PMOD_CS      	: out STD_LOGIC;
				OLED_PMOD_MOSI    	: out STD_LOGIC;
 				OLED_PMOD_SCK     	: out STD_LOGIC;
				OLED_PMOD_DC      	: out STD_LOGIC;
 				OLED_PMOD_RES     	: out STD_LOGIC;
				OLED_PMOD_VCCEN   	: out STD_LOGIC;
				OLED_PMOD_EN      	: out STD_LOGIC;


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

				gpio0_out    : out std_logic_vector(31 downto 0);
				gpioA_in     : in  std_logic_vector(31 downto 0);
				
				ampSD: out std_logic;
				odata: out std_logic
				);
end; --entity plasma

architecture logic of plasma is
   signal address_next      : std_logic_vector(31 downto 2);
   signal byte_we_next      : std_logic_vector(3 downto 0);
   signal cpu_address       : std_logic_vector(31 downto 0);
   signal cpu_byte_we       : std_logic_vector(3 downto 0);
   signal cpu_data_w        : std_logic_vector(31 downto 0);
   signal cpu_data_r        : std_logic_vector(31 downto 0);
   signal cpu_pause         : std_logic;

   signal ppcie_rdata       : std_logic_vector(31 downto 0);

   signal data_read_uart    : std_logic_vector(7 downto 0);
   signal data_vga_read     : std_logic_vector(31 downto 0);
   signal write_enable      : std_logic;
   signal eth_pause_in      : std_logic;
   signal eth_pause         : std_logic;
   signal mem_busy          : std_logic;
   
   signal enable_ram_vga    : std_logic;
   signal vga_ram_we        : std_logic;
   signal ram_data_vga      : std_logic_vector(11 downto 0);
   
   signal enable_misc       : std_logic;
   signal enable_uart       : std_logic;
   signal enable_uart_read  : std_logic;
   signal enable_uart_write : std_logic;
   signal enable_eth        : std_logic;
   signal enable_local_mem  : std_logic;
   signal enable_buttons    : std_logic;
   signal enable_i2c        : std_logic;
   signal enable_vga        : std_logic;
   signal enable_vga_read   : std_logic;
   signal enable_vga_write  : std_logic;
   signal ctrl_7seg_valid   : std_logic;
   signal ctrl_7seg_reset   : std_logic;

  signal oled_pinout        : std_logic_vector(6 downto 0);

   signal ctrl_SL_reset     : std_logic;
   signal ctrl_SL_valid	    : std_logic;
   signal ctrl_SL_output    : std_logic_vector(31 downto 0);

   signal oled_mux    : std_logic_vector(31 downto 0);
   signal oledcharmap_reset   	: std_logic;
   signal oledcharmap_valid	: std_logic;
   signal oledcharmap_output  	: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
   signal oledcharmap_pinout	: std_logic_vector(6 downto 0);
   signal oledcharmap_use 	: std_logic;
   signal oledcharmap_use_signal : std_logic;
   signal oledterminal_reset  	: std_logic;
   signal oledterminal_valid	: std_logic;
   signal oledterminal_output 	: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
   signal oledterminal_pinout	: std_logic_vector(6 downto 0);
   signal oledterminal_use 	: std_logic;

   signal oledbitmap_reset  : std_logic;
   signal oledbitmap_valid  : std_logic;
   signal oledbitmap_output : std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
   signal oledbitmap_pinout : std_logic_vector(6 downto 0);
   signal oledbitmap_use    : std_logic;

   signal olednibblemap_reset   : std_logic;
   signal olednibblemap_valid	: std_logic;
   signal olednibblemap_output  : std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
   signal olednibblemap_pinout	: std_logic_vector(6 downto 0);
   signal olednibblemap_use 	: std_logic;

   signal oledsigplot_reset : std_logic;
   signal oledsigplot_valid	: std_logic;
   signal oledsigplot_output: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
   signal oledsigplot_pinout: std_logic_vector(6 downto 0);
   signal oledsigplot_use 	: std_logic;

   signal buttons_values    : std_logic_vector(31 downto 0);
   signal buttons_change    : std_logic_vector(31 downto 0);

   signal i2c_addr          : std_logic_vector(31 downto 0);
   signal i2c_status        : std_logic_vector(31 downto 0);
   signal i2c_status_pmod   : std_logic_vector(31 downto 0);
   signal i2c_status_tmp    : std_logic_vector(31 downto 0);
   signal i2c_control       : std_logic_vector(31 downto 0);
   signal i2c_control_out   : std_logic_vector(31 downto 0);
   signal i2c_control_out_pmod   : std_logic_vector(31 downto 0);
   signal i2c_control_out_tmp   : std_logic_vector(31 downto 0);
   signal i2c_control_update_out : std_logic;
   signal i2c_control_update_out_pmod  : std_logic;
   signal i2c_control_update_out_tmp  : std_logic;
   signal i2c_data          : std_logic_vector(31 downto 0);
   signal i2c_data_out      : std_logic_vector(31 downto 0);
   signal i2c_data_out_pmod : std_logic_vector(31 downto 0);
   signal i2c_data_out_tmp  : std_logic_vector(31 downto 0);
   signal i2c_data_update_out  : std_logic;
   signal i2c_data_update_out_pmod  : std_logic;
   signal i2c_data_update_out_tmp  : std_logic;
   signal i2c_clock_enable  : std_logic;
   signal i2c_clock_enable_pmod  : std_logic;
   signal i2c_clock_enable_tmp  : std_logic;
   signal i2c_scl_signal    : std_logic;
   signal i2c_mid           : std_logic;
   signal i2c_access_pmod   : std_logic;
   signal i2c_access_tmp    : std_logic;

   signal gpio0_reg         : std_logic_vector(31 downto 0);
   signal uart_write_busy   : std_logic;
   signal uart_data_avail   : std_logic;
   signal irq_mask_reg      : std_logic_vector(7 downto 0);
   signal irq_status        : std_logic_vector(7 downto 0);
   signal irq               : std_logic;
   signal irq_eth_rec       : std_logic;
   signal irq_eth_send      : std_logic;
   signal counter_reg       : std_logic_vector(31 downto 0);

   signal ram_boot_enable   : std_logic;
   signal ram_enable        : std_logic;
   signal ram_byte_we       : std_logic_vector( 3 downto 0);
   signal ram_address       : std_logic_vector(31 downto 2);
   signal ram_data_w        : std_logic_vector(31 downto 0);
   signal ram_data_r        : std_logic_vector(31 downto 0);
   signal ram_data_lm       : std_logic_vector(31 downto 0);

   signal dma_address       : std_logic_vector(31 downto 0);
   signal dma_byte_we       : std_logic_vector( 3 downto 0);
   signal dma_data_write    : std_logic_vector(31 downto 0);
   signal dma_data_read     : std_logic_vector(31 downto 0);
   signal dma_start         : std_logic;

   signal cop_1_reset       : std_logic;
   signal cop_1_valid       : std_logic;
   signal cop_1_output      : std_logic_vector(31 downto 0);
   signal cop_2_reset       : std_logic;
   signal cop_2_valid       : std_logic;
   signal cop_2_output      : std_logic_vector(31 downto 0);
   signal cop_3_reset       : std_logic;
   signal cop_3_valid       : std_logic;
   signal cop_3_output      : std_logic_vector(31 downto 0);
   signal cop_4_reset       : std_logic;
   signal cop_4_valid       : std_logic;
   signal cop_4_output      : std_logic_vector(31 downto 0);

   signal cache_access      : std_logic;
   signal cache_checking    : std_logic;
   signal cache_miss        : std_logic;
   signal cache_hit         : std_logic;
   
   signal ctrl_PWM_valid   : std_logic;
   signal ctrl_PWM_reset   : std_logic;
   signal ctrl_rw: std_logic := '0';
   signal ctrl_etat_valid: std_logic;


	COMPONENT memory_64k
    Port ( clk       : in   STD_LOGIC;
           addr_in   : in   STD_LOGIC_VECTOR (31 downto 2);
           data_in   : in   STD_LOGIC_VECTOR (31 downto 0);
           enable    : in   STD_LOGIC;
           we_select : in   STD_LOGIC_VECTOR (3 downto 0);
           data_out  : out  STD_LOGIC_VECTOR (31 downto 0));
	end COMPONENT;

	component vga_ctrl is
      port(
         clock           : in  std_logic;
         clock_vga       : in  std_logic;
         reset           : in  std_logic;
         vga_w           : in  std_logic_vector(31 downto 0);
         vga_w_en        : in  std_logic;
         vga_r           : out std_logic_vector(31 downto 0);
         vga_r_en        : in std_logic;
         VGA_hs          : out std_logic;   -- horisontal vga syncr.
         VGA_vs          : out std_logic;   -- vertical vga syncr.
         VGA_red         : out std_logic_vector(3 downto 0);   -- red output
         VGA_green       : out std_logic_vector(3 downto 0);   -- green output
         VGA_blue        : out std_logic_vector(3 downto 0)   -- blue output
      );
   end component;
   
   component VGA_bitmap_640x480 is
     generic(bit_per_pixel : integer range 1 to 12:=12;    -- number of bits per pixel
             grayscale     : boolean := false);           -- should data be displayed in grayscale
     port(clk          : in  std_logic;
          clk_vga      : in  std_logic;
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

	component ctrl_SL is
	   port(
	   		clock			: in  std_logic;
			reset			: in  std_logic;
			INPUT_1			: in  std_logic_vector(31 downto 0);
			INPUT_1_valid	: in  std_logic;
			OUTPUT_1		: out std_logic_vector(31 downto 0);
			SW				: in std_logic_vector(15 downto 0);
			LED				: out std_logic_vector(15 downto 0);
			RGB1_Red		: out  std_logic;
			RGB2_Red		: out  std_logic;
			RGB1_Green		: out  std_logic;
			RGB2_Green		: out  std_logic;
			RGB1_Blue		: out  std_logic;
			RGB2_Blue		: out  std_logic
		);
	end component;


  component PmodOLEDrgb_charmap is
      Generic (CLK_FREQ_HZ : integer := 100000000;        -- by default, we run at 100MHz
               PARAM_BUFF  : boolean := False;            -- if True, no need to hold inputs while module busy
               LEFT_SIDE   : boolean := False);           -- True if the Pmod is on the left side of the board
      Port (clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;

            char_write   : in  STD_LOGIC;
            char_col     : in  STD_LOGIC_VECTOR(3 downto 0);
            char_row     : in  STD_LOGIC_VECTOR(2 downto 0);
            char         : in  STD_LOGIC_VECTOR(7 downto 0);
            ready        : out STD_LOGIC;
            foregnd      : in  STD_LOGIC_VECTOR(7 downto 0):=x"FF";
            backgnd      : in  STD_LOGIC_VECTOR(7 downto 0):=x"00";
            scroll_up    : in  STD_LOGIC := '0';
            row_clear    : in  STD_LOGIC := '0';
            screen_clear : in  STD_LOGIC;

            PMOD_CS      : out STD_LOGIC;
            PMOD_MOSI    : out STD_LOGIC;
            PMOD_SCK     : out STD_LOGIC;
            PMOD_DC      : out STD_LOGIC;
            PMOD_RES     : out STD_LOGIC;
            PMOD_VCCEN   : out STD_LOGIC;
            PMOD_EN      : out STD_LOGIC);
  end component;

  component PmodOLEDrgb_terminal is
      Generic (CLK_FREQ_HZ   : integer := 100000000;        -- by default, we run at 100MHz
               PARAM_BUFF    : boolean := False;            -- if True, no need to hold inputs while module busy
               LEFT_SIDE     : boolean := False);           -- True if the Pmod is on the left side of the board
      Port (clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;

            char_write   : in  STD_LOGIC;
            char         : in  STD_LOGIC_VECTOR(7 downto 0);
            ready        : out STD_LOGIC;
            foregnd      : in  STD_LOGIC_VECTOR(7 downto 0):=x"FF";
            backgnd      : in  STD_LOGIC_VECTOR(7 downto 0):=x"00";
            screen_clear : in  STD_LOGIC;

            PMOD_CS      : out STD_LOGIC;
            PMOD_MOSI    : out STD_LOGIC;
            PMOD_SCK     : out STD_LOGIC;
            PMOD_DC      : out STD_LOGIC;
            PMOD_RES     : out STD_LOGIC;
            PMOD_VCCEN   : out STD_LOGIC;
            PMOD_EN      : out STD_LOGIC);
  end component;


  component PmodOLEDrgb_bitmap is
      Generic (CLK_FREQ_HZ : integer := 100000000;        -- by default, we run at 100MHz
               BPP         : integer range 1 to 16 := 16; -- bits per pixel
               GREYSCALE   : boolean := False;            -- color or greyscale ? (only for BPP>6)
               LEFT_SIDE   : boolean := False);           -- True if the Pmod is on the left side of the board
      Port (clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;

            pix_write    : in  STD_LOGIC;
            pix_col      : in  STD_LOGIC_VECTOR(    6 downto 0);
            pix_row      : in  STD_LOGIC_VECTOR(    5 downto 0);
            pix_data_in  : in  STD_LOGIC_VECTOR(BPP-1 downto 0);
            pix_data_out : out STD_LOGIC_VECTOR(BPP-1 downto 0);

            PMOD_CS      : out STD_LOGIC;
            PMOD_MOSI    : out STD_LOGIC;
            PMOD_SCK     : out STD_LOGIC;
            PMOD_DC      : out STD_LOGIC;
            PMOD_RES     : out STD_LOGIC;
            PMOD_VCCEN   : out STD_LOGIC;
            PMOD_EN      : out STD_LOGIC);
  end component;


	component PmodOLEDrgb_nibblemap is
    Generic (CLK_FREQ_HZ : integer := 100000000;        -- by default, we run at 100MHz
             PARAM_BUFF  : boolean := False;            -- if True, no need to hold inputs while module busy
             LEFT_SIDE   : boolean := False);           -- True if the Pmod is on the left side of the board
    Port (clk          : in  STD_LOGIC;
          reset        : in  STD_LOGIC;

          nibble_write : in  STD_LOGIC;
          nibble_col   : in  STD_LOGIC_VECTOR(3 downto 0);
          nibble_row   : in  STD_LOGIC_VECTOR(2 downto 0);
          nibble       : in  STD_LOGIC_VECTOR(3 downto 0);
          ready        : out STD_LOGIC;
          foregnd      : in  STD_LOGIC_VECTOR(7 downto 0):=x"FF";
          backgnd      : in  STD_LOGIC_VECTOR(7 downto 0):=x"00";
          nibble_clear : in  STD_LOGIC := '0';
          row_clear    : in  STD_LOGIC := '0';
          screen_clear : in  STD_LOGIC := '0';

          PMOD_CS      : out STD_LOGIC;
          PMOD_MOSI    : out STD_LOGIC;
          PMOD_SCK     : out STD_LOGIC;
          PMOD_DC      : out STD_LOGIC;
          PMOD_RES     : out STD_LOGIC;
          PMOD_VCCEN   : out STD_LOGIC;
          PMOD_EN      : out STD_LOGIC);
  	end component;


  	component PmodOLEDrgb_sigplot is
    Generic (CLK_FREQ_HZ : integer := 100000000;        -- by default, we run at 100MHz
             PARAM_BUFF  : boolean := False;            -- should parameters be bufferized
             MAX_ON_TOP  : boolean := True;             -- max value is on top of the screen, min value is below.
             LEFT_SIDE   : boolean := False);           -- True if the Pmod is on the left side of the board
    Port (clk          : in  STD_LOGIC;
          reset        : in  STD_LOGIC;

          sample       : in  STD_LOGIC_VECTOR(5 downto 0); -- the value of the new sample
          sample_en    : in  STD_LOGIC;                    -- enable bit for the new sample
          sample_num   : in  STD_LOGIC_VECTOR(1 downto 0); -- the curve considered

          disp_shift   : in  STD_LOGIC;                    -- enables the display shift
          back_grad    : in  STD_LOGIC_vector(3 downto 0):="0000"; -- a grey level to eventually provide graduation

          ready        : out STD_LOGIC;                    -- commands can only be sent if ready = '1'.

          PMOD_CS      : out STD_LOGIC;
          PMOD_MOSI    : out STD_LOGIC;
          PMOD_SCK     : out STD_LOGIC;
          PMOD_DC      : out STD_LOGIC;
          PMOD_RES     : out STD_LOGIC;
          PMOD_VCCEN   : out STD_LOGIC;
          PMOD_EN      : out STD_LOGIC);
	end component;

	Component ctrl_pwm is
	generic (DATA_BITS: integer range 0 to 32 := 8; 
         	 MAX_ADDR: integer := 38324;
          	 FREQ: integer := 1134);
	    Port ( clock : in STD_LOGIC;
		   reset : in STD_LOGIC;
		   INPUT_1_valid : in STD_LOGIC;
                   INPUT_ETAT_valid : in STD_LOGIC;
		   Reading: in STD_LOGIC;
		   INPUT_1 : in std_logic_vector(31 downto 0);
		   OUTPUT_ampSD : out STD_LOGIC;
		   odata : out STD_LOGIC);
	end component;
	    
begin  --architecture


   --RGB1_Red <= not btnCpuReset;
   --RGB1_Green <= btnD;
   --RGB1_Blue <= btnU;
   --RGB2_Red <= btnR;
   --RGB2_Green <= btnL;
   --RGB2_Blue <= btnC;

   --led <= sw;

   --seg <= "1011010";
   --an <= sw(7 downto 0);


   write_enable <= '1' when cpu_byte_we /= "0000" else '0';
   mem_busy     <= eth_pause;-- or mem_pause_in;
   cache_hit    <= cache_checking and not cache_miss;
   cpu_pause    <= (uart_write_busy and enable_uart and write_enable)    --UART busy
--						 or  cache_miss                                        --Cache wait
--                   or (cpu_address(31) and not cache_hit and mem_busy);  --DDR or flash
                   or (eth_pause);  -- DMA ENGINE FREEZE ALL (BLG)
   irq_status   <= gpioA_in(31) & not gpioA_in(31) &
                        irq_eth_send & irq_eth_rec &
                        counter_reg(18) & not counter_reg(18) &
                        not uart_write_busy & uart_data_avail;
   irq          <= '1' when (irq_status and irq_mask_reg) /= ZERO(7 downto 0) else '0';

   gpio0_out(31 downto 29) <= gpio0_reg(31 downto 29);
   gpio0_out(23 downto 0)  <= gpio0_reg(23 downto 0);

   enable_misc             <= '1' when cpu_address(30 downto 28) = "010" else '0';
   enable_uart             <= '1' when enable_misc = '1' and cpu_address(8 downto 4) = "00000" else '0';
   enable_uart_read        <= enable_uart and not write_enable;
   enable_uart_write       <= enable_uart and write_enable;
   enable_eth              <= '1' when enable_misc = '1' and cpu_address(8 downto 4) = "00111" else '0';
   enable_vga <= '1' when enable_misc = '1' and cpu_address(8 downto 4) = "10010" else '0';
   enable_vga_read <= enable_vga and not write_enable;
   enable_vga_write <= enable_vga and  write_enable;

   cpu_address(1 downto 0) <= "00";

	--
	-- ON GENERE LES SIGNAUX DE COMMANDE EN DIRECTION DU PORT PCIe
	--
	--fifo_1_read_en  <= '1' when ((cpu_address(31 downto 28) = "0011") AND (cpu_address(7 downto 4) = "1000")                         ) else '0';
   --fifo_1_write_en <= '1' when ((cpu_address(31 downto 28) = "0011") AND (cpu_address(7 downto 4) = "1001") AND (write_enable = '1')) else '0';
   fifo_1_read_en  <= '1' when (cpu_address = x"30000080") AND (cpu_pause    = '0')                         else '0';
   fifo_1_write_en <= '1' when (cpu_address = x"30000090") AND (cpu_pause    = '0') AND(write_enable = '1') else '0';

   cop_1_reset <= '1' when (cpu_address = x"40000000") AND (cpu_pause = '0') else '0';
   cop_1_valid <= '1' when (cpu_address = x"40000004") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   cop_2_reset <= '1' when (cpu_address = x"40000030") AND (cpu_pause = '0') else '0';
   cop_2_valid <= '1' when (cpu_address = x"40000034") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   cop_3_reset <= '1' when (cpu_address = x"40000060") AND (cpu_pause = '0') else '0';
   cop_3_valid <= '1' when (cpu_address = x"40000064") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   cop_4_reset <= '1' when (cpu_address = x"40000090") AND (cpu_pause = '0') else '0';
   cop_4_valid <= '1' when (cpu_address = x"40000094") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   ctrl_SL_reset <= '1' when (cpu_address = x"400000C0") AND (cpu_pause = '0') else '0';
   ctrl_SL_valid <= '1' when (cpu_address = x"400000C4") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   enable_buttons <= '1' when (cpu_address = x"40000100" or cpu_address = x"40000104") AND (cpu_pause = '0') else '0';

   ctrl_7seg_valid <= '1' when (cpu_address = x"40000200") AND (cpu_pause = '0') else '0';
   ctrl_7seg_reset <= '1' when (cpu_address = x"40000204") AND (cpu_pause = '0') else '0';

   enable_i2c <= '1' when (cpu_address(31 downto 8) = x"400003") AND (cpu_pause = '0') else '0';

   oledcharmap_reset <= '1' when (cpu_address = x"400004A0") AND (cpu_pause = '0') else '0';
   oledcharmap_valid <= '1' when (cpu_address = x"400004A8") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   oledterminal_reset <= '1' when (cpu_address = x"400004A4") AND (cpu_pause = '0') else '0';
   oledterminal_valid <= '1' when (cpu_address = x"400004AC") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   oledbitmap_reset <= '1' when (cpu_address = x"400004B0") AND (cpu_pause = '0') else '0';
   oledbitmap_valid <= '1' when (cpu_address = x"400004B8") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   olednibblemap_reset <= '1' when (cpu_address = x"400004B4") AND (cpu_pause = '0') else '0';
   olednibblemap_valid <= '1' when (cpu_address = x"400004BC") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   oledsigplot_reset <= '1' when (cpu_address = x"400004D0") AND (cpu_pause = '0') else '0';
   oledsigplot_valid <= '1' when (cpu_address = x"400004D8") AND (cpu_pause = '0') AND (write_enable = '1') else '0';

   ctrl_PWM_reset <= '1' when (cpu_address = x"400004D4") AND (cpu_pause = '0') else '0';
   ctrl_PWM_valid <= '1' when (cpu_address = x"400004DC") AND (cpu_pause = '0') else '0';
   ctrl_rw        <= '1' when (cpu_address = x"400004E0") AND (cpu_pause = '0') else '0';
   ctrl_etat_valid <= '1' when (cpu_address = x"400004E4") AND (cpu_pause = '0') else '0';
--   assert cop_4_valid /= '1' severity failure;
	--
	-- ON LIT/ECRIT DANS LA MEMOIRE LOCALE UNIQUEMENT LORSQUE LE BUS
	-- D'ADRESSE (MSB) = "001". SINON ON ADRESSE UN AUTRE PERIPHERIQUE
	--

   --dram_procr: process(clk)
   --begin
   --	if rising_edge(clk) then
	--		ppcie_rdata <= pcie_rdata;
	--	end if;
   --end process;

	--
	-- INTERNAL RAM MEMORY (64ko)
	--
--	enable_local_mem        <= '1' when (cpu_address(31 downto 28) = "0001") else '0';
--	enable_local_mem <= '1' when (ram_address(31 downto 28) = "0001") else '0';


   local_memory: memory_64k
      port map (
         clk        => clk,
			   addr_in	  => ram_address, --cpu_data_r,
         data_in    => ram_data_w,
         enable     => enable_local_mem,
         we_select  => ram_byte_we,
         data_out   => ram_data_lm
		);
		

   vga_ram_we <= ram_byte_we(0) and enable_ram_vga;
    
vga_enabled : if eVGA = '1' generate

   vga_bloc : VGA_bitmap_640x480 generic map(bit_per_pixel => 12,    -- number of bits per pixel
                                             grayscale     => true)           -- should data be displayed in grayscale
     port map (clk => clk,
          clk_vga => clk_VGA,
          reset => reset,
          VGA_hs => VGA_hs,   -- horisontal vga syncr.
          VGA_vs => VGA_vs,   -- vertical vga syncr.
          VGA_red =>  VGA_red,   -- red output
          VGA_green => VGA_green,   -- green output
          VGA_blue => VGA_blue,   -- blue output
          ADDR => ram_address(20 downto 2),
          data_in => ram_data_w(11 downto 0),
          data_write => vga_ram_we,
          data_out => ram_data_vga );
   
   end generate;

vga_not_enabled : if eVGA = '0' generate
   VGA_hs <= '0';
   VGA_vs <= '0';
   VGA_red <= (others => '0');
   VGA_green <= (others => '0');
   VGA_blue <= (others => '0');
   ram_data_vga <= (others => '0');
end generate;       

	
   u1_cpu: mlite_cpu
      generic map (memory_type => memory_type)
      PORT MAP (
         clk          => clk,
         reset_in     => reset,
         intr_in      => irq,

         address_next => address_next,             --before rising_edge(clk)
         byte_we_next => byte_we_next,

         address      => cpu_address(31 downto 2), --after rising_edge(clk)
         byte_we      => cpu_byte_we,
         data_w       => cpu_data_w,
         data_r       => cpu_data_r,
         mem_pause    => cpu_pause);


	--
	--
	--
   opt_cache: if use_cache = '0' generate
      cache_access   <= '0';
      cache_checking <= '0';
      cache_miss     <= '0';
   end generate;

	--
	--
	--
   opt_cache2: if use_cache = '1' generate
   --Control 4KB unified cache that uses the upper 4KB of the 8KB
   --internal RAM.  Only lowest 2MB of DDR is cached.
   u_cache: cache
      generic map (memory_type => memory_type)
      PORT MAP (
         clk            => clk,
         reset          => reset,
         address_next   => address_next,
         byte_we_next   => byte_we_next,
         cpu_address    => cpu_address(31 downto 2),
         mem_busy       => mem_busy,

         cache_access   => cache_access,    --access 4KB cache
         cache_checking => cache_checking,  --checking if cache hit
         cache_miss     => cache_miss);     --cache miss
   end generate; --opt_cache2

   no_ddr_start <= not eth_pause and cache_checking;
   no_ddr_stop  <= not eth_pause and cache_miss;
   eth_pause_in <= (not eth_pause and cache_miss and not cache_checking);


	--
	--
	--
   misc_proc: process(clk, reset, cpu_address, enable_misc,
      ram_data_r, data_read_uart, cpu_pause, enable_buttons, enable_i2c,
      irq_mask_reg, irq_status, gpio0_reg, write_enable,
      cache_checking,
      gpioA_in, counter_reg, cpu_data_w, ram_data_lm,
      fifo_1_empty, fifo_2_empty, fifo_1_full, fifo_2_full,
      fifo_1_valid, fifo_2_valid, fifo_1_compteur, fifo_2_compteur, fifo_1_out_data,
      oledsigplot_output, oledterminal_output, oledcharmap_output, olednibblemap_output,
      oledbitmap_output, ctrl_SL_output)
   begin
      case cpu_address(30 downto 28) is

			-- ON LIT LES DONNEES DE LA MEMOIRE INTERNE
      	when "000" =>         --internal ROM
         	cpu_data_r <= ram_data_r;

			-- ON LIT LES DONNEES DE LA MEMOIRE EXTERNE (LOCAL RAM)
      	when "001" =>         --external (local) RAM
				cpu_data_r <= ram_data_lm;
      	when "101" =>         --external (local) RAM
             cpu_data_r <= "00000000000000000000"&ram_data_vga;      
			-- ON LIT LES DONNEES DES PERIPHERIQUES MISC.
	when "010" =>         --misc
         	case cpu_address(8 downto 4) is
         		when "00000" =>      --uart
         		   cpu_data_r <= ZERO(31 downto 8) & data_read_uart;
        		when "00001" =>      --irq_mask
            		cpu_data_r <= ZERO(31 downto 8) & irq_mask_reg;
         		when "00010" =>      --irq_status
         		   cpu_data_r <= ZERO(31 downto 8) & irq_status;
         		when "00011" =>      --gpio0
            		cpu_data_r <= gpio0_reg;
         		when "00101" =>      --gpioA
            		cpu_data_r <= gpioA_in;
         		when "00110" =>      --counter
            		cpu_data_r <= counter_reg;
            		when "10010" => -- vga
            	  	cpu_data_r <= data_vga_read;
			when others =>		 -- ce n'est pas pr\E9vu...
			cpu_data_r <= x"FFFFFFFF";
		end case;

			-- ON LIT LES DONNEES EN PROVENANCE DU PCIe 0x3....XX
	when "011" =>
         	case cpu_address(7 downto 4) is
					when "0000"  => cpu_data_r <= ZERO(31 downto 1) & fifo_1_empty;
					when "0001"  => cpu_data_r <= ZERO(31 downto 1) & fifo_2_empty;
					when "0010"  => cpu_data_r <= ZERO(31 downto 1) & fifo_1_full;
					when "0011"  => cpu_data_r <= ZERO(31 downto 1) & fifo_2_full;
					when "0100"  => cpu_data_r <= ZERO(31 downto 1) & fifo_1_valid;
					when "0101"  => cpu_data_r <= ZERO(31 downto 1) & fifo_2_valid;
					when "0110"  => cpu_data_r <= fifo_1_compteur;
					when "0111"  => cpu_data_r <= fifo_2_compteur;
					when "1000"  => cpu_data_r <= fifo_1_out_data;
					when others =>		 -- ce n'est pas pr\E9vu...
						cpu_data_r <= x"FFFFFFFF";
         	end case;

			--
			-- LECTURE DES RESULTATS DES COPROCESSEURS
			--
	when "100" =>
		case cpu_address is
		   when x"40000004" => cpu_data_r <= cop_1_output;
		   when x"40000034" => cpu_data_r <= cop_2_output;
         when x"40000064" => cpu_data_r <= cop_3_output;
         when x"40000094" => cpu_data_r <= cop_4_output;                                    
			when x"400000C4" => cpu_data_r <= ctrl_SL_output;
			when x"40000100" => cpu_data_r <= buttons_values;
			when x"40000104" => cpu_data_r <= buttons_change;
			when x"40000300" => cpu_data_r <= i2c_addr;
			when x"40000304" => cpu_data_r <= i2c_status;
			when x"40000308" => cpu_data_r <= i2c_control;
			when x"4000030C" => cpu_data_r <= i2c_data;
			when x"40000400" => cpu_data_r <= oled_mux;
			when x"400004A8" => cpu_data_r <= oledcharmap_output;
			when x"400004AC" => cpu_data_r <= oledterminal_output;
			when x"400004B8" => cpu_data_r <= oledbitmap_output;
			when x"400004D8" => cpu_data_r <= oledsigplot_output;
            		
			when others => cpu_data_r <= x"FFFFFFFF";
		end case;

			--when "011" =>         --flash
         --	cpu_data_r <= data_read;
      	when others =>
      	   cpu_data_r <= ZERO(31 downto 8) & x"FF";
      end case;

      if reset = '1' then
         irq_mask_reg <= ZERO(7 downto 0);
         gpio0_reg    <= ZERO;
         counter_reg  <= ZERO;
      elsif rising_edge(clk) then
         if cpu_pause = '0' then
            if enable_misc = '1' and write_enable = '1' then
               if cpu_address(6 downto 4) = "001" then
                  irq_mask_reg <= cpu_data_w(7 downto 0);
               elsif cpu_address(6 downto 4) = "011" then
                  gpio0_reg <= gpio0_reg or cpu_data_w;
               elsif cpu_address(6 downto 4) = "100" then
                  gpio0_reg <= gpio0_reg and not cpu_data_w;
               end if;
            end if;
         end if;
         counter_reg <= bv_inc(counter_reg);
      end if;
   end process;



   ram_proc: process(cache_access, cache_miss,
                     address_next, cpu_address,
                     byte_we_next, cpu_data_w,
							dma_address,
							dma_byte_we, eth_pause,
							dma_data_write,
							dma_start)
   begin
      if eth_pause = '1' then    --Check if cache hit or write through
         if dma_address(31 downto 28) = "0000" then
            ram_boot_enable <= '1';
         else
            ram_boot_enable <= '0';
         end if;
         if dma_address(31 downto 28) = "0001" then
            enable_local_mem <= '1';
         else
            enable_local_mem <= '0';
         end if;

		   ram_address <= dma_address(31 downto 2);	-- adr from ram
		   ram_byte_we <= dma_byte_we;
         ram_data_w  <= dma_data_write;

		else --Normal non-cache access
         if address_next(31 downto 28) = "0000" then
            ram_boot_enable <= '1';
         else
            ram_boot_enable <= '0';
         end if;
         if address_next(31 downto 28) = "0001" then
            enable_local_mem <= '1';
         else
            enable_local_mem <= '0';
         end if;
         if address_next(31 downto 28) = "0101" then -- 
            enable_ram_vga <= '1';
         else
            enable_ram_vga <= '0';
         end if;

         ram_byte_we              <= byte_we_next;
         ram_address(31 downto 2) <= address_next(31 downto 2);
         ram_data_w               <= cpu_data_w;
      end if;
   end process;

	--
	-- RAM DATA CONTROLLER
	--
   --ram_boot_enable <= '1' WHEN (ram_enable = '1') AND eth_pause = '0' ELSE '0';
   u2_boot: ram
      generic map (memory_type => memory_type)
      port map (
         clk               => clk,
         enable            => ram_boot_enable,
         write_byte_enable => ram_byte_we,
         address           => ram_address,
         data_write        => ram_data_w,
         data_read         => ram_data_r);


	-- ON RELIT L'ENTREE DU PCIe (port de sortie) AU BUS DE DONNEE DU PROCESSEUR
	-- PLASMA
	fifo_2_in_data <= cpu_data_w;

	--
	-- UART CONTROLLER CAN BE REMOVED (FOR ASIC DESIGN)
	--
   uart_gen: if eUart = '1' generate
	   u3_uart: uart
      generic map (log_file => log_file)
      port map(
         clk          => clk,
         reset        => reset,
         enable_read  => enable_uart_read,
         enable_write => enable_uart_write,
         data_in      => cpu_data_w(7 downto 0),
         data_out     => data_read_uart,
         uart_read    => uart_read,
         uart_write   => uart_write,
         busy_write   => uart_write_busy,
         data_avail   => uart_data_avail
		);
   end generate;

   uart_gen2: if eUart = '0' generate
         data_read_uart  <= "00000000";
         uart_write_busy <= '0';
         uart_data_avail <= '0';
   end generate;

	--
	-- Buttons controller
	--
	buttons_gen_enabled: if eButtons = '1' generate
		plasma_buttons_controller: buttons_controller
		port map(
			 clock          => clk,
			 reset        => reset,
			 buttons_access => enable_buttons,
			 btnC => btnC,
			 btnU => btnU,
			 btnD => btnD,
			 btnL => btnL,
			 btnR => btnR,
			 buttons_values => buttons_values,
			 buttons_change => buttons_change
		);
	end generate;

	buttons_gen_disabled: if eI2C = '0' generate
		buttons_values <= ZERO;
		buttons_change <= ZERO;
	end generate;

	--
	-- I2C CONTROLLER CAN BE REMOVED (FOR ASIC DESIGN)
	--
	i2c_gen_enabled: if eI2C = '1' generate
		plasma_i2c_clock: i2c_clock
		port map(
			clock => clk,
			reset => reset,
			enable => i2c_clock_enable,
			i2c_scl => i2c_scl_signal,
			i2c_mid => i2c_mid
		);
		plasma_i2c_pmod_controller: i2c_controller
		port map(
			clock => clk,
			reset => reset,
			i2c_access => i2c_access_pmod,
			i2c_sda => i2c_sda_pmod,
			i2c_scl => i2c_scl_pmod,
			i2c_mid => i2c_mid,
			i2c_clock_enable => i2c_clock_enable_pmod,
			addr => i2c_addr,
			control_in => i2c_control,
			control_out => i2c_control_out_pmod,
			control_update => i2c_control_update_out_pmod,
			status => i2c_status_pmod,
			data_in => i2c_data,
			data_out => i2c_data_out_pmod,
			data_update => i2c_data_update_out_pmod
		);
		plasma_i2c_tmp_controller: i2c_controller
		port map(
			clock => clk,
			reset => reset,
			i2c_access => i2c_access_tmp,
			i2c_sda => i2c_sda_tmp,
			i2c_scl => i2c_scl_tmp,
			i2c_mid => i2c_mid,
			i2c_clock_enable => i2c_clock_enable_tmp,
			addr => i2c_addr,
			control_in => i2c_control,
			control_out => i2c_control_out_tmp,
			control_update => i2c_control_update_out_tmp,
			status => i2c_status_tmp,
			data_in => i2c_data,
			data_out => i2c_data_out_tmp,
			data_update => i2c_data_update_out_tmp
		);

		i2c_clock_enable <= i2c_clock_enable_pmod when i2c_control(5) = '1' else i2c_clock_enable_tmp;
		i2c_status <= i2c_status_pmod when i2c_control(5) = '1' else i2c_status_tmp;
		i2c_control_out <= i2c_control_out_pmod when i2c_control(5) = '1' else i2c_control_out_tmp;
		i2c_control_update_out <= i2c_control_update_out_pmod when i2c_control(5) = '1' else i2c_control_update_out_tmp;
		i2c_data_out <= i2c_data_out_pmod when i2c_control(5) = '1' else i2c_data_out_tmp;
		i2c_data_update_out <= i2c_data_update_out_pmod when i2c_control(5) = '1' else i2c_data_update_out_tmp;
	end generate;

	i2c_gen_disabled: if eI2C = '0' generate
		i2c_data_update_out <= '0';
		i2c_control_update_out <= '0';
		i2c_scl_signal <= 'Z';
		i2c_sda_pmod <= 'Z';
		i2c_sda_tmp <= 'Z';
	end generate;

	-- Sync cpu_data_w capture for buffered registers.

	process (reset, clk)
	begin
		if reset = '1' then
			i2c_addr <= ZERO;
		elsif clk'event and clk = '1' then
			if cpu_address = x"40000300" and write_enable = '1' then
				i2c_addr <= cpu_data_w;
			end if;
		end if;
	end process;

	process (reset, clk)
	begin
		if reset = '1' then
			i2c_control <= ZERO;
		elsif clk'event and clk = '1' then
			if cpu_address = x"40000308" and write_enable = '1' then
				i2c_control <= cpu_data_w;
			elsif i2c_control_update_out = '1' then
				i2c_control <= i2c_control_out;
			end if;
		end if;
	end process;

	process (reset, clk)
	begin
		if reset = '1' then
			i2c_data <= ZERO;
		elsif clk'event and clk = '1' then
			if cpu_address = x"4000030C" and write_enable = '1' then
				i2c_data <= cpu_data_w;
			elsif i2c_data_update_out = '1' then
				i2c_data <= i2c_data_out;
			end if;
		end if;
	end process;

	i2c_scl_pmod <= '0' when i2c_scl_signal = '0' and i2c_control(5) = '1' else 'Z';
	i2c_scl_tmp <= '0' when i2c_scl_signal = '0' and i2c_control(5) = '0' else 'Z';

	i2c_access_pmod <= '1' when i2c_control(5) = '1' else '0';
	i2c_access_tmp <= '1' when i2c_control(5) = '0' else '0';

--   vga_controler: vga_ctrl port map(
--		clock          => clk,
--		clock_VGA      => clk_VGA,
--		reset          => reset,
--		vga_w         => cpu_data_w,
--		vga_w_en  => enable_vga_write,
--		vga_r       => data_vga_read,
--		vga_r_en => enable_vga_read,
--		VGA_hs => VGA_hs,
--		VGA_vs => VGA_vs,
--		VGA_red => VGA_red,
--		VGA_green => VGA_green,
--		VGA_blue => VGA_blue
--	);

	--
	-- ETHERNET CONTROLLER CAN BE REMOVED (FOR ASIC DESIGN)
	--
--   dma_gen: if ethernet = '2' generate
--      address      <= cpu_address(31 downto 2);
--      byte_we      <= cpu_byte_we;
--      data_write   <= cpu_data_w;
--      eth_pause    <= '0';
--      irq_eth_rec  <= '0';
--      irq_eth_send <= '0';
--      gpio0_out(28 downto 24) <= ZERO(28 downto 24);
--   end generate;

--   dma_gen2: if ethernet = '1' generate
--   u4_eth: eth_dma
--      port map(
--         clk         => clk,
--         reset       => reset,
--         enable_eth  => gpio0_reg(24),
--         select_eth  => enable_eth,
--         rec_isr     => irq_eth_rec,
--         send_isr    => irq_eth_send,
--
--         address     => address,      --to DDR
--         byte_we     => byte_we,
--         data_write  => data_write,
--         data_read   => data_read,
--         pause_in    => eth_pause_in,
--
--         mem_address => cpu_address(31 downto 2), --from CPU
--         mem_byte_we => cpu_byte_we,
--         data_w      => cpu_data_w,
--         pause_out   => eth_pause,
--
--         E_RX_CLK    => gpioA_in(20),
--         E_RX_DV     => gpioA_in(19),
--         E_RXD       => gpioA_in(18 downto 15),
--         E_TX_CLK    => gpioA_in(14),
--         E_TX_EN     => gpio0_out(28),
--         E_TXD       => gpio0_out(27 downto 24));
--   end generate;

	dma_start <= '1' when ((cpu_address(31 downto 28) = "1000") and (cpu_byte_we = "1111")) else '0';

	------------------------------------------------------------------------------------------------------
	--
	--
	--
	--
	--
	------------------------------------------------------------------------------------------------------

   dma_input_mux_proc: process(clk, reset, dma_address, enable_misc,
      ram_data_r, data_read_uart, cpu_pause,
      irq_mask_reg, irq_status, gpio0_reg, write_enable,
      cache_checking,
      gpioA_in, counter_reg, cpu_data_w, ram_data_lm,
		fifo_1_empty, fifo_2_empty, fifo_1_full, fifo_2_full,
		fifo_1_valid, fifo_2_valid, fifo_1_compteur, fifo_2_compteur, fifo_1_out_data)
   begin
      case dma_address(30 downto 28) is
      	when "000" =>         --internal ROM
         	dma_data_read <= ram_data_r;
      	when "001" =>         --external (local) RAM
				dma_data_read <= ram_data_lm;
			when "010" =>         --misc
         	case dma_address(6 downto 4) is
         		when "000" =>  dma_data_read <= ZERO(31 downto 8) & data_read_uart;
        		 	when "001" =>  dma_data_read <= ZERO(31 downto 8) & irq_mask_reg;
         		when "010" =>  dma_data_read <= ZERO(31 downto 8) & irq_status;
         		when "011" =>  dma_data_read <= gpio0_reg;
         		when "101" =>  dma_data_read <= gpioA_in;
         		when "110" =>  dma_data_read <= counter_reg;
					when others =>	dma_data_read <= x"FFFFFFFF";
				end case;
			when "011" =>
         	case dma_address(7 downto 4) is
					when "0000"  => dma_data_read <= ZERO(31 downto 1) & fifo_1_empty;
					when "0001"  => dma_data_read <= ZERO(31 downto 1) & fifo_2_empty;
					when "0010"  => dma_data_read <= ZERO(31 downto 1) & fifo_1_full;
					when "0011"  => dma_data_read <= ZERO(31 downto 1) & fifo_2_full;
					when "0100"  => dma_data_read <= ZERO(31 downto 1) & fifo_1_valid;
					when "0101"  => dma_data_read <= ZERO(31 downto 1) & fifo_2_valid;
					when "0110"  => dma_data_read <= fifo_1_compteur;
					when "0111"  => dma_data_read <= fifo_2_compteur;
					when "1000"  => dma_data_read <= fifo_1_out_data;
					when others  => dma_data_read <= x"FFFFFFFF";
         	end case;
      	when others =>
      	   dma_data_read <= ZERO(31 downto 8) & x"FF";
      end case;
	end process;

   u4_dma: entity WORK.dma_engine port map(
		clk         => clk,
		reset       => reset,
		start_dma   => dma_start,
		--
		address     => dma_address,	-- adr from ram
		byte_we     => dma_byte_we,
		data_write  => dma_data_write,
		data_read   => dma_data_read,
		--
		mem_address => cpu_address,	-- adr from cpu
		mem_byte_we => cpu_byte_we,
		data_w      => cpu_data_w,
		pause_out   => eth_pause
	);


	------------------------------------------------------------------------------------------------------
	--
	--
	--
	--
	--
	------------------------------------------------------------------------------------------------------

--   u5a_coproc: entity WORK.coproc_1 port map(
--		clock          => clk,
--		reset          => cop_1_reset,
--		INPUT_1        => cpu_data_w,
--		INPUT_1_valid  => cop_1_valid,
--		OUTPUT_1       => cop_1_output
--	);

--   u5b_coproc: entity WORK.coproc_2 port map(
--		clock          => clk,
--		reset          => cop_2_reset,
--		INPUT_1        => cpu_data_w,
--		INPUT_1_valid  => cop_2_valid,
--		OUTPUT_1       => cop_2_output
--	);

--   u5c_coproc: entity WORK.coproc_3 port map(
--		clock          => clk,
--		reset          => cop_3_reset,
--		INPUT_1        => cpu_data_w,
--		INPUT_1_valid  => cop_3_valid,
--		OUTPUT_1       => cop_3_output
--	);

-- seven segment display management bloc


  ctrl_7seg1: entity WORK.ctrl_7seg port map(
      clock          => clk,
      reset          => ctrl_7seg_reset,
      INPUT_1        => cpu_data_w,
      INPUT_1_valid  => ctrl_7seg_valid,
      OUTPUT_7s      => seg,
      DP             => DP,
      AN             => an
  );

	-- Controller Switchs/Leds

	switch_led_gen_enabled: if eSwitchLED = '1' generate
		plasma_ctrl_SL: ctrl_SL port map (
			clock		=> clk,
			reset		=> ctrl_SL_reset,
			INPUT_1		=> cpu_data_w,
			INPUT_1_valid	=> ctrl_SL_valid,
			OUTPUT_1	=> ctrl_SL_output,
			SW		=> sw,
			LED		=> led,
			RGB1_Red	=> RGB1_Red,
			RGB2_Red	=> RGB2_Red,
			RGB1_Green	=> RGB1_Green,
			RGB2_Green	=> RGB2_Green,
			RGB1_Blue	=> RGB1_Blue,
			RGB2_Blue	=> RGB2_Blue
		);
	end generate;

	switch_led_gen_disabled: if eSwitchLED = '0' generate
		ctrl_SL_output <= ZERO;
	end generate;

	rgb_oled_gen_enabled: if eRGBOLED = '1' generate
	  -- OLED Charmap
	  	plasma_oledcharmap: PmodOLEDrgb_charmap
		Generic map(	CLK_FREQ_HZ => CLK_FREQ_HZ,
		    		PARAM_BUFF  => True,            	-- necessary because we connect CPU bus directly and there is no solution to get it buffered
		      		LEFT_SIDE   => LEFT_SIDE)           -- True if the Pmod is on the left side of the board

	   	port map (
	  		clk          => clk,
	      	reset        => oledcharmap_reset,

	      	char_write   => oledcharmap_valid,
	      	char_col     => cpu_data_w(19 downto 16),
	      	char_row     => cpu_data_w(10 downto 8),
	      	char         => cpu_data_w(7 downto 0),
	      	ready        => oledcharmap_output(0),

	      	scroll_up    => cpu_data_w(26),
	      	row_clear    => cpu_data_w(25),
	      	screen_clear => cpu_data_w(24),

		PMOD_CS      => oledcharmap_pinout(0),
	      	PMOD_MOSI    => oledcharmap_pinout(1),
		PMOD_SCK     => oledcharmap_pinout(2),
		PMOD_DC      => oledcharmap_pinout(3),
		PMOD_RES     => oledcharmap_pinout(4),
		PMOD_VCCEN   => oledcharmap_pinout(5),
		PMOD_EN      => oledcharmap_pinout(6)
	  	);


	    -- OLED Terminal
	    plasma_oledterminal: PmodOLEDrgb_terminal
		Generic map(	CLK_FREQ_HZ => CLK_FREQ_HZ,
		          	PARAM_BUFF  => True,            -- necessary because we connect CPU bus directly and there is no solution to get it buffered
		          	LEFT_SIDE   => LEFT_SIDE)           -- True if the Pmod is on the left side of the board

		port map (
	    	clk          => clk,
		reset        => oledterminal_reset,

		char_write   => oledterminal_valid,
		char         => cpu_data_w(7 downto 0),
		ready        => oledterminal_output(0),
		screen_clear => cpu_data_w(24),

		PMOD_CS      => oledterminal_pinout(0),
		PMOD_MOSI    => oledterminal_pinout(1),
		PMOD_SCK     => oledterminal_pinout(2),
		PMOD_DC      => oledterminal_pinout(3),
		PMOD_RES     => oledterminal_pinout(4),
		PMOD_VCCEN   => oledterminal_pinout(5),
		PMOD_EN      => oledterminal_pinout(6)
	    );


	      -- OLED Bitmap
		plasma_oledbitmap: PmodOLEDrgb_bitmap
		Generic map(	CLK_FREQ_HZ => CLK_FREQ_HZ,
		            BPP         => BPP,
		            GREYSCALE   => GREYSCALE,
		            LEFT_SIDE   => LEFT_SIDE)           -- True if the Pmod is on the left side of the board

		port map (
	      	clk          => clk,
	       	reset        => oledbitmap_reset,

	       	pix_write    => oledbitmap_valid,
	    	pix_col      => cpu_data_w(6 downto 0),
	      	pix_row      => cpu_data_w(13 downto 8),
	     	pix_data_in  => cpu_data_w(((BPP-1)+16) downto 16),
	    	pix_data_out => oledbitmap_output(BPP-1 downto 0),

	      	PMOD_CS      => oledbitmap_pinout(0),
	  		PMOD_MOSI    => oledbitmap_pinout(1),
	       	PMOD_SCK     => oledbitmap_pinout(2),
	    	PMOD_DC      => oledbitmap_pinout(3),
	       	PMOD_RES     => oledbitmap_pinout(4),
	     	PMOD_VCCEN   => oledbitmap_pinout(5),
	       	PMOD_EN      => oledbitmap_pinout(6)
		);


	      -- OLED Nibble
		plasma_olednibble: PmodOLEDrgb_nibblemap
	    Generic map (		CLK_FREQ_HZ => CLK_FREQ_HZ,
		          	PARAM_BUFF  => True,            -- necessary because we connect CPU bus directly and there is no solution to get it buffered
		          	LEFT_SIDE   => LEFT_SIDE)           -- True if the Pmod is on the left side of the board
	    Port map (clk          => clk,
	       	  reset        => olednibblemap_reset,

		  nibble_write => olednibblemap_valid,
		  nibble_col   => cpu_data_w(3 downto 0),
		  nibble_row   => cpu_data_w(10 downto 8),
		  nibble       => cpu_data_w(19 downto 16),
		  ready        => olednibblemap_output(0),

		  PMOD_CS      => olednibblemap_pinout(0),
	  		  PMOD_MOSI    => olednibblemap_pinout(1),
	       	  PMOD_SCK     => olednibblemap_pinout(2),
	    	  PMOD_DC      => olednibblemap_pinout(3),
	       	  PMOD_RES     => olednibblemap_pinout(4),
	     	  PMOD_VCCEN   => olednibblemap_pinout(5),
	       	  PMOD_EN      => olednibblemap_pinout(6)
		  );


	      -- OLED Sigplot
		plasma_sigplot: PmodOLEDrgb_sigplot
	    Generic map (	CLK_FREQ_HZ => CLK_FREQ_HZ,
		          	PARAM_BUFF  => True,            -- necessary because we connect CPU bus directly and there is no solution to get it buffered
		          	LEFT_SIDE   => LEFT_SIDE,
		          	MAX_ON_TOP => MAX_ON_TOP)
	    Port map (
	    	  clk          => clk,
	       	  reset        => oledsigplot_reset,

		  sample       => cpu_data_w(5 downto 0),
		  sample_en    => oledsigplot_valid,
		  sample_num   => cpu_data_w(9 downto 8),
		  disp_shift   => '0',

		  ready        => oledsigplot_output(0),

		  PMOD_CS      => oledsigplot_pinout(0),
	  	  PMOD_MOSI    => oledsigplot_pinout(1),
	       	  PMOD_SCK     => oledsigplot_pinout(2),
	    	  PMOD_DC      => oledsigplot_pinout(3),
	       	  PMOD_RES     => oledsigplot_pinout(4),
	     	  PMOD_VCCEN   => oledsigplot_pinout(5),
	       	  PMOD_EN      => oledsigplot_pinout(6)
		  );

		oled_pinout <= oledcharmap_pinout when oled_mux(3 downto 0) = "0001" else
		       	oledbitmap_pinout when oled_mux(3 downto 0) = "0010" else
		       	oledterminal_pinout when oled_mux(3 downto 0) = "0011" else
		       	olednibblemap_pinout when oled_mux(3 downto 0) = "0100" else
		       	oledsigplot_pinout when oled_mux(3 downto 0) = "0101" else
		       	(others => 'Z');
	end generate;

	rgb_oled_gen_disabled: if eRGBOLED = '0' generate
		oled_pinout <= (others => 'Z');
	end generate;

	OLED_PMOD_CS    <= oled_pinout(0);
	OLED_PMOD_MOSI  <= oled_pinout(1);
	OLED_PMOD_SCK   <= oled_pinout(2);
	OLED_PMOD_DC    <= oled_pinout(3);
	OLED_PMOD_RES   <= oled_pinout(4);
	OLED_PMOD_VCCEN <= oled_pinout(5);
	OLED_PMOD_EN    <= oled_pinout(6);

	process (reset, clk)
	begin
		if reset = '1' then
			oled_mux <= ZERO;
		elsif clk'event and clk = '1' then
			if cpu_address = x"40000400" and write_enable = '1' then
				oled_mux <= cpu_data_w;
			end if;
		end if;
	end process;

	coproc_enabled: if eCoproc = '1' generate
		u1_coproc: entity WORK.coproc_1 port map(
               clock          => clk,
               reset          => cop_1_reset,
               INPUT_1        => cpu_data_w,
               INPUT_1_valid  => cop_1_valid,
               OUTPUT_1       => cop_1_output
            );
            
      u2_coproc: entity WORK.coproc_2 port map(
            clock          => clk,
            reset          => cop_2_reset,
            INPUT_1        => cpu_data_w,
            INPUT_1_valid  => cop_2_valid,
            OUTPUT_1       => cop_2_output
         );
         
      u3_coproc: entity WORK.coproc_3 port map(
            clock          => clk,
            reset          => cop_3_reset,
            INPUT_1        => cpu_data_w,
            INPUT_1_valid  => cop_3_valid,
            OUTPUT_1       => cop_3_output
         );
               
      u4_coproc: entity WORK.coproc_4 port map(
            clock          => clk,
            reset          => cop_4_reset,
            INPUT_1        => cpu_data_w,
            INPUT_1_valid  => cop_4_valid,
            OUTPUT_1       => cop_4_output
         );        
	end generate;
	
   coproc_not_enabled: if eCoproc = '0' generate
      cop_4_output <= (others => '0');
      cop_3_output <= (others => '0');
      cop_2_output <= (others => '0');
      cop_1_output <= (others => '0');
   end generate;
	
--	u5d_coproc: entity WORK.coproc_3 port map(-- atention 2x coproc 3
--         clock          => clk,
--         reset          => cop_4_reset,
--         INPUT_1        => cpu_data_w,
--         INPUT_1_valid  => cop_4_valid,
--         OUTPUT_1       => cop_4_output
--      );

--   u5d_coproc: entity WORK.coproc_4 port map(
--		clock          => clk,
--		clock_VGA      => clk_VGA,
--		reset          => cop_4_reset,
--		INPUT_1        => cpu_data_w,
--		INPUT_1_valid  => cop_4_valid,
--		OUTPUT_1       => cop_4_output,
--		VGA_hs => VGA_hs,
--		VGA_vs => VGA_vs,
--		VGA_red => VGA_red,
--		VGA_green => VGA_green,
--		VGA_blue => VGA_blue
--	);

    plasma_ctrl_audio: ctrl_pwm
	generic map( DATA_BITS => DATA_BITS, MAX_ADDR => MAX_ADDR, FREQ => FREQ)
        Port map( 
                    clock          => clk,
                    reset          => ctrl_PWM_reset,
                    INPUT_1_valid  => ctrl_PWM_valid,
		    INPUT_ETAT_valid => ctrl_etat_valid,
		    Reading        => ctrl_rw,
                    INPUT_1        => cpu_data_w,
                    OUTPUT_ampSD   => ampSD,
                    odata          => odata
                );
    


end; --architecture logic
