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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.mlite_pack.all;

entity sequ_alu_1 is
  port(
		clk       		: in  std_logic;
		  reset_in  		: in  std_logic;
		a_in         	: in  std_logic_vector(31 downto 0);
		  b_in         	: in  std_logic_vector(31 downto 0);
		  alu_function 	: in  std_logic_vector( 5 downto 0);
		  c_alu        	: out std_logic_vector(31 downto 0);
		  pause_out 		: out std_logic
  );
end; --sequ_alu_1

architecture logic of sequ_alu_1 is

  -------------------------------------------------------------------------
  -- PRAGMA BEGIN DECLARATION
--	COMPONENT PGDC_32b
--		PORT(
--			rst		  : in  STD_LOGIC; 
--			clk		  : in  STD_LOGIC; 
--			start	  : in  STD_LOGIC; 
--			INPUT_1	  : in  STD_LOGIC_VECTOR(31 downto 0); 
--			INPUT_2	  : in  STD_LOGIC_VECTOR(31 downto 0); 
--			working   : out std_logic;
--			OUTPUT_1  : out STD_LOGIC_VECTOR(31 downto 0)
--		);
--	END COMPONENT;
  -- PRAGMA END DECLARATION
  -------------------------------------------------------------------------
	 function chr_one_zero(int: std_logic) return character is
	 variable c: character;
  begin
		  case int is
			 when  '0'   => c := '0';
			 when  '1'   => c := '1';
			 when others => c := '?';
		  end case;
		  return c;
	 end chr_one_zero;

  -- converts std_logic_vector into a string (binary base)
  -- (this also takes care of the fact that the range of
  --  a string is natural while a std_logic_vector may
  --  have an integer range)
  function bin_char(slv: std_logic_vector) return string is
		variable result : string (1 to slv'length);
		variable r      : integer;
		variable bitv   : std_logic;
  begin
	 r := 1;
	 for i in slv'range loop
		  bitv := slv(i);
		  result(r) := chr_one_zero( bitv );
		  r := r + 1;
	 end loop;
	 return result;
  end bin_char;

  -------------------------------------------------------------------------
  -- PRAGMA BEGIN SIGNAL
--	SIGNAL RESULT_1  : STD_LOGIC_VECTOR(31 downto 0);
--	SIGNAL sSTART_1  : STD_LOGIC;
--	SIGNAL  PAUSE_1  : STD_LOGIC;
--	SIGNAL pPAUSE_1  : STD_LOGIC;
  -- PRAGMA END SIGNAL
  -------------------------------------------------------------------------
  signal counter : unsigned(2 downto 0) := (others =>'0');
  signal busy, count_busy, init_count : std_logic := '0';
  signal tmp, tmp1 : std_logic_vector(31 downto 0) := (others =>'0');
  
  type state_type is (s_wait,s_init_counter,s_processing);  --type of state machine.
  signal current_s,next_s: state_type;  --current and next state declaration.

begin

process (clk,reset_in)
begin
if (reset_in='1') then
  current_s <= s_wait;  --default state on reset_in.
elsif (rising_edge(clk)) then
  current_s <= next_s;   --state change.
end if;
end process;

--state machine process.
process (current_s, alu_function(0), count_busy)
begin
  case current_s is
	 when s_wait =>
	 if((count_busy ='0') and (alu_function(0) = '0')) then
		busy <= '0';
		init_count <= '0';
		next_s <= s_wait;
	 else
		busy <= '1';
		init_count <= '1';
		next_s <= s_init_counter;
	 end if;  

	 when s_init_counter =>
	 	busy <= '1';
		init_count <= '0';
		next_s <= s_processing;
	 
	 when s_processing =>
	 if(count_busy ='1') then
		busy <= '1';
		init_count <= '0';
		next_s <= s_processing;
	 else
		busy <= '0';
		init_count <= '0';
		next_s <= s_wait;
	 end if;

  end case;
end process;


  --assert (alu_function(0)/='1') severity error;
  -------------------------------------------------------------------------
  -- synthesis translate_off 
  --PROCESS
  --BEGIN
	 --	WAIT FOR 1 ns;
  --	printmsg("(IMS) COMBINATOIRE EXTENSION (1) : ALLOCATION OK !");
	 --	WAIT;
  --END PROCESS;
  -- synthesis translate_on 
  -------------------------------------------------------------------------

  counting : process(clk, reset_in)
  begin
	 if (reset_in = '1') then
		counter <= (others =>'0');
		count_busy <= '0';
	 elsif clk'event and clk = '1' then
		if(init_count = '1') then
		  counter <= (others =>'0');
		  count_busy <= '1';
		elsif(counter = "010") then
		  counter <= counter;
		  count_busy <= '0';
		else
		  counter <= counter + to_unsigned(1,2);
		  count_busy <= '1';
		end if;
	 end if;
  end process;
  
  --c_alu <= ("00000000000000000000000000000"&std_logic_vector(counter)) when busy = '1' or alu_function(0) = '1' else (others =>'0');
  c_alu <= tmp1 when busy = '1' or alu_function(0) = '1' else (others =>'0');
  pause_out <= busy;
  --busy <= '1' when (counter /= "000") and (counter /= "111") else '0';
  --pause_out <= '1'  WHEN (alu_function(0) = '1') OR (busy= '1') ELSE '0';
  
  mini_pipe : process(clk, reset_in)
  begin 
		if (reset_in = '1') then
		  tmp <= (others =>'0');
		  tmp1 <= (others =>'0');
--		  c_alu <= (others =>'0');
		elsif clk'event and clk = '1' then
		  --if(busy = '1') then
			 tmp <= std_logic_vector(unsigned(a_in) + to_unsigned(3,2));
			 tmp1 <= std_logic_vector(unsigned(tmp) + to_unsigned(1,2));
--			 if(busy = '1') then			 
--				report "tmp: "&bin_char(tmp);
--				report "a_in "&bin_char(a_in);
--			 end if;
--			 c_alu <= tmp1;
		  --end if;
		end if;
  end process;

--  --c_alu <= tmp when alu_function(0) = '1' else (others =>'0');
--  c_alu <= tmp when busy = '1' else (others =>'0');

  
--c_alu <= "00000000000000000000000000000000";
  
		--sSTART_1 <= (not pPAUSE_1) AND alu_function(0);
  
  -------------------------------------------------------------------------
  -- PRAGMA BEGIN INSTANCIATION
--	RESOURCE_1 : PGDC_32b PORT MAP (reset_in, clk, sSTART_1, a_in, b_in, PAUSE_1, RESULT_1);
  -- PRAGMA END INSTANCIATION
  -------------------------------------------------------------------------

--  	REG : process(clk, reset_in)
--  	begin 
--		if (reset_in = '1') then
--			pPAUSE_1   <= '0';
--		elsif clk'event and clk = '1' then
--			pPAUSE_1 <= PAUSE_1;
--		end if;
--	end process;
  

  -------------------------------------------------------------------------
  -- PRAGMA BEGIN RESULT SELECTION
  --c_alu <= 
		  --RESULT_1 WHEN pPAUSE_1 = '1' ELSE
		--"00000000000000000000000000000000";
  -- PRAGMA END RESULT SELECTION
  -------------------------------------------------------------------------    
  
 -- pause_out <= '0'; --PAUSE_1; -- OR (alu_function(0) AND (NOT pPAUSE_1(0)));
  
end; --architecture logic

