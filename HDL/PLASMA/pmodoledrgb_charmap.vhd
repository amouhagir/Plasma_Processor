----------------------------------------------------------------------------------------------------
-- PmodOLEDrgb_charmap
--    Version V1.0 (2017/08/05)
--    (c)2017 Y. BORNAT - Bordeaux INP / ENSEIRB-MATMECA
--    This module controls the OLEDrgb Pmod to display ASCii chars at given positions
----------------------------------------------------------------------------------------------------
-- For the last version and a more complete documentation, please visit
-- http://bornat.vvv.enseirb.fr/wiki/doku.php?id=en202:pmodoledrgb
--
-- How to use This module :
---------------------------
--   - The char_row and char_col are used to address any position of the 16x8 char array. Position 0,0 is the top left char
--   - To affect a new char at a given position, user should assert char_write, address the concerned char and provide
--     the new char value on 'char' on the same rising edge of clk. After reading char_write at '1', the module will
--     reset the 'ready' output until the operation is performed. Once 'ready' is set again, the module can accept
--     a new char value and position for display
--   - when an operation is performed, the command bit should be reset by user, but the parameters should keep their value
--     unchanged until the ready bit is set again. It is possible to change this behavior setting the PARAM_BUFF generic to
--     True. The module will then require more hardware resources to perform its own copy of the inputs when reading any
--     command bit at '1'.
--   - User can optionnaly provide a foreground and/or a background color for each char. default is white on black.
--     color format is rrrgggbb so 0xE0 mean red, 0x1C means green and 0x03 means blue.
--
--   - optionnal commands 'scroll_up', 'row_clear' and 'screen_clear' respectively shift the text up by one line,
--     fill the line addressed by char_row with the background color and fill the whole screen with the background color.
--     These three commands require the module to be ready. During the processing time, the 'ready' output will be reset.
--     if several commands are input at the same time, the priority list is (from high to low) : screen_clear, row_clear,
--     scroll_up, char_write.
--
----------------------------------------------------------------------------------
-- known bugs :
--    - None so far
--
-------------------------------------------------------------------------------------------------------
-- History
----------------------------------------------------------------------------------
-- V1.0 (2017/08/05) by YB
--    - initial release
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity PmodOLEDrgb_charmap is
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
          screen_clear : in  STD_LOGIC := '0';
          
          PMOD_CS      : out STD_LOGIC;
          PMOD_MOSI    : out STD_LOGIC;
          PMOD_SCK     : out STD_LOGIC;
          PMOD_DC      : out STD_LOGIC;
          PMOD_RES     : out STD_LOGIC;
          PMOD_VCCEN   : out STD_LOGIC;
          PMOD_EN      : out STD_LOGIC);
end PmodOLEDrgb_charmap;

