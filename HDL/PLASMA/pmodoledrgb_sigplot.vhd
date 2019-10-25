----------------------------------------------------------------------------------------------------
-- PmodOLEDrgb_sigplot
--    Version V1.1.1 (2017/10/29)
--    (c)2017 Y. BORNAT - Bordeaux INP / ENSEIRB-MATMECA
--    This module controls the OLEDrgb Pmod to display waveform plots.
----------------------------------------------------------------------------------------------------
-- For the last version and a more complete documentation, please visit
-- http://bornat.vvv.enseirb.fr/wiki/doku.php?id=en202:pmodoledrgb
--
-- How to use This module :
---------------------------
--   - It is possible to display up to 4 plots on the same diagram. Each time a new sample is input,
--     the sample value shall be presented on 'sample', the considered curve shall be indicated on
--     sample_num and the sample_en bit should ne set on the same rising edge of clk. The plot coordinates
--     follow the mathematical logic instead of the screen address logic, so higher values are displayed
--     at the top of the screen, and lower values at the bottom. It is possible to change this behavior
--     thanks to the MAX_ON_TOP generic.
--
--   - to provide more flexibility, horizontal shifts are performed as separate commands. It is then
--     possible to input several points/pixel column, or to dynamically change the display scale. To make
--     the display progress at each sample, disp_shift and sample_en must be asserted simultaneously.
--
--   - When a new point is entered for a given curve and the previous point is still visible on the
--     screen, a line is drawn between the two points, regardless the horizontal position of the last
--     point. It is then possible to draw curves at different sampling rates.
--
--   - When performing a horizontal shift, user can optionnally provide a 4-bit background greyscale
--     value on back_grad. This feature is usefull to indicate triggers, events or timing scales. It is not possible
--     to change the background color of a pixel column once the horizontal shift has been performed.
--     
----------------------------------------------------------------------------------
-- known bugs :
--    - None so far
--
-------------------------------------------------------------------------------------------------------
-- History
----------------------------------------------------------------------------------
-- V1.1.1 (2017/10/29) by Xavier Marino
--    - fixed typo in state name line_start_cpy
-- V1.1.0 (2017/10/25) by YB
--    - fixed bad comment hiding IEEE lib declaration
--    - if sample_en and disp_shift are asserted at the same time, displays the sample then
--      shifts the display.
-- V1.0 (2017/08/06) by YB
--    - initial release
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity PmodOLEDrgb_sigplot is
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
end PmodOLEDrgb_sigplot;

