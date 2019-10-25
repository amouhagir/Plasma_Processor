---------------------------------------------------------------------
-- TITLE: Ethernet DMA
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 12/27/07
-- FILENAME: eth_dma.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Ethernet DMA (Direct Memory Access) controller.  
--    Reads four bits and writes four bits from/to the Ethernet PHY each 
--    2.5 MHz clock cycle.  Received data is DMAed starting at 0x13ff0000 
--    transmit data is read from 0x13fd0000.
--    To send a packet write bytes/4 to Ethernet send register.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;
use work.conversion.all;

entity dma_engine is port(
   clk         : in std_logic;                      --25 MHz
   reset       : in std_logic;
   start_dma   : in std_logic;                      --enable receive DMA

   --
   --
	--
   address     : out std_logic_vector(31 downto 0); --to DDR
   byte_we     : out std_logic_vector( 3 downto 0); 
   data_write  : out std_logic_vector(31 downto 0);
   data_read   : in  std_logic_vector(31 downto 0);

   --
	--
	--
   mem_address : in  std_logic_vector(31 downto 0);  --from CPU
   mem_byte_we : in  std_logic_vector(3 downto 0);
   data_w      : in  std_logic_vector(31 downto 0);
   pause_out   : out std_logic
);
end; --entity eth_dma

architecture logic of dma_engine is
   signal rec_clk    : std_logic_vector(1 downto 0);  --receive
   signal rec_store  : std_logic_vector(31 downto 0); --to DDR

   signal struc_ptr  : std_logic_vector(31 downto 0);

   SIGNAL dma_type   : std_logic_vector( 7 DOWNTO 0);
   SIGNAL ptr_src    : std_logic_vector(31 downto 0);
   SIGNAL ptr_src_2  : std_logic_vector(31 downto 0);
   SIGNAL ptr_src_3  : std_logic_vector(31 downto 0);
   SIGNAL ptr_dst    : std_logic_vector(31 downto 0);
   SIGNAL nWords     : std_logic_vector(15 downto 0);   

	TYPE STATE_TYPE IS (waiting, nextS, addr_dma_type, read_dma_type, read_ptr_src, read_ptr_src_2, read_ptr_src_3, read_ptr_dst, read_nb_words, select_type, cpy_init_data, cpy_read_data, cpy_write_data, init_write_data, wait_one_cycle);
   SIGNAL dma_state : STATE_TYPE;
   
   CONSTANT INC_1_WORD : UNSIGNED(31 downto 0) := TO_UNSIGNED(4, 32);


begin  --architecture

--   mem_address : in  std_logic_vector(31 downto 2);  --from CPU
--   mem_byte_we : in  std_logic_vector(3 downto 0);
--   data_w      : in  std_logic_vector(31 downto 0);
--   pause_out   : out std_logic

	-- DMA CLEAR (0x00)
	-- DMA COPY  (0x01)
	-- DMA XOR   (0x02)
	-- DMA F     (0x03)
	-- DMA G     (0x04)

    dma : process(reset, clk)
    BEGIN
        IF reset = '1' THEN
				dma_state  <= waiting;
            dma_type   <= ZERO( 7 downto 0);
            ptr_src    <= ZERO;
            ptr_dst    <= ZERO;
            nWords     <= ZERO(15 downto 0); 
	         pause_out  <= '0';
				address    <= ZERO;
				byte_we    <= "0000";
				data_write <= ZERO;
        ELSE
         if CLK'event and CLK = '1' then
               CASE dma_state IS
                    WHEN waiting =>
                        struc_ptr <= data_w(31 DOWNTO 0);
                        IF start_dma = '1' THEN
--								   REPORT "STARTING DMA = " & to_hex_str( data_w );
                        	dma_state <= nextS;
									pause_out <= '1';
	                    ELSE
                        	dma_state <= waiting;
									pause_out <= '0';
	                    END IF;
                    	  address   <= data_w(31 DOWNTO 0); -- ON POSITIONNE L'ADRESSE MEMOIRE

                    WHEN nextS   =>
                        dma_state <= addr_dma_type;
								pause_out <= '1';
                       	
                    WHEN addr_dma_type   =>
--								REPORT "WRITING STRUCTURE ADDRESS";
	                     pause_out <= '1';
                       	struc_ptr <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	--
                    		address   <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	-- ON POSITIONNE L'ADRESSE MEMOIRE
                       	byte_we   <= "0000";			                                       -- DE LA STRUCTURE CONTENANT LA
                       	dma_state <= read_dma_type;		                                 -- REQUETE DMA

                    WHEN read_dma_type =>
--								REPORT "READING DMA TYPE = " & to_hex_str( data_read );
	                     pause_out <= '1';
                        dma_type  <= data_read( 7 DOWNTO 0);	-- ON MEMORISE LE
                       	byte_we   <= "0000";					      -- TYPE DE LA REQUETE +
                       	struc_ptr <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	--
                    		address   <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	-- ON POSITIONNE L'ADRESSE MEMOIRE

								IF data_read(7 DOWNTO 0) = "00000000" THEN
                       		dma_state <= read_ptr_dst;		         -- NEXT STATE
								ELSE
                       		dma_state <= read_ptr_src;		         -- NEXT STATE
								END IF;
				
                    WHEN read_ptr_src =>
--								REPORT "READING SRC POINTER = " & to_hex_str( data_read );
                        ptr_src   <= data_read(31 DOWNTO 0);		--
                       	byte_we   <= "0000";					   -- TYPE DE LA REQUETE +
                       	struc_ptr <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	--
                    		address   <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	-- ON POSITIONNE L'ADRESSE MEMOIRE

								IF data_read(7 DOWNTO 0) = "00000001" THEN
	                       	dma_state <= read_ptr_dst;		      -- NEXT STATE
								ELSE
                       		dma_state <= read_ptr_src_3;		   -- NEXT STATE
								END IF;

                    WHEN read_ptr_src_2 =>
