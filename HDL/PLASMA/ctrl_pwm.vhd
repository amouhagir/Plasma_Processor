----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2019 14:12:36
-- Design Name: 
-- Module Name: ctrl_PWM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.mlite_pack.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ctrl_pwm is
    Generic ( DATA_BITS: integer range 0 to 32 := 8;
           MAX_ADDR: integer := 38423;
           FREQ: integer := 1134 );
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           INPUT_1_valid : in STD_LOGIC;
	   INPUT_ETAT_valid : in std_logic;
           Reading: in STD_LOGIC;
           INPUT_1 : in std_logic_vector(31 downto 0);
           OUTPUT_ampSD : out STD_LOGIC;
           odata : out STD_LOGIC);
end ctrl_pwm;

architecture Behavioral of ctrl_pwm is

--constant max_counter : integer := 38423;
--constant freq : integer := 2267;

signal cnt : INTEGER;
signal CE,Read: std_logic;

SIGNAL   NB_TICKS   : UNSIGNED(DATA_BITS-1 downto 0) := (others=>'0');
SIGNAL   counter    : UNSIGNED(9 downto 0) := (others=>'0');
SIGNAL pwm_val_reg  : STD_LOGIC := '0';


TYPE ram_type IS ARRAY (0 TO MAX_ADDR) OF UNSIGNED (DATA_BITS-1 DOWNTO 0);
signal ram1: ram_type;

signal compteur_addr: INTEGER;
signal max_value: INTEGER;
signal compteur_addr1: INTEGER range 0 to MAX_ADDR;

signal mem: std_logic_vector (7 downto 0);
signal volume: std_logic_vector(3 downto 0):="0000";
signal etat: std_logic_vector(3 downto 0):="1010";

begin


  process (clock, reset)
begin
  if reset = '1' then
      compteur_addr <= 0;
      	
  elsif clock'event and clock = '1' then
    if INPUT_1_valid = '1' then
        ram1(compteur_addr) <= UNSIGNED(INPUT_1(DATA_BITS-1 downto 0));
	     IF compteur_addr < MAX_ADDR then 
	     	compteur_addr <= compteur_addr + 1;
	     END IF;
    elsif INPUT_ETAT_valid ='1' then
	  mem <= INPUT_1(7 downto 0); 	
    end if;
  end if;
end process;


Clock_enable: process (clock,reset)
  begin
     if reset ='1' then
        cnt <= 0;
        CE <= '0';
     elsif rising_edge(clock) then

         if cnt=FREQ then
     
             CE <= '1';
             cnt <= 0;  
         else 
             cnt <= cnt+1;
             CE <= '0';
         end if;
      end if; 
  end process;
 
process (clock,reset)
  begin
  if reset ='1' then 
      Read <= '0';
  elsif rising_edge(clock) then
     if (Reading = '1') then
	Read <= '1';
     else 
	Read <= Read; 
     end if;
  end if;
end process;	

etat <= mem(7 downto 4);
volume <= mem(3 downto 0);

PROCESS(clock,reset)
    BEGIN
        IF (reset ='1') then 
	   compteur_addr1 <= 0;
           --NB_TICKS <= (others => '0');
	ELSIF (rising_edge(clock)) then
	      IF (Read = '1') then
		IF CE = '1' THEN
		    -- NB_TICKS <= ram1(compteur_addr1);
		    IF etat = "1010" THEN
		        compteur_addr1 <= 0;
	    
		    ELSIF etat="1111" THEN
		        IF compteur_addr1 >= MAX_ADDR-1 THEN
		            compteur_addr1 <= 0;
		        ELSE
		            compteur_addr1 <= compteur_addr1 + 1;
		        END IF;
	    
		    ELSIF etat="1011" THEN 
		        IF compteur_addr1 = 0 THEN
		            compteur_addr1 <= MAX_ADDR-1;
		        ELSE
		            compteur_addr1 <= compteur_addr1 - 1;
		        END IF;
		        
		    ELSE
		        compteur_addr1 <= compteur_addr1;
	    
		    END IF;
		
		ELSE
		    -- NB_TICKS <= NB_TICKS;
			compteur_addr1 <= compteur_addr1;
	        END IF;
	     END IF;
	END IF;

    END PROCESS;

volume_manager: PROCESS(reset, clock)
    variable data: UNSIGNED (7 downto 0);
    BEGIN
        IF reset = '1' THEN
            NB_TICKS <= (OTHERS => '0');
        ELSIF (rising_edge(clock)) then
            IF CE = '1' THEN
                data := ram1(compteur_addr1);
                CASE volume IS
                    WHEN "0001"   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO DATA_BITS-2), DATA_BITS);
                    WHEN "0010"   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO DATA_BITS-3), DATA_BITS);
                    WHEN "0011"   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO DATA_BITS-4), DATA_BITS);
                    WHEN "0100"   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO DATA_BITS-5), DATA_BITS);
                    WHEN "0101"   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO DATA_BITS-6), DATA_BITS);
                    WHEN "0110"   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO DATA_BITS-7), DATA_BITS);
                    WHEN others   => NB_TICKS <=  RESIZE( data(DATA_BITS-1  DOWNTO 0), DATA_BITS);
                END CASE;
	    ELSE 
		NB_TICKS <= NB_TICKS;	
            END IF;
       END IF;
    END PROCESS;

    PROCESS(reset, clock)
    BEGIN
	   IF reset = '1' THEN
	       counter     <= TO_UNSIGNED(0, 10);
	   ELSIF (rising_edge(clock)) then
		   IF CE = '1' THEN
		      counter  <= TO_UNSIGNED(0, 10);
		   ELSE
		      counter  <= counter + TO_UNSIGNED(1, 1);
		   END IF;
		END IF;
    END PROCESS;


	--max_value <= TO_INTEGER(NB_TICKS);
	pwm_val_reg <= '1' when (counter <= NB_TICKS) else '0';
	odata <= pwm_val_reg;
	OUTPUT_ampSD       <= '1';


end Behavioral;
