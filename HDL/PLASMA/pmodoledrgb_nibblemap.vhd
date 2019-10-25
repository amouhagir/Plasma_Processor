----------------------------------------------------------------------------------------------------
-- PmodOLEDrgb_nibblemap
--    Version V1.0 (2017/08/05)
--    (c)2017 Y. BORNAT - Bordeaux INP / ENSEIRB-MATMECA
--    This module controls the OLEDrgb Pmod to display hexadecimal chars in an array
----------------------------------------------------------------------------------------------------
-- For the last version and a more complete documentation, please visit
-- http://bornat.vvv.enseirb.fr/wiki/doku.php?id=en202:pmodoledrgb
--
-- How to use This module :
---------------------------
--   - The nibble_row and nibble_col are used to address any position of the 16x8 char array. Position 0,0 is the top left char
--   - To affect a new char at a given position, user should assert nibble_write, address the concerned char and provide
--     the new hexadecimal value on 'nibble' on the same rising edge of clk. After reading nibble_write at '1', the module will
--     reset the 'ready' output until the operation is performed. Once 'ready' is set again, the module can accept
--     a new char value and position for display
--   - when an operation is performed, the command bit should be reset by user, but the parameters should keep their value
--     unchanged until the ready bit is set again. It is possible to change this behavior setting the PARAM_BUFF generic to
--     True. The module will then require more hardware resources to perform its own copy of the inputs when reading any
--     command bit at '1'.
--   - User can optionnaly provide a foreground and/or a background color for each char. default is white on black.
--     color format is rrrgggbb so 0xE0 mean red, 0x1C means green and 0x03 means blue.
--
--   - optionnal commands 'nibble_clear', 'row_clear' and 'screen_clear' respectively fill the addressed char, the 
--     addressed line or the whole screen with the background color.
--     These three commands require the module to be ready. During the processing time, the 'ready' output will be reset.
--     if several commands are input at the same time, the priority list is (from high to low) : screen_clear, row_clear,
--     nibble_clear, nibble_write.
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


entity PmodOLEDrgb_nibblemap is
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
end PmodOLEDrgb_nibblemap;

architecture Behavioral of PmodOLEDrgb_nibblemap is

   constant SPI_frequ               : integer := 6666666;                       -- 150ns SPI clk period
   constant SPI_halfper             : integer := (CLK_FREQ_HZ-1)/(SPI_frequ*2); -- max counter value for SPI_SCK hal periods

   constant delay_after_set_EN      : integer := CLK_FREQ_HZ /50;       -- 20ms
   constant delay_after_clear_RES   : integer := CLK_FREQ_HZ /333;      -- 15ms (actually 15.151ms) officially 3ms
   constant delay_after_set_RES_2   : integer := CLK_FREQ_HZ /333;      -- 15ms (actually 15.151ms) officially 3ms
   constant delay_after_set_VCCEN   : integer := CLK_FREQ_HZ /40;       -- 25ms
   constant delay_for_disp_ok       : integer := CLK_FREQ_HZ /10;       -- 100ms
   constant delay_for_clear         : integer := CLK_FREQ_HZ /2000;     -- 500µs (330µs should be sufficient for a full screen, 40µs were sufficient for a line)

   
   -- this is just to get proper integer dimension...
   constant max_wait : integer := CLK_FREQ_HZ /10;
   
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
                       clr_nibble_sc,
                       w_clr_nibble_sc,
                       clr_nibble_st,
                       w_clr_nibble_st,
                       clr_nibble_nd,
                       w_clr_nibble_nd,
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
                       clear_init,
                       wait_clear_done);
   signal OLED_FSM : t_OLED_FSM;



   --------------------------------------------------------------------------
   -- signals to manage SPI interface
   --------------------------------------------------------------------------
   signal spi_sck       : std_logic;                     -- local copy of the clock
   signal spi_shift_reg : std_logic_vector(15 downto 0); -- the output shift register
   signal spi_rem_bits  : integer range 0 to 15;         -- the number of remaining shifts before next data

   signal spi_send_ack  : boolean;                       -- True when the spi sending is over
   signal spi_active    : boolean;                       -- True when a spi transfer is active
   
   signal col_range     : std_logic_vector(15 downto 0); -- the column range computed from nibble_col


   --------------------------------------------------------------------------
   -- signals to manage the displayed data
   --------------------------------------------------------------------------
   signal buff_next_pix : std_logic_vector( 7 downto 0); -- the next pixel to send
   signal pixmap        : std_logic_vector(47 downto 0); -- the displayed char bitmap
   signal bit_index     : integer range 0 to 47;         -- the bit of the char we are about to display
   signal disp_bit_a    : std_logic;                     -- the bit to be displayed next (asynchronous version)
   signal disp_bit_s    : std_logic;                     -- the bit to be displayed next (synchronized version)
   
   
   signal nibble_col_cpy : STD_LOGIC_VECTOR(3 downto 0);
   signal nibble_row_cpy : STD_LOGIC_VECTOR(2 downto 0);
   signal nibble_cpy     : STD_LOGIC_VECTOR(3 downto 0);
   signal foregnd_cpy    : STD_LOGIC_VECTOR(7 downto 0);
   signal backgnd_cpy    : STD_LOGIC_VECTOR(7 downto 0);

   
   

