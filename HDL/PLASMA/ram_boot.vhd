
-- The libraries ieee.std_logic_unsigned and std.textio will need to be included
-- with this example
-- The following code will infer a Single port Block RAM and initialize it using a FILE

-- Place the following code before the begin of the architecture
---------------------------------------------------------------------
-- TITLE: Random Access Memory for Xilinx
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 11/06/05
-- FILENAME: ram_xilinx.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements Plasma internal RAM as RAMB for Spartan 3x 
--    
--    Compile the MIPS C and assembly code into "test.axf".
--    Run convert.exe to change "test.axf" to "code.txt" which
--    will contain the hex values of the opcodes.
--    Next run "ram_image ram_xilinx.vhd code.txt ram_image.vhd",
--    to create the "ram_image.vhd" file that will have the opcodes
--    correctly placed inside the INIT_00 => strings.
--    Then include ram_image.vhd in the simulation/synthesis.
--
--    Warning:  Addresses 0x1000 - 0x1FFF are reserved for the cache
--    if the DDR cache is enabled.
---------------------------------------------------------------------
-- UPDATED: 09/07/10 Olivier Rinaudo (orinaudo@gmail.com)
-- new behaviour: 8KB expandable to 64KB of internal RAM
--
-- MEMORY MAP
--    0000..1FFF : 8KB   8KB  block0 (upper 4KB used as DDR cache)
--    2000..3FFF : 8KB  16KB  block1 
--    4000..5FFF : 8KB  24KB  block2
--    6000..7FFF : 8KB  32KB  block3
--    8000..9FFF : 8KB  40KB  block4
--    A000..BFFF : 8KB  48KB  block5
--    C000..DFFF : 8KB  56KB  block6
--    E000..FFFF : 8KB  64KB  block7
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY RAM IS
    GENERIC(
        memory_type : string  := "DEFAULT";
        block_count : integer := 03); 
    PORT(
        clk               : IN  std_logic;
        enable            : IN  std_logic;
        write_byte_enable : IN  std_logic_vector(3 DOWNTO 0);
        address           : IN  std_logic_vector(31 DOWNTO 2);
        data_write        : IN  std_logic_vector(31 DOWNTO 0);
        data_read         : OUT std_logic_vector(31 DOWNTO 0)
        );
END;

ARCHITECTURE logic OF RAM IS

	CONSTANT TAILLE_LOADER : INTEGER := 4096;--1024; -- TAILLE EN OCTETS (NORMALEMENT)
   TYPE memoire IS ARRAY(0 TO TAILLE_LOADER-1) OF bit_vector(7 DOWNTO 0);

    IMPURE FUNCTION load_memoire (filename : IN string; byte : IN integer) RETURN memoire IS
        FILE ram_file      : text IS IN filename;
        VARIABLE line_name : line;
        VARIABLE line_temp : bit_vector(31 DOWNTO 0);
        VARIABLE ram_name  : memoire;
    BEGIN
        FOR I IN memoire'range LOOP
		      IF (NOT endfile(ram_file)) THEN
              readline(ram_file, line_name);
              read (line_name, line_temp);
              IF(byte = 1) THEN
                  ram_name(I) := line_temp(31 DOWNTO 24);
              ELSIF(byte = 2) THEN
                  ram_name(I) := line_temp(23 DOWNTO 16);
              ELSIF(byte = 3) THEN
                  ram_name(I) := line_temp(15 DOWNTO 8);
              ELSIF(byte = 4) THEN
                  ram_name(I) := line_temp(7 DOWNTO 0);
              END IF;
	         END IF;
        END LOOP; 
        RETURN ram_name;
    END FUNCTION;

    SIGNAL laRAM1 : memoire := load_memoire("./code_bin.txt", 1);
    SIGNAL laRAM2 : memoire := load_memoire("./code_bin.txt", 2);
    SIGNAL laRAM3 : memoire := load_memoire("./code_bin.txt", 3);
    SIGNAL laRAM4 : memoire := load_memoire("./code_bin.txt", 4);

	--
	-- CETTE MEMOIRE EST MICROSCOPIQUE... PAS LA PEINE D'UTILISER UN BLOC RAM POUR
	-- SON IMPLANTATION...
	--
--	attribute RAM_STYLE : string;
--	attribute RAM_STYLE of laRAM1: signal is "PIPE_DISTRIBUTED";
--	attribute RAM_STYLE of laRAM2: signal is "PIPE_DISTRIBUTED";
--	attribute RAM_STYLE of laRAM3: signal is "PIPE_DISTRIBUTED";
--	attribute RAM_STYLE of laRAM4: signal is "PIPE_DISTRIBUTED";

BEGIN

    --
    -- ON GERE LES BITS (31 => 24)
    --
    PROCESS (clk)
    BEGIN
        IF clk'event AND clk = '1' THEN
            IF enable = '1' THEN
                IF write_byte_enable(3) = '1' THEN
                    laRAM1(conv_integer(address(16 DOWNTO 2))) <= to_bitvector(data_write(31 DOWNTO 24));
                    data_read(31 DOWNTO 24)                    <= data_write(31 DOWNTO 24);
                ELSE
                    data_read(31 DOWNTO 24) <= to_stdlogicvector(laRAM1(conv_integer(address(16 DOWNTO 2))));
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --
    -- ON GERE LES BITS (23 => 16)
    --
    PROCESS (clk)
    BEGIN
        IF clk'event AND clk = '1' THEN
            IF enable = '1' THEN
                IF write_byte_enable(2) = '1' THEN
                    laRAM2(conv_integer(address(16 DOWNTO 2))) <= to_bitvector(data_write(23 DOWNTO 16));
                    data_read(23 DOWNTO 16)                    <= data_write(23 DOWNTO 16);
                ELSE
                    data_read(23 DOWNTO 16) <= to_stdlogicvector(laRAM2(conv_integer(address(16 DOWNTO 2))));
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --
    -- ON GERE LES BITS (15 => 8)
    --
    PROCESS (clk)
    BEGIN
        IF clk'event AND clk = '1' THEN
            IF enable = '1' THEN
                IF write_byte_enable(1) = '1' THEN
                    laRAM3(conv_integer(address(16 DOWNTO 2))) <= to_bitvector(data_write(15 DOWNTO 8));
                    data_read(15 DOWNTO 8)                     <= data_write(15 DOWNTO 8);
                ELSE
                    data_read(15 DOWNTO 8) <= to_stdlogicvector(laRAM3(conv_integer(address(16 DOWNTO 2))));
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --
    -- ON GERE LES BITS (7 => 0)
    --
    PROCESS (clk)
    BEGIN
        IF clk'event AND clk = '1' THEN
            IF enable = '1' THEN
                IF write_byte_enable(0) = '1' THEN
                    laRAM4(conv_integer(address(16 DOWNTO 2))) <= to_bitvector(data_write(7 DOWNTO 0));
                    data_read(7 DOWNTO 0)                      <= data_write(7 DOWNTO 0);
                ELSE
                    data_read(7 DOWNTO 0) <= to_stdlogicvector(laRAM4(conv_integer(address(16 DOWNTO 2))));
                END IF;
            END IF;
        END IF;
    END PROCESS;

END;  --architecture logic
