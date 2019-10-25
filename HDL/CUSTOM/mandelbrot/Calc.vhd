library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.CONSTANTS.ALL;
use WORK.FUNCTIONS.ALL;

entity Calc is
    Port ( y0 : in STD_LOGIC_VECTOR (XY_RANGE-1 downto 0);
       x0 : in STD_LOGIC_VECTOR (XY_RANGE-1 downto 0);
       yi : in STD_LOGIC_VECTOR (XY_RANGE-1 downto 0);
       xi : in STD_LOGIC_VECTOR (XY_RANGE-1 downto 0);
       yi1 : out STD_LOGIC_VECTOR (XY_RANGE-1 downto 0);
       xi1 : out STD_LOGIC_VECTOR (XY_RANGE-1 downto 0));
end Calc;

architecture Behavioral of Calc is

signal temp : SIGNED (XY_RANGE-1 downto 0);

begin
	temp <= SIGNED(mult(xi,yi,FIXED));
	yi1 <= STD_LOGIC_VECTOR(temp(XY_RANGE-2 downto 0)&'0' + SIGNED(y0));
	xi1 <= STD_LOGIC_VECTOR(SIGNED(mult(xi,xi,FIXED)) - SIGNED(mult(yi,yi,FIXED)) + SIGNED(x0));
end Behavioral;