begin

   -- eventual copy of inputs
   no_buffering : if not PARAM_BUFF generate
      nibble_col_cpy <= nibble_col;
      nibble_row_cpy <= nibble_row;
      nibble_cpy     <= nibble;
      foregnd_cpy    <= foregnd;
      backgnd_cpy    <= backgnd;
   end generate;
   
   input_buffering : if PARAM_BUFF generate
      process(clk)
      begin
         if rising_edge(clk) then
            if (nibble_write or nibble_clear or row_clear or screen_clear) = '1' and OLED_FSM = s_ready then
               nibble_col_cpy <= nibble_col;
               nibble_row_cpy <= nibble_row;
               nibble_cpy     <= nibble;
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
                                     elsif nibble_clear = '1' then OLED_FSM <= clr_nibble_sc;
                                     elsif nibble_write = '1' then OLED_FSM <= cmd_set_cols;  end if;
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
               when clr_nibble_sc    =>                      OLED_FSM <= w_clr_nibble_sc;
               when w_clr_nibble_sc  => if spi_send_ack then OLED_FSM <= clr_nibble_st;    end if;
               when clr_nibble_st    =>                      OLED_FSM <= w_clr_nibble_st;
               when w_clr_nibble_st  => if spi_send_ack then OLED_FSM <= clr_nibble_nd;    end if;
               when clr_nibble_nd    =>                      OLED_FSM <= w_clr_nibble_nd;
               when w_clr_nibble_nd  => if spi_send_ack then OLED_FSM <= col_CB;           end if;
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
               when w_col_BA         => if spi_send_ack then OLED_FSM <= clear_init;       end if;
               when clear_init       =>                      OLED_FSM <= wait_clear_done;
               when wait_clear_done  => if wait_cnt = 0 then OLED_FSM <= s_ready;          end if;
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
            when clear_init       => wait_cnt <= delay_for_clear          - 1;
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
               | clr_nibble_sc
               | clr_nibble_st
               | clr_nibble_nd
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
            | w_clr_nibble_sc
            | w_clr_nibble_st
            | w_clr_nibble_nd
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
               | clr_nibble_st
               | clr_nibble_nd
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
               | clr_nibble_sc
               | clr_row_sc
               | clr_scr_sc       => spi_rem_bits <= 7;
            when others           => 
               if wait_cnt = 0 and spi_sck = '1' then
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
         col_range(15 downto 8) <= '0' & std_logic_vector(unsigned('0' & nibble_col_cpy & "00") + unsigned("00" & nibble_col_cpy & '0'));
         col_range( 7 downto 0) <= '0' & std_logic_vector(unsigned('0' & nibble_col_cpy & "00") + unsigned("00" & nibble_col_cpy & '0') + 5);
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
            when rowminmax        => spi_shift_reg <= "00" & nibble_row_cpy & "00000" & nibble_row_cpy & "111";
            when clr_nibble_sc    => spi_shift_reg <= x"2200";
            when clr_nibble_st    => spi_shift_reg <= col_range(15 downto 8) & "00" & nibble_row_cpy & "000";
            when clr_nibble_nd    => spi_shift_reg <= col_range( 7 downto 0) & "00" & nibble_row_cpy & "111";
            when clr_row_sc       => spi_shift_reg <= x"2200";
            when clr_row_st       => spi_shift_reg <= "0000000000" & nibble_row_cpy & "000";
            when clr_row_nd       => spi_shift_reg <= "0101111100" & nibble_row_cpy & "111";
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


   char_bitmap : process(nibble_cpy, bit_index)
   begin
      case nibble_cpy is
         when "0000" => pixmap <= x"7C8A92A27C00";
         when "0001" => pixmap <= x"0042FE020000";
         when "0010" => pixmap <= x"42868A926200";
         when "0011" => pixmap <= x"8482A2D28C00";
         when "0100" => pixmap <= x"182848FE0800";
         when "0101" => pixmap <= x"E2A2A2A29C00";
         when "0110" => pixmap <= x"3C5292920C00";
         when "0111" => pixmap <= x"808E90A0C000";
         when "1000" => pixmap <= x"6C9292926C00";
         when "1001" => pixmap <= x"609292947800";
         when "1010" => pixmap <= x"7E9090907E00";
         when "1011" => pixmap <= x"FE9292926C00";
         when "1100" => pixmap <= x"7C8282824400";
         when "1101" => pixmap <= x"FE8282443800";
         when "1110" => pixmap <= x"FE9292928200";
         when others => pixmap <= x"FE9090908000";
      end case;
   end process;

   process(clk)
   begin
      if rising_edge(clk) then
         disp_bit_a <= pixmap(bit_index);
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

