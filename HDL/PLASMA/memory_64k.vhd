----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   18:40:23 07/17/2011 
-- Design Name: 
-- Module Name:	   memory_64k - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
--LIBRARY IEEE;
--USE IEEE.STD_LOGIC_1164.ALL;
--USE ieee.std_logic_unsigned.ALL;
--USE ieee.std_logic_arith.ALL;
--USE std.textio.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;


ENTITY memory_64k IS
	PORT (
		clk	    : IN  STD_LOGIC;
	   addr_in   : IN  STD_LOGIC_VECTOR (31 DOWNTO 2);
	   data_in   : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
	   enable    : IN  STD_LOGIC;
	   we_select : IN  STD_LOGIC_VECTOR (3 DOWNTO 0);
	   data_out  : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	   );
END memory_64k;

ARCHITECTURE Behavioral OF memory_64k IS
    CONSTANT ADDRESS_WIDTH : NATURAL := 18;  -- 2**X = NOMBRE D'OCTETS DE LA MEMOIRE
					     -- 14 =>  16ko of memory
					     -- 15 =>  32ko of memory
					     -- 16 =>  64ko of memory
					     -- 17 => 128ko of memory
						  -- 18 => 256ko of memory
    --TYPE   ptorage_array IS ARRAY(NATURAL RANGE 0 TO (2 ** ADDRESS_WIDTH) / 4 - 1) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	 TYPE ptorage_array IS ARRAY(0 TO (2 ** ADDRESS_WIDTH) / 4 - 1) OF bit_vector(7 DOWNTO 0);
	 
	     IMPURE FUNCTION load_memoire (filename : IN string; byte : IN integer) RETURN ptorage_array IS
        FILE ram_file      : text IS IN filename;
        VARIABLE line_name : line;
        VARIABLE line_temp : bit_vector(31 DOWNTO 0);
        VARIABLE ram_name  : ptorage_array;
    BEGIN
        FOR I IN ptorage_array'range LOOP
		      IF (NOT endfile(ram_file)) THEN
              readline(ram_file, line_name);
              
				  read (line_name, line_temp);
              
				  IF(byte = 1) THEN
                  ram_name(I) := (line_temp(31 DOWNTO 24));
              ELSIF(byte = 2) THEN
                  ram_name(I) := (line_temp(23 DOWNTO 16));
              ELSIF(byte = 3) THEN
                  ram_name(I) := (line_temp(15 DOWNTO 8));
              ELSIF(byte = 4) THEN
                  ram_name(I) := (line_temp(7 DOWNTO 0));
              END IF;
	         END IF;
        END LOOP;
        RETURN ram_name;
    END FUNCTION;
	 
	 
    SIGNAL memBank1    : ptorage_array;-- := load_memoire("./pcie_in.txt", 4);
    SIGNAL memBank2    : ptorage_array;-- := load_memoire("./pcie_in.txt", 3);
    SIGNAL memBank3    : ptorage_array;-- := load_memoire("./pcie_in.txt", 2);
    SIGNAL memBank4    : ptorage_array;-- := load_memoire("./pcie_in.txt", 1);
	 
	 attribute RAM_STYLE : string;
	 attribute RAM_STYLE of memBank1: signal is "BLOCK";
	 attribute RAM_STYLE of memBank2: signal is "BLOCK";
	 attribute RAM_STYLE of memBank3: signal is "BLOCK";
	 attribute RAM_STYLE of memBank4: signal is "BLOCK";
	 
BEGIN
    process (CLK)
		VARIABLE index : INTEGER RANGE 0 TO (2**(ADDRESS_WIDTH-2)-1) := 0;
    begin
        if CLK'event and CLK = '1' then
            if enable = '1' then
                index := conv_integer(addr_in(ADDRESS_WIDTH-1 DOWNTO 2));
                if We_select(0) = '1' then
                    memBank1(index) <= to_bitvector(data_in(7 DOWNTO 0));
                end if;
					data_out(7 DOWNTO 0) <= to_stdlogicvector(memBank1(index));
            end if;
        end if;
    end process;
	 
    process (CLK)
		VARIABLE index : INTEGER RANGE 0 TO (2**(ADDRESS_WIDTH-2)-1) := 0;
    begin
        if CLK'event and CLK = '1' then
            if enable = '1' then
                index := conv_integer(addr_in(ADDRESS_WIDTH-1 DOWNTO 2));
                if We_select(1) = '1' then
                    memBank2(index) <= to_bitvector(data_in(15 DOWNTO 8));
                end if;
					data_out(15 DOWNTO 8) <= to_stdlogicvector(memBank2(index));
            end if;
        end if;
    end process;
	 
    process (CLK)
		VARIABLE index : INTEGER RANGE 0 TO (2**(ADDRESS_WIDTH-2)-1) := 0;
    begin
        if CLK'event and CLK = '1' then
            if enable = '1' then
					 index := conv_integer(addr_in(ADDRESS_WIDTH-1 DOWNTO 2));
                if We_select(2) = '1' then
                    memBank3(index) <= to_bitvector(data_in(23 DOWNTO 16));
                end if;
					data_out(23 DOWNTO 16) <= to_stdlogicvector(memBank3(index));
            end if;
        end if;
    end process;
	 
    process (CLK)
		VARIABLE index : INTEGER RANGE 0 TO (2**(ADDRESS_WIDTH-2)-1) := 0;
    begin
        if CLK'event and CLK = '1' then
            if enable = '1' then
					 index := conv_integer(addr_in(ADDRESS_WIDTH-1 DOWNTO 2));
                if We_select(3) = '1' then
                    memBank4(index) <= to_bitvector(data_in(31 DOWNTO 24));
                end if;
					data_out(31 DOWNTO 24) <= to_stdlogicvector(memBank4(index));
            end if;
        end if;
    end process;

END Behavioral;