architecture Behavioral of PmodOLEDrgb_charmap is

   constant SPI_frequ               : integer := 6666666;                       -- 150ns SPI clk period
   constant SPI_halfper             : integer := (CLK_FREQ_HZ-1)/(SPI_frequ*2); -- max counter value for SPI_SCK hal periods

   constant delay_after_set_EN      : integer := CLK_FREQ_HZ /50;       -- 20ms
   constant delay_after_clear_RES   : integer := CLK_FREQ_HZ /333;      -- 3ms
   constant delay_after_set_RES_2   : integer := CLK_FREQ_HZ /333;      -- 3ms
   constant delay_after_set_VCCEN   : integer := CLK_FREQ_HZ /40;       -- 25ms
   constant delay_for_disp_ok       : integer := CLK_FREQ_HZ /10;       -- 100ms
   constant delay_for_scroll_up     : integer := CLK_FREQ_HZ /1000;     -- 1ms   (570탎 were sufficient on the test OLED, no documentation found on the exact time)
   constant delay_for_clear         : integer := CLK_FREQ_HZ /2000;     -- 500탎 (330탎 should be sufficient for a full screen, 40탎 were sufficient for a line)
   
   -- this is just to get proper integer dimension...
   constant max_wait : integer := delay_for_disp_ok;
   
   signal wait_cnt                  : integer range 0 to max_wait-1;    -- the counter for waiting states


   -- the FSM that controls communication to the Pmod
   type t_OLED_FSM is (waking,            -- the state in which we go from reset
                       set_EN,            -- set EN
                       w_set_EN,          -- wait
                       clear_RES,         -- clear RES
                       w_clear_RES,       -- wait
                       set_RES_2,         -- set RES again
                       w_set_RES_2,       -- wait
                       send_unlock,       -- sends the unlock command : 0xFD 0x12
                       w_unlock,
                       send_disp_off,     -- display off command 0xAE
                       w_disp_off,
                       send_geom,         -- command 0xA0 0x72 (fixme : what does this command do ? reverting the module is 0xA0 0x60)
                       w_send_geom,
                       send_master_cfg,   -- master config, select ext Vcc. 0xAD, 0x8E
                       w_master_cfg,
                       dis_pow_saving,    -- 0xB0 0x0B
                       w_dis_pow_sav,
                       set_phase_len,     -- 0xB1, 0x31
                       w_phase_len,
                       setup_disp_clk,    -- 0xB3 0xF0
                       w_set_disp_clk,
                       pre_charge_voltg,  -- Set the Pre-Charge Voltage, 0xBB, 0x3A
                       w_pcv,
                       set_MastCurrAtt,   -- 0x87, 0x06 (See page 23 of the datasheet)
                       w_set_MCA,
                       set_VCCEN,         -- set VCCEN
                       w_set_VCCEN,
                       disp_on,           -- display on, 0xAF
                       w_disp_on,
                       prep_w_disp_ok,    -- 1 clock cycle to prepare the long wait just after
                       w_disp_ok,
                       cmd_fill_rec,      -- tells to fill the rectangles
                       w_fill_rec,
                       s_ready,
                       cmd_set_cols,
                       w_set_cols,
                       colminmax,
                       w_colminmax,
                       cmd_set_rows,
                       w_set_rows,
                       rowminmax,
                       w_rowminmax,
                       data_send,
                       cmd_scroll_up,
                       w_scroll_up,
                       scroll_start,
                       w_scroll_start,
                       scroll_stop,
                       w_scroll_stop,
                       scroll_dest,
                       w_scroll_dest,
                       scroll_dly,
                       w_scroll_done,
                       clr_row_sc,
                       w_clr_row_sc,
                       clr_row_st,
                       w_clr_row_st,
                       clr_row_nd,
                       w_clr_row_nd,
                       clr_scr_sc,
                       w_clr_scr_sc,
                       clr_scr_st,
                       w_clr_scr_st,
                       clr_scr_nd,
                       w_clr_scr_nd,
                       col_CB,
                       w_col_CB,
                       col_AC,
                       w_col_AC,
                       col_BA,
                       w_col_BA,
                       clear_delay,
                       w_clear_done);
   signal OLED_FSM : t_OLED_FSM;



   --------------------------------------------------------------------------
   -- signals to manage SPI interface
   --------------------------------------------------------------------------
   signal spi_sck       : std_logic;                     -- local copy of the clock
   signal spi_shift_reg : std_logic_vector(15 downto 0); -- the output shift register
   signal spi_rem_bits  : integer range 0 to 15;         -- the number of remaining shifts before next data

   signal spi_send_ack  : boolean;                       -- True when the spi sending is over
   signal spi_active    : boolean;                       -- True when a spi transfer is active
   
   signal col_range     : std_logic_vector(15 downto 0); -- the column range computed from char_col


   --------------------------------------------------------------------------
   -- signals to manage the displayed data
   --------------------------------------------------------------------------
   signal buff_next_pix : std_logic_vector( 7 downto 0); -- the next pixel to send
   signal charmap       : std_logic_vector(47 downto 0); -- the displayed char bitmap
   signal bit_index     : integer range 0 to 47;         -- the bit of the char we are about to display
   signal disp_bit_a    : std_logic;                     -- the bit to be displayed next (asynchronous version)
   signal disp_bit_s    : std_logic;                     -- the bit to be displayed next (synchronized version)
   
   
   signal char_col_cpy   : STD_LOGIC_VECTOR(3 downto 0);
   signal char_row_cpy   : STD_LOGIC_VECTOR(2 downto 0);
   signal char_cpy       : STD_LOGIC_VECTOR(7 downto 0);
   signal foregnd_cpy    : STD_LOGIC_VECTOR(7 downto 0);
   signal backgnd_cpy    : STD_LOGIC_VECTOR(7 downto 0);

   
   