architecture Behavioral of PmodOLEDrgb_sigplot is

   constant SPI_frequ               : integer := 6666666;                       -- 150ns SPI clk period
   constant SPI_halfper             : integer := (CLK_FREQ_HZ-1)/(SPI_frequ*2); -- max counter value for SPI_SCK hal periods

   constant delay_after_set_EN      : integer := CLK_FREQ_HZ /50;       -- 20ms
   constant delay_after_clear_RES   : integer := CLK_FREQ_HZ /333;      -- 15ms (actually 15.151ms) officially 3ms
   constant delay_after_set_RES_2   : integer := CLK_FREQ_HZ /333;      -- 15ms (actually 15.151ms) officially 3ms
   constant delay_after_set_VCCEN   : integer := CLK_FREQ_HZ /40;       -- 25ms
   constant delay_for_disp_ok       : integer := CLK_FREQ_HZ /10;       -- 100ms

   constant delay_for_line_draw     : integer := CLK_FREQ_HZ /10000;    -- 100µs
   constant delay_for_disp_shift    : integer := CLK_FREQ_HZ /1000;     -- 1ms   (570µs were sufficient on the test OLED, no documentation found on the exact time)
   
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
                       s_ready,           -- system is idle and ready
                       cmd_line,          -- line draw instruction
                       w_line,
                       line_start,        -- start of line
                       w_line_start,
                       line_stop,         -- end of line
                       w_line_stop,
                       line_col_CB,       -- line color
                       w_line_col_CB,
                       line_col_A,        -- line color (continued)
                       w_line_col_A,
                       line_draw,         -- pause to get time to draw the line
                       w_line_draw,
                              -- states ending with _cpy perform the same operation
                              -- but will shift the display when the operation is finished
                       cmd_line_cpy,      -- line draw instruction
                       w_line_cpy,
                       line_start_cpy,    -- start of line
                       w_line_start_cpy,
                       line_stop_cpy,     -- end of line
                       w_line_stop_cpy,
                       line_col_CB_cpy,   -- line color
                       w_line_col_CB_cpy,
                       line_col_A_cpy,    -- line color (continued)
                       w_line_col_A_cpy,
                       line_draw_cpy,     -- pause to get time to draw the line
                       w_line_draw_cpy,
                       cmd_copy,          -- instruction for data copy
                       w_cmd_copy,
                       copy_start,        -- start of source rectangle
                       w_copy_start,
                       copy_end,          -- end of source rectangle
                       w_copy_end,
                       copy_dest,         -- destination
                       w_copy_dest,
                       copy_draw,         -- pause to get time to perform the copy       
                       w_copy_draw,
                       erase_line,        -- line instruction to erase 
                       w_erase_line,
                       erase_start,       -- top of erase line
                       w_erase_start,
                       erase_stop,        -- bottom of erase line
                       w_erase_stop,
                       erase_colCB,       -- sendinf black color
                       w_erase_colCB,
                       erase_colA,        -- end of black color
                       w_erase_colA);
                       
                       
                       
   signal OLED_FSM : t_OLED_FSM;



   --------------------------------------------------------------------------
   -- signals to manage SPI interface
   --------------------------------------------------------------------------
   signal spi_sck       : std_logic;                     -- local copy of the clock
   signal spi_shift_reg : std_logic_vector(15 downto 0); -- the output shift register
   signal spi_rem_bits  : integer range 0 to 15;         -- the number of remaining shifts before next data

   signal spi_send_ack  : boolean;                       -- True when the spi sending is over
   signal spi_active    : boolean;                       -- True when a spi transfer is active


   --------------------------------------------------------------------------
   -- signals related to previous sample
   --------------------------------------------------------------------------

   type t_coord is array(0 to 3) of std_logic_vector(6 downto 0);
   signal prev_sample_coord : t_coord;
   
   type t_sample is array(0 to 3) of std_logic_vector(5 downto 0);
   signal prev_sample_val : t_sample;
   
   signal color_cpy  : integer range 0 to 3;
   signal sample_cpy : std_logic_vector(5 downto 0);

   -- colors
   -- 0 : light blue
   -- 1 : green
   -- 2 : purple
   -- 3 : yellow

begin

   ready <= '1' when OLED_FSM = s_ready else '0';
   PMOD_DC <= '0';


   bufferize_parameters : if PARAM_BUFF generate
      process(clk)
      begin
         if rising_edge(clk) then
            if MAX_ON_TOP then
               sample_cpy <= not sample;
            else
               sample_cpy <= sample;
            end if;
            color_cpy <= to_integer(unsigned(sample_num));            
         end if;
      end process;
   end generate;

   direct_parameters : if not PARAM_BUFF generate
      sample_cpy <= not sample when MAX_ON_TOP else sample;
      color_cpy <= to_integer(unsigned(sample_num));            
   end generate;

   
   -- affecting the outputs...
   process(clk)
   begin
      if rising_edge(clk) then
