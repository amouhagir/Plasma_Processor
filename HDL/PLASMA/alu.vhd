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
use ieee.std_logic_1164.all;
use work.mlite_pack.all;

entity alu is
   generic(alu_type  : string := "DEFAULT");
   port(a_in         : in  std_logic_vector(31 downto 0);
        b_in         : in  std_logic_vector(31 downto 0);
        alu_function : in  alu_function_type;
        c_alu        : out std_logic_vector(31 downto 0));
end; --alu

architecture logic of alu is
   signal do_add    : std_logic;
   signal sum       : std_logic_vector(32 downto 0);
   signal less_than : std_logic;
begin

   sum       <= bv_adder(a_in, b_in, do_add);
   do_add    <= '1'     when alu_function = ALU_ADD else '0';

	-- BEGIN ENABLE_(SLT,SLTU,SLTI,SLTIU)
   less_than <= sum(32) when (a_in(31) = b_in(31)) or (alu_function = ALU_LESS_THAN) else a_in(31);
	-- END ENABLE_(SLT,SLTU,SLTI,SLTIU)

   GENERIC_ALU: if alu_type = "DEFAULT" generate
					c_alu <= sum(31 downto 0) when alu_function = ALU_ADD or alu_function = ALU_SUBTRACT else

					-- BEGIN ENABLE_(SLT,SLTU,SLTI,SLTIU)
               ZERO(31 downto 1) & less_than when alu_function = ALU_LESS_THAN or alu_function = ALU_LESS_THAN_SIGNED else
					-- END ENABLE_(SLT,SLTU,SLTI,SLTIU)

               a_in or  b_in    when alu_function=ALU_OR  else

		 			-- BEGIN ENABLE_(AND,ANDI)
               a_in and b_in    when alu_function=ALU_AND else
		 			-- END ENABLE_(AND,ANDI)

			 		-- BEGIN ENABLE_(XOR,XORI)
               a_in xor b_in    when alu_function=ALU_XOR else
			 		-- END ENABLE_(XOR,XORI)

					-- BEGIN ENABLE_(NOR)
               a_in nor b_in    when alu_function=ALU_NOR else
					-- END ENABLE_(NOR)

               ZERO;
   end generate;

   AREA_OPTIMIZED_ALU: if alu_type /= "DEFAULT" generate
      c_alu <= sum (31 downto 0)             when alu_function = ALU_ADD       or alu_function = ALU_SUBTRACT         else (others => 'Z');

		-- BEGIN ENABLE_(SLT,SLTU,SLTI,SLTIU)
      c_alu <= ZERO(31 downto 1) & less_than when alu_function = ALU_LESS_THAN or alu_function = ALU_LESS_THAN_SIGNED else (others => 'Z');
		-- END ENABLE_(SLT,SLTU,SLTI,SLTIU)

      c_alu <= a_in or  b_in                 when alu_function = ALU_OR                                               else (others => 'Z');

		-- BEGIN ENABLE_(AND,ANDI)
      c_alu <= a_in and b_in                 when alu_function = ALU_AND                                              else (others => 'Z');
		-- END ENABLE_(AND,ANDI)

		-- BEGIN ENABLE_(XOR,XORI)
      c_alu <= a_in xor b_in                 when alu_function = ALU_XOR                                              else (others => 'Z');
		-- END ENABLE_(XOR,XORI)

		-- BEGIN ENABLE_(NOR)
      c_alu <= a_in nor b_in                 when alu_function = ALU_NOR                                              else (others => 'Z');
		-- END ENABLE_(NOR)

      c_alu <= ZERO                          when alu_function = ALU_NOTHING                                          else (others => 'Z');
   end generate;
    
end; --architecture logic