begin

   -- eventual copy of inputs
   no_buffering : if not PARAM_BUFF generate
      char_col_cpy <= char_col;
      char_row_cpy <= char_row;
      char_cpy     <= char;
      foregnd_cpy    <= foregnd;
      backgnd_cpy    <= backgnd;
   end generate;
   
   input_buffering : if PARAM_BUFF generate
      process(clk)
      begin
         if rising_edge(clk) then
            if (char_write or scroll_up or row_clear or screen_clear) = '1' and OLED_FSM = s_ready then
               char_col_cpy <= char_col;
               char_row_cpy <= char_row;
               char_cpy     <= char;
               foregnd_cpy    <= foregnd;
               backgnd_cpy    <= backgnd;
            end if;
         end if;
      end process;
   end generate;
   
   
   -- affecting the outputs...
   process(clk)
   begin
      if rising_edge(clk) then
         if OLED_FSM = data_send then
            PMOD_DC <= '1';
         elsif OLED_FSM = waking or OLED_FSM = s_ready then
            PMOD_DC <= '0';
         end if;
         
         if OLED_FSM = waking or OLED_FSM = w_set_RES_2 then
            PMOD_RES <= '1';
         elsif OLED_FSM = clear_RES then
            PMOD_RES <= '0';
         end if;
         
         if reset = '1' then
            PMOD_EN <= '0';
         elsif OLED_FSM = set_EN then
            PMOD_EN <= '1';
         end if;
         
         if OLED_FSM = set_VCCEN then
            PMOD_VCCEN <= '1';
         elsif OLED_FSM = waking then
            PMOD_VCCEN <= '0';
         end if;
         
         if reset = '1' then
            PMOD_CS <= '1';
         elsif OLED_FSM = w_set_RES_2 then
            -- we assert the SPI CS on the state before sending the first instruction
            PMOD_CS <= '0';
         end if;         
      end if;
   end process;
   
   
   
   
   
   -- the main FSM of the module
   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            OLED_FSM <= waking;
         else
            case OLED_FSM is
               when waking           =>                      OLED_FSM <= set_EN;
               when set_EN           =>                      OLED_FSM <= w_set_EN;
               when w_set_EN         => if wait_cnt = 0 then OLED_FSM <= clear_RES;        end if;
               when clear_RES        =>                      OLED_FSM <= w_clear_RES;
               when w_clear_RES      => if wait_cnt = 0 then OLED_FSM <= set_RES_2;        end if;
               when set_RES_2        =>                      OLED_FSM <= w_set_RES_2;
               when w_set_RES_2      => if wait_cnt = 0 then OLED_FSM <= send_unlock;      end if;
               when send_unlock      =>                      OLED_FSM <= w_unlock;
               when w_unlock         => if spi_send_ack then OLED_FSM <= send_disp_off;    end if;
               when send_disp_off    =>                      OLED_FSM <= w_disp_off;
               when w_disp_off       => if spi_send_ack then OLED_FSM <= send_geom;        end if;
               when send_geom        =>                      OLED_FSM <= w_send_geom;
               when w_send_geom      => if spi_send_ack then OLED_FSM <= send_master_cfg;  end if;
               when send_master_cfg  =>                      OLED_FSM <= w_master_cfg;
               when w_master_cfg     => if spi_send_ack then OLED_FSM <= dis_pow_saving;   end if;
               when dis_pow_saving   =>                      OLED_FSM <= w_dis_pow_sav;
               when w_dis_pow_sav    => if spi_send_ack then OLED_FSM <= set_phase_len;    end if;
               when set_phase_len    =>                      OLED_FSM <= w_phase_len;
               when w_phase_len      => if spi_send_ack then OLED_FSM <= setup_disp_clk;   end if;
               when setup_disp_clk   =>                      OLED_FSM <= w_set_disp_clk;
               when w_set_disp_clk   => if spi_send_ack then OLED_FSM <= pre_charge_voltg; end if;
               when pre_charge_voltg =>                      OLED_FSM <= w_pcv;
               when w_pcv            => if spi_send_ack then OLED_FSM <= set_MastCurrAtt;  end if;
               when set_MastCurrAtt  =>                      OLED_FSM <= w_set_MCA;
               when w_set_MCA        => if spi_send_ack then OLED_FSM <= set_VCCEN;        end if;
               when set_VCCEN        =>                      OLED_FSM <= w_set_VCCEN;
               when w_set_VCCEN      => if wait_cnt = 0 then OLED_FSM <= disp_on;          end if;
               when disp_on          =>                      OLED_FSM <= w_disp_on;
               when w_disp_on        => if spi_send_ack then OLED_FSM <= prep_w_disp_ok;   end if;
               when prep_w_disp_ok   =>                      OLED_FSM <= w_disp_ok;
               when w_disp_ok        => if wait_cnt = 0 then OLED_FSM <= cmd_fill_rec;     end if;
               when cmd_fill_rec     =>                      OLED_FSM <= w_fill_rec;
               when w_fill_rec       => if spi_send_ack then OLED_FSM <= s_ready;          end if;
               when s_ready          => if screen_clear = '1' then OLED_FSM <= clr_scr_sc;
                                     elsif row_clear    = '1' then OLED_FSM <= clr_row_sc;
                                     elsif scroll_up = '1'    then OLED_FSM <= cmd_scroll_up;
                                     elsif char_write = '1'   then OLED_FSM <= cmd_set_cols;  end if;
               when cmd_set_cols     =>                      OLED_FSM <= w_set_cols;
               when w_set_cols       => if spi_send_ack then OLED_FSM <= colminmax;        end if;
               when colminmax        =>                      OLED_FSM <= w_colminmax;
               when w_colminmax      => if spi_send_ack then OLED_FSM <= cmd_set_rows;     end if;
               when cmd_set_rows     =>                      OLED_FSM <= w_set_rows;
               when w_set_rows       => if spi_send_ack then OLED_FSM <= rowminmax;        end if;
               when rowminmax        =>                      OLED_FSM <= w_rowminmax;
               when w_rowminmax      => if spi_send_ack then OLED_FSM <= data_send;        end if;
               when data_send        => if spi_rem_bits = 0 and wait_cnt = 0 and spi_sck = '1' and bit_index=47 then
                                                             OLED_FSM <= s_ready;          end if;
               when cmd_scroll_up    =>                      OLED_FSM <= w_scroll_up;
               when w_scroll_up      => if spi_send_ack then OLED_FSM <= scroll_start;     end if;
               when scroll_start     =>                      OLED_FSM <= w_scroll_start;
               when w_scroll_start   => if spi_send_ack then OLED_FSM <= scroll_stop;      end if;
               when scroll_stop      =>                      OLED_FSM <= w_scroll_stop;
               when w_scroll_stop    => if spi_send_ack then OLED_FSM <= scroll_dest;      end if;
               when scroll_dest      =>                      OLED_FSM <= w_scroll_dest;
               when w_scroll_dest    => if spi_send_ack then OLED_FSM <= scroll_dly;       end if;
               when scroll_dly       =>                      OLED_FSM <= w_scroll_done;
               when w_scroll_done    => if wait_cnt = 0 then OLED_FSM <= s_ready;          end if;
               when clr_row_sc       =>                      OLED_FSM <= w_clr_row_sc;
               when w_clr_row_sc     => if spi_send_ack then OLED_FSM <= clr_row_st;       end if;
               when clr_row_st       =>                      OLED_FSM <= w_clr_row_st;
               when w_clr_row_st     => if spi_send_ack then OLED_FSM <= clr_row_nd;       end if;
               when clr_row_nd       =>                      OLED_FSM <= w_clr_row_nd;
               when w_clr_row_nd     => if spi_send_ack then OLED_FSM <= col_CB;           end if;
               when clr_scr_sc       =>                      OLED_FSM <= w_clr_scr_sc;
               when w_clr_scr_sc     => if spi_send_ack then OLED_FSM <= clr_scr_st;       end if;
               when clr_scr_st       =>                      OLED_FSM <= w_clr_scr_st;
               when w_clr_scr_st     => if spi_send_ack then OLED_FSM <= clr_scr_nd;       end if;
               when clr_scr_nd       =>                      OLED_FSM <= w_clr_scr_nd;
               when w_clr_scr_nd     => if spi_send_ack then OLED_FSM <= col_CB;           end if;
               when col_CB           =>                      OLED_FSM <= w_col_CB;
               when w_col_CB         => if spi_send_ack then OLED_FSM <= col_AC;           end if;
               when col_AC           =>                      OLED_FSM <= w_col_AC;
               when w_col_AC         => if spi_send_ack then OLED_FSM <= col_BA;           end if;
               when col_BA           =>                      OLED_FSM <= w_col_BA;
               when w_col_BA         => if spi_send_ack then OLED_FSM <= clear_delay;      end if;
               when clear_delay      =>                      OLED_FSM <= w_clear_done;
               when w_clear_done     => if wait_cnt = 0 then OLED_FSM <= s_ready;          end if;
            end case;
         end if;
      end if;
   end process;


   ready <= '1' when OLED_FSM = s_ready else '0';

   -- wait counter process
   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when set_EN           => wait_cnt <= delay_after_set_EN       - 1;
            when clear_RES        => wait_cnt <= delay_after_clear_RES    - 1;
            when set_RES_2        => wait_cnt <= delay_after_set_RES_2    - 1;
            when set_VCCEN        => wait_cnt <= delay_after_set_VCCEN    - 1;
            when prep_w_disp_ok   => wait_cnt <= delay_for_disp_ok        - 1;
            when scroll_dly       => wait_cnt <= delay_for_scroll_up      - 1;
            when clear_delay      => wait_cnt <= delay_for_clear          - 1;
            when send_unlock
               | send_disp_off
               | send_geom
               | send_master_cfg
               | dis_pow_saving
               | set_phase_len
               | setup_disp_clk
               | pre_charge_voltg
               | set_MastCurrAtt
               | disp_on
               | cmd_fill_rec
               | cmd_set_cols
               | colminmax
               | cmd_set_rows
               | rowminmax
               | cmd_scroll_up
               | scroll_start
               | scroll_stop
               | scroll_dest
               | clr_row_sc
               | clr_row_st
               | clr_row_nd
               | clr_scr_sc
               | clr_scr_st
               | clr_scr_nd
               | col_CB
               | col_AC
               | col_BA               
                                  => wait_cnt <= SPI_halfper;
            when others           => -- in these states, we will change as soon as wait_cnt is 0
                                     -- or we are sending data through SPI, so we reload SPI_halfper just in case.
               if wait_cnt > 0 then
                  wait_cnt <= wait_cnt - 1;
               else
                  wait_cnt <= SPI_halfper;
               end if;
         end case;
      end if;
   end process;


   --------------------------------------------------------------------------
   -- in the next processes, we manage the spi output
   --------------------------------------------------------------------------
   process(OLED_FSM)
   begin
      case OLED_FSM is
         when w_unlock
            | w_disp_off
            | w_send_geom
            | w_master_cfg
            | w_dis_pow_sav
            | w_phase_len
            | w_set_disp_clk
            | w_pcv
            | w_set_MCA
            | w_disp_on
            | w_fill_rec
            | w_set_cols
            | w_colminmax
            | w_set_rows
            | w_rowminmax
            | data_send
            | w_scroll_up
            | w_scroll_start
            | w_scroll_stop
            | w_scroll_dest
            | w_clr_row_sc
            | w_clr_row_st
            | w_clr_row_nd
            | w_clr_scr_sc
            | w_clr_scr_st
            | w_clr_scr_nd
            | w_col_CB
            | w_col_AC
            | w_col_BA
                            => spi_active <= True;
         when others        => spi_active <= False;
      end case;
   end process;


   -- SPI clock
   PMOD_sck <= spi_sck;
   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            spi_sck <= '0';
         elsif spi_active then
            if wait_cnt = 0 then
               spi_sck <= not spi_sck;
            end if;
         else
            spi_sck <= '0';
         end if;
      end if;
   end process;

   -- remaining bits in the shift reg
   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when send_unlock
               | send_geom
               | send_master_cfg
               | dis_pow_saving
               | set_phase_len
               | setup_disp_clk
               | pre_charge_voltg
               | set_MastCurrAtt
               | cmd_fill_rec
               | colminmax
               | rowminmax
               | scroll_start
               | scroll_stop
               | scroll_dest
               | clr_row_st
               | clr_row_nd
               | clr_scr_st
               | clr_scr_nd
               | col_CB
               | col_AC
               | col_BA           => spi_rem_bits <= 15;
            when send_disp_off
               | disp_on
               | cmd_set_cols
               | cmd_set_rows
               | cmd_scroll_up
               | clr_row_sc
               | clr_scr_sc       => spi_rem_bits <= 7;
            when others           => 
               if wait_cnt = 0 and spi_sck = '1' and spi_active then
                  if spi_rem_bits > 0 then
                     spi_rem_bits <= spi_rem_bits - 1;
                  else
                     spi_rem_bits <= 7;
                  end if;
               end if;
         end case;
      end if;
   end process;



   process(clk)
   begin
      if rising_edge(clk) then
         col_range(15 downto 8) <= '0' & std_logic_vector(unsigned('0' & char_col_cpy & "00") + unsigned("00" & char_col_cpy & '0'));
         col_range( 7 downto 0) <= '0' & std_logic_vector(unsigned('0' & char_col_cpy & "00") + unsigned("00" & char_col_cpy & '0') + 5);
      end if;
   end process;



   -- remaining bits in the shift reg
   PMOD_MOSI <= spi_shift_reg(15);
   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when send_unlock      => spi_shift_reg <= x"FD12";
            when send_geom        => if LEFT_SIDE then spi_shift_reg <= x"A021";
                                     else              spi_shift_reg <= x"A033"; end if;
            when send_master_cfg  => spi_shift_reg <= x"AD8E";
            when dis_pow_saving   => spi_shift_reg <= x"B00B";
            when set_phase_len    => spi_shift_reg <= x"B131";
            when setup_disp_clk   => spi_shift_reg <= x"B3F0";
            when pre_charge_voltg => spi_shift_reg <= x"BB2A";
            when set_MastCurrAtt  => spi_shift_reg <= x"8706";
            when send_disp_off    => spi_shift_reg <= x"AE00";
            when disp_on          => spi_shift_reg <= x"AF00";
            when cmd_fill_rec     => spi_shift_reg <= x"2601";
            when cmd_set_cols     => spi_shift_reg <= x"1500";
            when colminmax        => spi_shift_reg <= col_range; 
            when cmd_set_rows     => spi_shift_reg <= x"7500";
            when rowminmax        => spi_shift_reg <= "00" & char_row_cpy & "00000" & char_row_cpy & "111";
            when cmd_scroll_up    => spi_shift_reg <= x"2300";
            when scroll_start     => spi_shift_reg <= x"0008";
            when scroll_stop      => spi_shift_reg <= x"5F3F";
            when scroll_dest      => spi_shift_reg <= x"0000";
            when clr_row_sc       => spi_shift_reg <= x"2200";
            when clr_row_st       => spi_shift_reg <= "0000000000" & char_row_cpy & "000";
            when clr_row_nd       => spi_shift_reg <= "0101111100" & char_row_cpy & "111";
            when clr_scr_sc       => spi_shift_reg <= x"2200";
            when clr_scr_st       => spi_shift_reg <= x"0000";
            when clr_scr_nd       => spi_shift_reg <= x"5F3F";
            when col_CB           => spi_shift_reg <= "00" & backgnd_cpy(7 downto 5) & backgnd_cpy(7 downto 6) & "000" & backgnd_cpy(4 downto 2) & backgnd_cpy(4 downto 2);
            when col_AC           => spi_shift_reg <= "00" & backgnd_cpy(1 downto 0) & backgnd_cpy(1 downto 0) & backgnd_cpy(1) & "000" & backgnd_cpy(7 downto 5) & backgnd_cpy(7 downto 6) & '0';
            when col_BA           => spi_shift_reg <= "00" & backgnd_cpy(4 downto 2) & backgnd_cpy(4 downto 2) & "00" & backgnd_cpy(1 downto 0) & backgnd_cpy(1 downto 0) & backgnd_cpy(1) & '0';
            when others           => 
               if wait_cnt = 0 and spi_sck = '1' and spi_active then
                  if spi_rem_bits > 0 then
                     spi_shift_reg(15 downto 1) <= spi_shift_reg(14 downto 0);
                  else
                     spi_shift_reg(15 downto 8) <= buff_next_pix;
                  end if;
               end if;
         end case;
      end if;
   end process;

   -- this is to inform OLED_FSM that a SPI transfer is over
   spi_send_ack <= wait_cnt = 0 and spi_sck = '1' and spi_rem_bits = 0;




   --------------------------------------------------------------------------
   -- what about displaying something ? :)
   --------------------------------------------------------------------------
   process(clk)
   begin
      if rising_edge(clk) then
         if OLED_FSM /= data_send then
            bit_index <= 47;
         elsif spi_rem_bits = 6 and wait_cnt = 0 and spi_sck = '1' then
            if  bit_index>0 then
               bit_index <= bit_index - 1;
            else
               bit_index <= 47;
            end if;
         end if;
      end if;
   end process;


   char_bitmap : process(clk)
   begin
      if rising_edge(clk) then
         case char_cpy is
            when "00000000" => charmap <= x"007c447c0000";
            when "00000001" => charmap <= x"00247c040000";
            when "00000010" => charmap <= x"005c54740000";
            when "00000011" => charmap <= x"0054547c0000";
            when "00000100" => charmap <= x"0070107c0000";
            when "00000101" => charmap <= x"0074545c0000";
            when "00000110" => charmap <= x"007c545c0000";
            when "00000111" => charmap <= x"004c50600000";
            when "00001000" => charmap <= x"007c547c0000";
            when "00001001" => charmap <= x"0074547c0000";
            when "00001010" => charmap <= x"081c08780000";
            when "00001011" => charmap <= x"00247d040000";
            when "00001100" => charmap <= x"005c55740000";
            when "00001101" => charmap <= x"0054557c0000";
            when "00001110" => charmap <= x"0070117c0000";
            when "00001111" => charmap <= x"0074555c0000";
            when "00010000" => charmap <= x"007c555c0000";
            when "00010001" => charmap <= x"004c51600000";
            when "00010010" => charmap <= x"007c557c0000";
            when "00010011" => charmap <= x"0074557c0000";
            when "00010100" => charmap <= x"007d447d0000";
            when "00010101" => charmap <= x"00257c050000";
            when "00010110" => charmap <= x"005d54750000";
            when "00010111" => charmap <= x"0055547d0000";
            when "00011000" => charmap <= x"0071107d0000";
            when "00011001" => charmap <= x"0075545d0000";
            when "00011010" => charmap <= x"007d545d0000";
            when "00011011" => charmap <= x"004d50610000";
            when "00011100" => charmap <= x"ffabd5abd5ff";
            when "00011101" => charmap <= x"fefefefefe00";
            when "00011110" => charmap <= x"00081c3e1c00";
            when "00011111" => charmap <= x"001c3e1c0800";
            when "00100000" => charmap <= x"000000000000";
            when "00100001" => charmap <= x"0000fa000000";
            when "00100010" => charmap <= x"00e000e00000";
            when "00100011" => charmap <= x"28fe28fe2800";
            when "00100100" => charmap <= x"2454fe544800";
            when "00100101" => charmap <= x"c4c810264600";
            when "00100110" => charmap <= x"6c926a040a00";
            when "00100111" => charmap <= x"0000e0000000";
            when "00101000" => charmap <= x"003844820000";
            when "00101001" => charmap <= x"008244380000";
            when "00101010" => charmap <= x"105438541000";
            when "00101011" => charmap <= x"10107c101000";
            when "00101100" => charmap <= x"000d0e000000";
            when "00101101" => charmap <= x"101010101000";
            when "00101110" => charmap <= x"000606000000";
            when "00101111" => charmap <= x"040810204000";
            when "00110000" => charmap <= x"7c8a92a27c00";
            when "00110001" => charmap <= x"0042fe020000";
            when "00110010" => charmap <= x"468a92926200";
            when "00110011" => charmap <= x"449292926c00";
            when "00110100" => charmap <= x"182848fe0800";
            when "00110101" => charmap <= x"e4a2a2a29c00";
            when "00110110" => charmap <= x"3c5292920c00";
            when "00110111" => charmap <= x"808e90a0c000";
            when "00111000" => charmap <= x"6c9292926c00";
            when "00111001" => charmap <= x"609292947800";
            when "00111010" => charmap <= x"006c6c000000";
            when "00111011" => charmap <= x"006d6e000000";
            when "00111100" => charmap <= x"102844820000";
            when "00111101" => charmap <= x"282828282800";
            when "00111110" => charmap <= x"824428100000";
            when "00111111" => charmap <= x"40808a906000";
            when "01000000" => charmap <= x"7c82ba927400";
            when "01000001" => charmap <= x"7e9090907e00";
            when "01000010" => charmap <= x"fe9292926c00";
            when "01000011" => charmap <= x"7c8282824400";
            when "01000100" => charmap <= x"fe8282443800";
            when "01000101" => charmap <= x"fe9292928200";
            when "01000110" => charmap <= x"fe9090908000";
            when "01000111" => charmap <= x"7c8292925e00";
            when "01001000" => charmap <= x"fe101010fe00";
            when "01001001" => charmap <= x"0082fe820000";
            when "01001010" => charmap <= x"0c020202fc00";
            when "01001011" => charmap <= x"fe1028448200";
            when "01001100" => charmap <= x"fe0202020200";
            when "01001101" => charmap <= x"fe403040fe00";
            when "01001110" => charmap <= x"fe201008fe00";
            when "01001111" => charmap <= x"7c8282827c00";
            when "01010000" => charmap <= x"fe9090906000";
            when "01010001" => charmap <= x"7c828a847a00";
            when "01010010" => charmap <= x"fe9098946200";
            when "01010011" => charmap <= x"649292924c00";
            when "01010100" => charmap <= x"8080fe808000";
            when "01010101" => charmap <= x"fc020202fc00";
            when "01010110" => charmap <= x"e0180618e000";
            when "01010111" => charmap <= x"fe041804fe00";
            when "01011000" => charmap <= x"c6281028c600";
            when "01011001" => charmap <= x"c0201e20c000";
            when "01011010" => charmap <= x"868a92a2c200";
            when "01011011" => charmap <= x"00fe82820000";
            when "01011100" => charmap <= x"402010080400";
            when "01011101" => charmap <= x"008282fe0000";
            when "01011110" => charmap <= x"204080402000";
            when "01011111" => charmap <= x"020202020200";
            when "01100000" => charmap <= x"00c020000000";
            when "01100001" => charmap <= x"042a2a2a1e00";
            when "01100010" => charmap <= x"fe1222221c00";
            when "01100011" => charmap <= x"1c2222221200";
            when "01100100" => charmap <= x"1c222212fe00";
            when "01100101" => charmap <= x"1c2a2a2a1800";
            when "01100110" => charmap <= x"107e90804000";
            when "01100111" => charmap <= x"182525291e00";
            when "01101000" => charmap <= x"fe1020201e00";
            when "01101001" => charmap <= x"0022be020000";
            when "01101010" => charmap <= x"020121be0000";
            when "01101011" => charmap <= x"fe0814220000";
            when "01101100" => charmap <= x"0082fe020000";
            when "01101101" => charmap <= x"3e201c201e00";
            when "01101110" => charmap <= x"3e1020201e00";
            when "01101111" => charmap <= x"1c2222221c00";
            when "01110000" => charmap <= x"3f2424241800";
            when "01110001" => charmap <= x"182424243f00";
            when "01110010" => charmap <= x"3e1020201000";
            when "01110011" => charmap <= x"122a2a2a2400";
            when "01110100" => charmap <= x"20fc22220400";
            when "01110101" => charmap <= x"3c0202043e00";
            when "01110110" => charmap <= x"380402043800";
            when "01110111" => charmap <= x"3c020c023c00";
            when "01111000" => charmap <= x"22241c122200";
            when "01111001" => charmap <= x"380505093e00";
            when "01111010" => charmap <= x"22262a322200";
            when "01111011" => charmap <= x"106c82820000";
            when "01111100" => charmap <= x"0000fe000000";
            when "01111101" => charmap <= x"0082826c1000";
            when "01111110" => charmap <= x"102010081000";
            when "01111111" => charmap <= x"aa55aa55aa55";
            when "10000000" => charmap <= x"060a1a264200";
            when "10000001" => charmap <= x"a2948894a200";
            when "10000010" => charmap <= x"605844586000";
            when "10000011" => charmap <= x"0804fe808000";
            when "10000100" => charmap <= x"04027c804000";
            when "10000101" => charmap <= x"82c6aa92c600";
            when "10000110" => charmap <= x"fefe7c381000";
            when "10000111" => charmap <= x"203e203e2000";
            when "10001000" => charmap <= x"0c9252321c00";
            when "10001001" => charmap <= x"0a1a2a4a8a00";
            when "10001010" => charmap <= x"8a4a2a1a0a00";
            when "10001011" => charmap <= x"282c38682800";
            when "10001100" => charmap <= x"1c22221c2200";
            when "10001101" => charmap <= x"101054381000";
            when "10001110" => charmap <= x"103854101000";
            when "10001111" => charmap <= x"0804fe040800";
            when "10010000" => charmap <= x"2040fe402000";
            when "10010001" => charmap <= x"1020100e3000";
            when "10010010" => charmap <= x"0c52b21c0000";
            when "10010011" => charmap <= x"1c2a2a2a0000";
            when "10010100" => charmap <= x"10201c201f00";
            when "10010101" => charmap <= x"7c92927c0000";
            when "10010110" => charmap <= x"621408040200";
            when "10010111" => charmap <= x"013e48483000";
            when "10011000" => charmap <= x"1c22223c2000";
            when "10011001" => charmap <= x"10203c222400";
            when "10011010" => charmap <= x"3c020c221c00";
            when "10011011" => charmap <= x"0c1424140c00";
            when "10011100" => charmap <= x"80fe80fe8000";
            when "10011101" => charmap <= x"7a8680867a00";
            when "10011110" => charmap <= x"003838380000";
            when "10011111" => charmap <= x"182418241800";
            when "10100000" => charmap <= x"000000000000";
            when "10100001" => charmap <= x"0000be000000";
            when "10100010" => charmap <= x"18247e242400";
            when "10100011" => charmap <= x"127e92824200";
            when "10100100" => charmap <= x"ba444444ba00";
            when "10100101" => charmap <= x"d4341e34d400";
            when "10100110" => charmap <= x"2020f8202000";
            when "10100111" => charmap <= x"106aaaac1000";
            when "10101000" => charmap <= x"008000800000";
            when "10101001" => charmap <= x"7cbaaa827c00";
            when "10101010" => charmap <= x"14acac740000";
            when "10101011" => charmap <= x"102854284400";
            when "10101100" => charmap <= x"101010180000";
            when "10101101" => charmap <= x"101010100000";
            when "10101110" => charmap <= x"7cbab28a7c00";
            when "10101111" => charmap <= x"202020202000";
            when "10110000" => charmap <= x"00e0a0e00000";
            when "10110001" => charmap <= x"2222fa222200";
            when "10110010" => charmap <= x"00b8a8e80000";
            when "10110011" => charmap <= x"00a8a8f80000";
            when "10110100" => charmap <= x"000040800000";
            when "10110101" => charmap <= x"1f02021c0200";
            when "10110110" => charmap <= x"60f2fe80fe00";
            when "10110111" => charmap <= x"001818000000";
            when "10111000" => charmap <= x"000105020000";
            when "10111001" => charmap <= x"0048f8080000";
            when "10111010" => charmap <= x"649494946400";
            when "10111011" => charmap <= x"442854281000";
            when "10111100" => charmap <= x"e8102c440e00";
            when "10111101" => charmap <= x"e81020561a00";
            when "10111110" => charmap <= x"a8f81c244e00";
            when "10111111" => charmap <= x"0c12a2020400";
            when "11000000" => charmap <= x"04126c904000";
            when "11000001" => charmap <= x"04020214181c";
            when "11000010" => charmap <= x"e0107c926000";
            when "11000011" => charmap <= x"92aafeaa9200";
            when "11000100" => charmap <= x"423c08906000";
            when "11000101" => charmap <= x"86887c22c200";
            when "11000110" => charmap <= x"e010fe10e000";
            when "11000111" => charmap <= x"788585864800";
            when "11001000" => charmap <= x"00e0382638e0";
            when "11001001" => charmap <= x"82929292fe00";
            when "11001010" => charmap <= x"fe00fe00fe00";
            when "11001011" => charmap <= x"00fe00fe0000";
            when "11001100" => charmap <= x"545454545400";
            when "11001101" => charmap <= x"040404040400";
            when "11001110" => charmap <= x"0404040e0400";
            when "11001111" => charmap <= x"2868aa2c2800";
            when "11010000" => charmap <= x"10fe92443800";
            when "11010001" => charmap <= x"3e508844be00";
            when "11010010" => charmap <= x"1ca262221c00";
            when "11010011" => charmap <= x"1c2262a21c00";
            when "11010100" => charmap <= x"1c62a2621c00";
            when "11010101" => charmap <= x"5ca262a21c00";
            when "11010110" => charmap <= x"1ca222a21c00";
            when "11010111" => charmap <= x"442810284400";
            when "11011000" => charmap <= x"3a4c5464b800";
            when "11011001" => charmap <= x"3c8242023c00";
            when "11011010" => charmap <= x"3c0242823c00";
            when "11011011" => charmap <= x"1c4282421c00";
            when "11011100" => charmap <= x"3c8202823c00";
            when "11011101" => charmap <= x"20104e902000";
            when "11011110" => charmap <= x"82feaa281000";
            when "11011111" => charmap <= x"7fa8a4a45800";
            when "11100000" => charmap <= x"04aa6a2a1e00";
            when "11100001" => charmap <= x"042a6aaa1e00";
            when "11100010" => charmap <= x"046aaa6a1e00";
            when "11100011" => charmap <= x"44aa6aaa1e00";
            when "11100100" => charmap <= x"04aa2aaa1e00";
            when "11100101" => charmap <= x"04eaaaea1e00";
            when "11100110" => charmap <= x"2e2a1e2a3a00";
            when "11100111" => charmap <= x"182525261400";
            when "11101000" => charmap <= x"1caa6a2a1800";
            when "11101001" => charmap <= x"1c2a6aaa1800";
            when "11101010" => charmap <= x"1c6aaa6a1800";
            when "11101011" => charmap <= x"1caa2aaa1800";
            when "11101100" => charmap <= x"00925e020000";
            when "11101101" => charmap <= x"00125e820000";
            when "11101110" => charmap <= x"00529e420000";
            when "11101111" => charmap <= x"00921e820000";
            when "11110000" => charmap <= x"0c1252fc4000";
            when "11110001" => charmap <= x"1e4890508e00";
            when "11110010" => charmap <= x"0c9252120c00";
            when "11110011" => charmap <= x"0c1252920c00";
            when "11110100" => charmap <= x"0c5292520c00";
            when "11110101" => charmap <= x"0c5292528c00";
            when "11110110" => charmap <= x"0c9212920c00";
            when "11110111" => charmap <= x"101054101000";
            when "11111000" => charmap <= x"1a242a122c00";
            when "11111001" => charmap <= x"1c8242041e00";
            when "11111010" => charmap <= x"1c0242841e00";
            when "11111011" => charmap <= x"1c4282441e00";
            when "11111100" => charmap <= x"1c8202841e00";
            when "11111101" => charmap <= x"180545891e00";
            when "11111110" => charmap <= x"7f2424180000";
            when others     => charmap <= x"188505891e00";
         end case;
         disp_bit_a <= charmap(bit_index);
      end if;
   end process;



   process(clk)
   begin
      if rising_edge(clk) then
         -- we first synchronize the bit to display to limit the critical path
         -- (and help the synthetizer to eventually infer a BRAM)
         disp_bit_s <= disp_bit_a;
         -- then we choose the correct color
         if disp_bit_s = '1' then
            buff_next_pix <= foregnd_cpy;
         else
            buff_next_pix <= backgnd_cpy;
         end if;
      end if;
   end process;





end Behavioral;