--         if OLED_FSM = w_disp_ok then
--            PMOD_DC <= '1';
--         elsif OLED_FSM = waking then
--            PMOD_DC <= '0';
--         end if;
         
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
               when waking           =>                          OLED_FSM <= set_EN;
               when set_EN           =>                          OLED_FSM <= w_set_EN;
               when w_set_EN         => if   wait_cnt =  0  then OLED_FSM <= clear_RES;        end if;
               when clear_RES        =>                          OLED_FSM <= w_clear_RES;
               when w_clear_RES      => if   wait_cnt =  0  then OLED_FSM <= set_RES_2;        end if;
               when set_RES_2        =>                          OLED_FSM <= w_set_RES_2;
               when w_set_RES_2      => if   wait_cnt =  0  then OLED_FSM <= send_unlock;      end if;
               when send_unlock      =>                          OLED_FSM <= w_unlock;
               when w_unlock         => if spi_send_ack     then OLED_FSM <= send_disp_off;    end if;
               when send_disp_off    =>                          OLED_FSM <= w_disp_off;
               when w_disp_off       => if spi_send_ack     then OLED_FSM <= send_geom;        end if;
               when send_geom        =>                          OLED_FSM <= w_send_geom;
               when w_send_geom      => if spi_send_ack     then OLED_FSM <= send_master_cfg;  end if;
               when send_master_cfg  =>                          OLED_FSM <= w_master_cfg;
               when w_master_cfg     => if spi_send_ack     then OLED_FSM <= dis_pow_saving;   end if;
               when dis_pow_saving   =>                          OLED_FSM <= w_dis_pow_sav;
               when w_dis_pow_sav    => if spi_send_ack     then OLED_FSM <= set_phase_len;    end if;
               when set_phase_len    =>                          OLED_FSM <= w_phase_len;
               when w_phase_len      => if spi_send_ack     then OLED_FSM <= setup_disp_clk;   end if;
               when setup_disp_clk   =>                          OLED_FSM <= w_set_disp_clk;
               when w_set_disp_clk   => if spi_send_ack     then OLED_FSM <= pre_charge_voltg; end if;
               when pre_charge_voltg =>                          OLED_FSM <= w_pcv;
               when w_pcv            => if spi_send_ack     then OLED_FSM <= set_MastCurrAtt;  end if;
               when set_MastCurrAtt  =>                          OLED_FSM <= w_set_MCA;
               when w_set_MCA        => if spi_send_ack     then OLED_FSM <= set_VCCEN;        end if;
               when set_VCCEN        =>                          OLED_FSM <= w_set_VCCEN;
               when w_set_VCCEN      => if   wait_cnt =  0  then OLED_FSM <= disp_on;          end if;
               when disp_on          =>                          OLED_FSM <= w_disp_on;
               when w_disp_on        => if spi_send_ack     then OLED_FSM <= prep_w_disp_ok;   end if;
               when prep_w_disp_ok   =>                          OLED_FSM <= w_disp_ok;
               when w_disp_ok        => if   wait_cnt =  0  then OLED_FSM <= s_ready;          end if;
               when s_ready          => if sample_en  = '1' then 
                                          if disp_shift='1' then OLED_FSM <= cmd_line_cpy;
                                                            else OLED_FSM <= cmd_line;         end if;
                                     elsif disp_shift = '1' then OLED_FSM <= cmd_copy;         end if;
               when cmd_line         =>                          OLED_FSM <= w_line;
               when w_line           => if spi_send_ack     then OLED_FSM <= line_start;       end if;
               when line_start       =>                          OLED_FSM <= w_line_start;
               when w_line_start     => if spi_send_ack     then OLED_FSM <= line_stop;        end if;
               when line_stop        =>                          OLED_FSM <= w_line_stop;
               when w_line_stop      => if spi_send_ack     then OLED_FSM <= line_col_CB;      end if;
               when line_col_CB      =>                          OLED_FSM <= w_line_col_CB;
               when w_line_col_CB    => if spi_send_ack     then OLED_FSM <= line_col_A;       end if;
               when line_col_A       =>                          OLED_FSM <= w_line_col_A;
               when w_line_col_A     => if spi_send_ack     then OLED_FSM <= line_draw;        end if;
               when line_draw        =>                          OLED_FSM <= w_line_draw;
               when w_line_draw      => if   wait_cnt =  0  then OLED_FSM <= s_ready;          end if;

               when cmd_line_cpy     =>                          OLED_FSM <= w_line_cpy;
               when w_line_cpy       => if spi_send_ack     then OLED_FSM <= line_start_cpy;   end if;
               when line_start_cpy   =>                          OLED_FSM <= w_line_start_cpy;
               when w_line_start_cpy => if spi_send_ack     then OLED_FSM <= line_stop_cpy;    end if;
               when line_stop_cpy    =>                          OLED_FSM <= w_line_stop_cpy;
               when w_line_stop_cpy  => if spi_send_ack     then OLED_FSM <= line_col_CB_cpy;  end if;
               when line_col_CB_cpy  =>                          OLED_FSM <= w_line_col_CB_cpy;
               when w_line_col_CB_cpy=> if spi_send_ack     then OLED_FSM <= line_col_A_cpy;   end if;
               when line_col_A_cpy   =>                          OLED_FSM <= w_line_col_A_cpy;
               when w_line_col_A_cpy => if spi_send_ack     then OLED_FSM <= line_draw_cpy;    end if;
               when line_draw_cpy    =>                          OLED_FSM <= w_line_draw_cpy;
               when w_line_draw_cpy  => if   wait_cnt =  0  then OLED_FSM <= cmd_copy;         end if;
               
               when cmd_copy         =>                          OLED_FSM <= w_cmd_copy;
               when w_cmd_copy       => if spi_send_ack     then OLED_FSM <= copy_start;       end if;
               when copy_start       =>                          OLED_FSM <= w_copy_start;
               when w_copy_start     => if spi_send_ack     then OLED_FSM <= copy_end;         end if;
               when copy_end         =>                          OLED_FSM <= w_copy_end;
               when w_copy_end       => if spi_send_ack     then OLED_FSM <= copy_dest;        end if;
               when copy_dest        =>                          OLED_FSM <= w_copy_dest;
               when w_copy_dest      => if spi_send_ack     then OLED_FSM <= copy_draw;        end if;
               when copy_draw        =>                          OLED_FSM <= w_copy_draw;
               when w_copy_draw      => if   wait_cnt =  0  then OLED_FSM <= erase_line;       end if;
               when erase_line       =>                          OLED_FSM <= w_erase_line;
               when w_erase_line     => if spi_send_ack     then OLED_FSM <= erase_start;      end if;
               when erase_start      =>                          OLED_FSM <= w_erase_start;
               when w_erase_start    => if spi_send_ack     then OLED_FSM <= erase_stop;       end if;
               when erase_stop       =>                          OLED_FSM <= w_erase_stop;
               when w_erase_stop     => if spi_send_ack     then OLED_FSM <= erase_colCB;      end if;
               when erase_colCB      =>                          OLED_FSM <= w_erase_colCB;
               when w_erase_colCB    => if spi_send_ack     then OLED_FSM <= erase_colA;       end if;
               when erase_colA       =>                          OLED_FSM <= w_erase_colA;
               when w_erase_colA     => if spi_send_ack     then OLED_FSM <= line_draw;        end if;
            end case;
         end if;
      end if;
   end process;



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
            when line_draw        |
                 line_draw_cpy    => wait_cnt <= delay_for_line_draw      - 1;
            when copy_draw        => wait_cnt <= delay_for_disp_shift     - 1;
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
               | cmd_line
               | line_start
               | line_stop
               | line_col_CB
               | line_col_A
               | cmd_line_cpy
               | line_start_cpy
               | line_stop_cpy
               | line_col_CB_cpy
               | line_col_A_cpy
               | cmd_copy
               | copy_start
               | copy_end
               | copy_dest
               | erase_line
               | erase_start
               | erase_stop
               | erase_colCB
               | erase_colA
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
            | w_line
            | w_line_start
            | w_line_stop
            | w_line_col_CB
            | w_line_col_A
            | w_line_cpy
            | w_line_start_cpy
            | w_line_stop_cpy
            | w_line_col_CB_cpy
            | w_line_col_A_cpy
            | w_cmd_copy
            | w_copy_start
            | w_copy_end
            | w_copy_dest
            | w_erase_line
            | w_erase_start
            | w_erase_stop
            | w_erase_colCB
            | w_erase_colA
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
               | line_start
               | line_stop
               | line_col_CB
               | line_start_cpy
               | line_stop_cpy
               | line_col_CB_cpy
               | copy_start
               | copy_end
               | copy_dest
               | erase_start
               | erase_stop
               | erase_colCB
                                  => spi_rem_bits <= 15;
            when send_disp_off
               | disp_on
               | cmd_line
               | line_col_A
               | cmd_line_cpy
               | line_col_A_cpy
               | cmd_copy
               | erase_line
               | erase_colA
                                  => spi_rem_bits <= 7;
            when others           => 
               if wait_cnt = 0 and spi_sck = '1' then
                  if spi_rem_bits > 0 then
                     spi_rem_bits <= spi_rem_bits - 1;
                  else
                     spi_rem_bits <= 15;
                  end if;
               end if;
         end case;
      end if;
   end process;

   
   -- remaining bits in the shift reg
   PMOD_MOSI <= spi_shift_reg(15);
   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when send_unlock      => spi_shift_reg <= x"FD12";
            when send_geom        => if LEFT_SIDE then spi_shift_reg <= x"A061";
                                     else              spi_shift_reg <= x"A073"; end if;
            when send_master_cfg  => spi_shift_reg <= x"AD8E";
            when dis_pow_saving   => spi_shift_reg <= x"B00B";
            when set_phase_len    => spi_shift_reg <= x"B131";
            when setup_disp_clk   => spi_shift_reg <= x"B3F0";
            when pre_charge_voltg => spi_shift_reg <= x"BB2A";
            when set_MastCurrAtt  => spi_shift_reg <= x"8706";
            when send_disp_off    => spi_shift_reg <= x"AE00";
            when disp_on          => spi_shift_reg <= x"AF00";
            when cmd_line
               | cmd_line_cpy     => spi_shift_reg <= x"2100";
            when line_start
               | line_start_cpy   => if prev_sample_coord(color_cpy)(6 downto 5) /= "11" then
                                         spi_shift_reg <= '0' & prev_sample_coord(color_cpy) & "00" & prev_sample_val(color_cpy);
                                     else
                                         spi_shift_reg <= x"5F" & "00" & sample_cpy;
                                     end if;
            when line_stop
               | line_stop_cpy    => spi_shift_reg <= x"5F" & "00" & sample_cpy;
            when line_col_CB
               | line_col_CB_cpy  => case color_cpy is 
                                       when 0 =>  spi_shift_reg <= x"003F";
                                       when 1 =>  spi_shift_reg <= x"003F";
                                       when 2 =>  spi_shift_reg <= x"3E00";
                                       when 3 =>  spi_shift_reg <= x"3E3F";
                                     end case;
            when line_col_A
               | line_col_A_cpy   => case color_cpy is 
                                       when 0 =>  spi_shift_reg <= x"3E00";
                                       when 1 =>  spi_shift_reg <= x"0000";
                                       when 2 =>  spi_shift_reg <= x"3E00";
                                       when 3 =>  spi_shift_reg <= x"0000";
                                     end case;
            when cmd_copy         => spi_shift_reg <= x"2300";
            when copy_start       => spi_shift_reg <= x"0100";
            when copy_end         => spi_shift_reg <= x"5F3F";
            when copy_dest        => spi_shift_reg <= x"0000";
            when erase_line       => spi_shift_reg <= x"2100";
            when erase_start      => spi_shift_reg <= x"5F00";
            when erase_stop       => spi_shift_reg <= x"5F3F";
            when erase_colCB      => spi_shift_reg <= "000" & back_grad & "0000" & back_grad & back_grad(3) ;
            when erase_colA       => spi_shift_reg <= "000" & back_grad & "000000000";
            when others           =>
               if wait_cnt = 0 and spi_sck = '1' and spi_active then
                  if spi_rem_bits > 0 then
                     spi_shift_reg(15 downto 1) <= spi_shift_reg(14 downto 0);
                  end if;
               end if;
         end case;
      end if;
   end process;

   
   -- this is to inform OLED_FSM that a SPI transfer is over
   spi_send_ack <= wait_cnt = 0 and spi_sck = '1' and spi_rem_bits = 0;



   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            for i in 0 to 3 loop
               prev_sample_coord(i) <= "1111111";
            end loop;
         elsif OLED_FSM = line_col_A or OLED_FSM = line_col_A_cpy then
            prev_sample_coord(color_cpy) <= "1011111";
            prev_sample_val(color_cpy)   <= sample_cpy;
         elsif OLED_FSM = cmd_copy then
            for i in 0 to 3 loop
               if prev_sample_coord(i)(6 downto 5) /= "11" then
                  prev_sample_coord(i) <= std_logic_vector(unsigned(prev_sample_coord(i)) - 1);
               end if;
            end loop;
         end if;
      end if;
   end process;




end Behavioral;