--								REPORT "READING SRC POINTER = " & to_hex_str( data_read );
                        ptr_src_2 <= data_read(31 DOWNTO 0);		--
                       	byte_we   <= "0000";					   -- TYPE DE LA REQUETE +
                       	struc_ptr <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	--
                    		address   <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	-- ON POSITIONNE L'ADRESSE MEMOIRE

								IF data_read(7 DOWNTO 0) = "00000010" THEN
	                       	dma_state <= read_ptr_dst;		      -- NEXT STATE
								ELSE
                       		dma_state <= read_ptr_src_3;		   -- NEXT STATE
								END IF;

                    WHEN read_ptr_src_3 =>
--								REPORT "READING SRC POINTER = " & to_hex_str( data_read );
                        ptr_src_3 <= data_read(31 DOWNTO 0);		--
                       	byte_we   <= "0000";					   -- TYPE DE LA REQUETE +
                       	struc_ptr <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	--
                    		address   <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	-- ON POSITIONNE L'ADRESSE MEMOIRE

                       	dma_state <= read_ptr_dst;		      -- NEXT STATE

                    WHEN read_ptr_dst =>
--								REPORT "READING DST POINTER = " & to_hex_str( data_read );
                        ptr_dst   <= data_read(31 DOWNTO 0);		--
                       	byte_we   <= "0000";					   -- TYPE DE LA REQUETE +
                       	struc_ptr <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	--
                    		address   <= STD_LOGIC_VECTOR( UNSIGNED(struc_ptr) + INC_1_WORD);	-- ON POSITIONNE L'ADRESSE MEMOIRE
                       	dma_state <= read_nb_words;		   -- NEXT STATE

                    WHEN read_nb_words =>
--								REPORT "READING NB WORDS = " & to_hex_str( data_read );
                        nWords    <= data_read(15 DOWNTO 0);	  --
                       	byte_we   <= "0000";					     -- 
                       	dma_state <= select_type;		        -- NEXT STATE

                    WHEN select_type =>
--								REPORT "SELECTING DMA OPERATION";
                    	   IF dma_type = "00000000" THEN
	                       	dma_state <= init_write_data;
                    	   ELSE
	                       	dma_state <= cpy_init_data;
                    	   END IF;


							-----------------------------------------------------------

							-- on demande la donnee 0
                    WHEN cpy_init_data   =>
								REPORT "PROCESSING cpy_init_data from "  & to_hex_str( ptr_src ) & " data_read = " & to_hex_str( data_read );
                      	ptr_src    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_src) + INC_1_WORD);	--
                    		address    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_src) );	-- ON POSITIONNE L'ADRESSE MEMOIRE 
								data_write <= ZERO;
                       	byte_we    <= "0000";					                  -- TYPE DE LA REQUETE +
                       	dma_state <= cpy_read_data;

							-- on demande la donnee 1
                    WHEN cpy_read_data   =>
								REPORT "PROCESSING cpy_read_data from "  & to_hex_str( ptr_src ) & " data_read = " & to_hex_str( data_read );
                      	ptr_src    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_src) + INC_1_WORD);	--
                    		address    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_src) );
								data_write <= data_read;
                       	byte_we    <= "0000";
                       	dma_state <= cpy_write_data;

							-- on ecrit la donnee 0
                    WHEN cpy_write_data  =>
								REPORT "PROCESSING cpy_write_data to "  & to_hex_str( ptr_dst ) & " data_read = " & to_hex_str( data_read );
                      	ptr_dst    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_dst) + INC_1_WORD);	--
                    		address    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_dst) );	-- ON POSITIONNE L'ADRESSE MEMOIRE 
--								data_write <= ZERO;												
                       	byte_we    <= "1111";					                  -- TYPE DE LA REQUETE +

								-- On decompte ...
                        nWords     <= STD_LOGIC_VECTOR( UNSIGNED(nWords) - TO_UNSIGNED(1, 16));
								if( UNSIGNED(nWords) = TO_UNSIGNED(1, 16) ) THEN
	                       	dma_state <= wait_one_cycle;		        -- NEXT STATE
								ELSE
	                       	dma_state <= cpy_read_data;		        -- NEXT STATE
								END IF;


							-----------------------------------------------------------

                    WHEN init_write_data =>
--								REPORT "PROCESSING init_write_data " & to_hex_str( ptr_dst ) & " - " & to_hex_str( nWords );
                      	ptr_dst    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_dst) + INC_1_WORD);	--
                    		address    <= STD_LOGIC_VECTOR( UNSIGNED(ptr_dst) );	-- ON POSITIONNE L'ADRESSE MEMOIRE 
								data_write <= ZERO;
                        nWords     <= STD_LOGIC_VECTOR( UNSIGNED(nWords) - TO_UNSIGNED(1, 16));
                       	byte_we    <= "1111";					                                 -- TYPE DE LA REQUETE +
		                  pause_out  <= '1';
								if( UNSIGNED(nWords) = TO_UNSIGNED(1, 16) ) THEN
	                       	dma_state <= wait_one_cycle;		        -- NEXT STATE
								ELSE
	                       	dma_state <= init_write_data;		        -- NEXT STATE
								END IF;


                    WHEN wait_one_cycle =>                        
--								REPORT "PROCESSING wait_one_cycle";
                       	byte_we    <= "0000";					         -- TYPE DE LA REQUETE +
	                     pause_out  <= '0';
                       	dma_state  <= waiting;		                  -- NEXT STATE

                END CASE;
			END IF;
        END IF;
    END process;
    
end; --architecture logic
