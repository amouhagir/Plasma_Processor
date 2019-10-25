----------------------------------------------------------------------------------------------------
-- PmodOLEDrgb_terminal
--    Version V1.0.1 (2017/10/31)
--    (c)2017 Y. BORNAT - Bordeaux INP / ENSEIRB-MATMECA
--    This module displays a stream of text as a terminal would do
----------------------------------------------------------------------------------------------------
-- For the last version and a more complete documentation, please visit
-- http://bornat.vvv.enseirb.fr/wiki/doku.php?id=en202:pmodoledrgb
--
-- How to use This module :
---------------------------
--   - To display a new char, user should assert char_write and provide the char on 'char' on the same rising edge of clk.
--     The module manages the update of cursor position and writes the char at the next place. After reading char_write at '1',
--     the module will reset the 'ready' output until the operation is performed. Once 'ready' is set again, the module can accept
--     a new char.
--   - when an operation is performed, the command bit should be reset by user as soon as possible, but the parameters
--     should keep their value unchanged until the ready bit is set again. It is possible to change this behavior setting
--     the PARAM_BUFF generic to True. The module will then require more hardware resources to perform its own copy of the
--     inputs when reading any command bit at '1'.
--   - User can optionnaly provide a foreground and/or a background color for each char. default is white on black.
--     color format is rrrgggbb so 0xE0 mean red, 0x1C means green and 0x03 means blue.
--
--   - optionnal command 'screen_clear' fill the whole screen with the background color. This command require the module to be
--      ready. During the processing time, the 'ready' output will be reset too. This command has priority on char_write
--
-- Dependencies
----------------
--     This module requires the PmodOLEDrgb_charmap module to work properly and was succesfully working with version 1.0
----------------------------------------------------------------------------------
-- known bugs :
--    - None so far
--
-------------------------------------------------------------------------------------------------------
-- History
----------------------------------------------------------------------------------
-- V1.0.1 (2017/10/31) by YB
--    - fixes on typos and mistakes while copy/pasting from other comments
-- V1.0 (2017/08/06) by YB
--    - initial release
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity PmodOLEDrgb_terminal is
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
          screen_clear : in  STD_LOGIC := '0';
          
          PMOD_CS      : out STD_LOGIC;
          PMOD_MOSI    : out STD_LOGIC;
          PMOD_SCK     : out STD_LOGIC;
          PMOD_DC      : out STD_LOGIC;
          PMOD_RES     : out STD_LOGIC;
          PMOD_VCCEN   : out STD_LOGIC;
          PMOD_EN      : out STD_LOGIC);
end PmodOLEDrgb_terminal;

architecture Behavioral of PmodOLEDrgb_terminal is

   type t_fsm is (w_op_ok,   -- wait until operation is finished
                  rdy,       -- ready
                  char_recv, -- a new char has been received
                  disp,      -- display the char
                  w_disp,    -- wait for char to be displayed
                  scroll,    -- start a scroll
                  w_scroll,
                  --tmp,       -- test fsm
                  clear_line, 
                  w_clr_ln); -- wait after clear new line
   signal fsm : t_fsm;


   signal char_cpy    : std_logic_vector(7 downto 0);
   signal foregnd_cpy : std_logic_vector(7 downto 0);
   signal backgnd_cpy : std_logic_vector(7 downto 0);
   

   signal submod_col    : std_logic_vector(3 downto 0);
   signal submod_row    : std_logic_vector(2 downto 0);
   signal submod_clrscr : std_logic;
   signal submod_clrrow : std_logic;
   signal submod_rdy    : std_logic;
   signal submod_scroll : std_logic;
   signal submod_write  : std_logic;

   signal got_0x0A : boolean;
   signal got_0x0D : boolean;
   signal need_scroll : boolean;
   
   signal nl_char     : boolean;           -- async test result, true when we got a newline char
   signal consider_nl : boolean;           -- async test result, should the newline char be considered ?
   
   
   COMPONENT PmodOLEDrgb_charmap
    Generic (CLK_FREQ_HZ : integer;
             PARAM_BUFF  : boolean;
             LEFT_SIDE   : boolean);
    Port (clk          : in  STD_LOGIC;
          reset        : in  STD_LOGIC;
          
          char_write   : in  STD_LOGIC;
          char_col     : in  STD_LOGIC_VECTOR(3 downto 0);
          char_row     : in  STD_LOGIC_VECTOR(2 downto 0);
          char         : in  STD_LOGIC_VECTOR(7 downto 0);
          ready        : out STD_LOGIC;
          foregnd      : in  STD_LOGIC_VECTOR(7 downto 0);
          backgnd      : in  STD_LOGIC_VECTOR(7 downto 0);
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
    END COMPONENT;
   
   
   

begin


   no_buffering : if not PARAM_BUFF generate
      char_cpy    <= char;
      foregnd_cpy <= foregnd;
      backgnd_cpy <= backgnd;
   end generate;

   buffering : if PARAM_BUFF generate
      -- this synchronous process will actually introduce a clock cycle delay when the
      -- inputs of the submodule will be ready for clearing rows or screen. This is
      -- not a specific issue since there is no buffering, so the data will actually
      -- be used a bit later
      process(clk)
      begin
         if rising_edge(clk) then
            if (char_write or screen_clear) = '1' and fsm = rdy then
               char_cpy    <= char;
               foregnd_cpy <= foregnd;
               backgnd_cpy <= backgnd;
            end if;
         end if;
      end process;
   end generate;

   ready         <= '1'          when fsm = rdy else '0';
   submod_clrscr <= screen_clear when fsm = rdy else '0';
   
   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            fsm <= w_op_ok;
         else
            case fsm is
               when w_op_ok   => if submod_rdy   = '1'   then fsm <= rdy;       end if;
               when rdy       => if screen_clear = '1'   then fsm <= w_op_ok;
                              elsif char_write   = '1'   then fsm <= char_recv; end if;
               when char_recv => if nl_char              then
                                    if consider_nl       then fsm <= scroll;
                                                         else fsm <= rdy;       end if;
                              elsif need_scroll          then fsm <= scroll;
                                                         else fsm <= disp;      end if;
               when disp      =>                              fsm <= w_disp;
               when w_disp    => if submod_write = '0' and submod_rdy = '1' then fsm <= rdy; end if;
               when scroll    => if submod_row = "111"   then fsm <= w_scroll;
                              elsif (not nl_char)        then fsm <= disp;
                                                         else fsm <= rdy;       end if;
               when w_scroll  => if submod_scroll = '0' and submod_rdy = '1' then fsm <= clear_line; end if;
               when clear_line => fsm <= w_clr_ln;
               when w_clr_ln  => if submod_rdy = '1'    and (not nl_char)    then fsm <= disp;
                              elsif submod_rdy = '1'                         then fsm <= rdy;      end if;
            end case;
         end if;
      end if;
   end process;



   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' or submod_clrscr = '1' then
            submod_col <= "0000";
         elsif fsm = w_disp and submod_write = '0' and submod_rdy = '1' then
            submod_col <= std_logic_vector(unsigned(submod_col)+1);
         elsif fsm = char_recv and nl_char then
            submod_col <= "0000";
         end if;
      end if;
   end process;


   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' or submod_clrscr = '1' then
            need_scroll <= False;
         elsif fsm = w_disp and submod_write = '0' and submod_rdy = '1' and (not nl_char) and submod_col = "1111" then
            need_scroll <= True;
         elsif fsm = scroll then
            need_scroll <= False;
         end if;
      end if;
   end process;

   
   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' or submod_clrscr = '1' then
            submod_row <= "000";
         elsif fsm = scroll and submod_row /= "111" then
            submod_row <= std_logic_vector(unsigned(submod_row) + 1);
         end if;
      end if;
   end process;

   process(clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            got_0x0A <= False;
            got_0x0D <= False;
         elsif fsm = scroll then
            got_0x0A <= char_cpy = x"0A";
            got_0x0D <= char_cpy = x"0D";
         elsif fsm = char_recv then
            got_0x0A <= False;
            got_0x0D <= False;
         end if;
      end if;
   end process;

   nl_char       <= char_cpy =x"0A" or char_cpy =x"0D";
   consider_nl <= (char_cpy = x"0A" and not got_0x0D) or (char_cpy = x"0D" and not got_0x0A);


   submod_write  <= '1' when fsm = disp else '0';
   submod_scroll <= '1' when fsm = scroll and submod_row = "111" else '0';
   submod_clrrow <= '1' when fsm = w_scroll else '0';
   
   OLED_charmap_mgr : PmodOLEDrgb_charmap
      generic map (CLK_FREQ_HZ => CLK_FREQ_HZ,
                   PARAM_BUFF => False,
                   LEFT_SIDE => LEFT_SIDE)
      port map(clk     => clk,
               reset   => reset,
               
               char_write => submod_write,
               char_col   => submod_col,
               char_row   => submod_row,
               char       => char_cpy,
               ready      => submod_rdy,
               
               scroll_up    => submod_scroll,
               row_clear    => submod_clrrow,
               screen_clear => submod_clrscr,
               
               foregnd      => foregnd_cpy,
               backgnd      => backgnd_cpy,
               
               PMOD_CS    => PMOD_CS,
               PMOD_MOSI  => PMOD_MOSI,
               PMOD_SCK   => PMOD_SCK,
               PMOD_DC    => PMOD_DC,
               PMOD_RES   => PMOD_RES,
               PMOD_VCCEN => PMOD_VCCEN,
               PMOD_EN    => PMOD_EN);



end Behavioral;

