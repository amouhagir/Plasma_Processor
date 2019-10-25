---------------------------------------------------------------------
-- TITLE: Controller / Opcode Decoder
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/8/01
-- FILENAME: control.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- NOTE:  MIPS(tm) is a registered trademark of MIPS Technologies.
--    MIPS Technologies does not endorse and is not associated with
--    this project.
-- DESCRIPTION:
--    Controls the CPU by decoding the opcode and generating control 
--    signals to the rest of the CPU.
--    This entity decodes the MIPS(tm) opcode into a 
--    Very-Long-Word-Instruction.  
--    The 32-bit opcode is converted to a 
--       6+6+6+16+4+2+4+3+2+2+3+2+4 = 60 bit VLWI opcode.
--    Based on information found in:
--       "MIPS RISC Architecture" by Gerry Kane and Joe Heinrich
--       and "The Designer's Guide to VHDL" by Peter J. Ashenden
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity control is
   port(opcode       : in  std_logic_vector(31 downto 0);
        intr_signal  : in  std_logic;
        rs_index     : out std_logic_vector(5 downto 0);
        rt_index     : out std_logic_vector(5 downto 0);
        rd_index     : out std_logic_vector(5 downto 0);
        imm_out      : out std_logic_vector(15 downto 0);
        alu_func     : out alu_function_type;
        shift_func   : out shift_function_type;
        mult_func    : out mult_function_type;
        branch_func  : out branch_function_type;

        calu_1_func  : out std_logic_vector(5 downto 0);
        salu_1_func  : out std_logic_vector(5 downto 0);
        a_source_out : out a_source_type;
        b_source_out : out b_source_type;
        c_source_out : out c_source_type;
        pc_source_out: out pc_source_type;
        mem_source_out:out mem_source_type;
        exception_out: out std_logic);
end; --entity control

architecture logic of control is



begin

control_proc: process(opcode, intr_signal) 
   variable op, func       : std_logic_vector(5 downto 0);
   variable rs, rt, rd     : std_logic_vector(5 downto 0);
   variable rtx            : std_logic_vector(4 downto 0);
   variable imm            : std_logic_vector(15 downto 0);
   variable alu_function   : alu_function_type;
   variable shift_function : shift_function_type;
   variable mult_function  : mult_function_type;
   variable a_source       : a_source_type;
   variable b_source       : b_source_type;
   variable c_source       : c_source_type;
   variable pc_source      : pc_source_type;
   variable branch_function: branch_function_type;
   variable mem_source     : mem_source_type;
   variable is_syscall     : std_logic;


   variable func_alu_comb_1: std_logic_vector(5 downto 0);
   variable func_alu_sequ_1: std_logic_vector(5 downto 0);


begin
	alu_function    := ALU_NOTHING;
	shift_function  := SHIFT_NOTHING;
	mult_function   := MULT_NOTHING;
	func_alu_comb_1 := "000000";
	func_alu_sequ_1 := "000000";
	
   a_source        := A_FROM_REG_SOURCE;
   b_source        := B_FROM_REG_TARGET;
   c_source        := C_FROM_NULL;
   pc_source       := FROM_INC4;
   branch_function := BRANCH_EQ;
   mem_source      := MEM_FETCH;
   op              := opcode(31 downto 26);
   rs              := '0' & opcode(25 downto 21);
   rt              := '0' & opcode(20 downto 16);
   rtx             := opcode(20 downto 16);
   rd              := '0' & opcode(15 downto 11);
   func            := opcode(5 downto 0);
   imm             := opcode(15 downto 0);
   is_syscall      := '0';


   case op is
   	when "000000" =>   --SPECIAL
      	case func is

				-- B GIN ENABLE_(SLL)
      		when "000000" =>   --SLL   r[rd] = r[rt] << re;
         		a_source       := A_FROM_IMM10_6;
         		c_source       := C_FROM_SHIFT;
         		shift_function := SHIFT_LEFT_UNSIGNED;
				-- E D ENABLE_(SLL)

				-- BEGIN ENABLE_(SRL)
      		when "000010" =>   --SRL   r[rd] = u[rt] >> re;
         		a_source       := A_FROM_IMM10_6;
         		c_source       := C_FROM_shift;
         		shift_function := SHIFT_RIGHT_UNSIGNED;
				-- END ENABLE_(SRL)

				-- BEGIN ENABLE_(SRA)
      		when "000011" =>   --SRA   r[rd] = r[rt] >> re;
         		a_source       := A_FROM_IMM10_6;
         		c_source       := C_FROM_SHIFT;
         		shift_function := SHIFT_RIGHT_SIGNED;
				-- END ENABLE_(SRA)

				-- BEGIN ENABLE_(SLLV)
      		when "000100" =>   --SLLV  r[rd] = r[rt] << r[rs];
         		c_source       := C_FROM_SHIFT;
         		shift_function := SHIFT_LEFT_UNSIGNED;
				-- END ENABLE_(SLLV)

				-- BEGIN ENABLE_(SRLV)
      		when "000110" =>   --SRLV  r[rd]=u[rt]>>r[rs];
         		c_source       := C_FROM_SHIFT;
        	 		shift_function := SHIFT_RIGHT_UNSIGNED;
				-- END ENABLE_(SRLV)

				-- BEGIN ENABLE_(SRAV)
      		when "000111" =>   --SRAV  r[rd]=r[rt]>>r[rs];
         		c_source       := C_FROM_SHIFT;
         		shift_function := SHIFT_RIGHT_SIGNED;
				-- END ENABLE_(SRAV)

				-- BEGIN ENABLE_(JR)
      		when "001000" =>   --JR    s->pc_next=r[rs];
         		pc_source       := FROM_BRANCH;
         		alu_function    := ALU_ADD;
         		branch_function := BRANCH_YES;
				-- END ENABLE_(JR)

				-- BEGIN ENABLE_(JALR)
      		when "001001" =>   --JALR  r[rd]=s->pc_next; s->pc_next=r[rs];
         		c_source         := C_FROM_PC_PLUS4;
         		pc_source        := FROM_BRANCH;
         		alu_function     := ALU_ADD;
         		branch_function  := BRANCH_YES;
				-- END ENABLE_(JALR)

      		--when "001010" =>   --MOVZ  if(!r[rt]) r[rd]=r[rs]; /*IV*/

      		--when "001011" =>   --MOVN  if(r[rt]) r[rd]=r[rs];  /*IV*/

				-- BEGIN ENABLE_(SYSCALL)
      		when "001100" =>   --SYSCALL
         		is_syscall := '1';
				-- END ENABLE_(SYSCALL)

				-- BEGIN 3NABLE_(BREAK)
      		when "001101" =>   --BREAK s->wakeup=1;
         		is_syscall := '1';
					if ( opcode(16) = '1' ) then 
						--ASSERT false REPORT "ON LANCE UN CRASH VOLONTAIRE (INSTR = CRASH) : SUCCESS" SEVERITY FAILURE;
						ASSERT false REPORT "=> SUCCESS <=" SEVERITY FAILURE;
					else
						--ASSERT false REPORT "ON LANCE UN CRASH VOLONTAIRE (INSTR = CRASH) : FAILURE" SEVERITY FAILURE;
						ASSERT false REPORT "=> FAILURE <=" SEVERITY FAILURE;
					end if;
				-- END 3NABLE_(BREAK)

				-- BEGIN ENABLE_(SYNC)
      		--when "001111" =>   --SYNC  s->wakeup=1;
				-- END ENABLE_(SYNC)

				-- BEGIN ENABLE_(MFHI)
      		when "010000" =>   --MFHI  r[rd]=s->hi;
         		c_source      := C_FROM_MULT;
         		mult_function := MULT_READ_HI;
				-- END ENABLE_(MFHI)

				-- BEGIN ENABLE_(MTHI)
      		when "010001" =>   --MTHI  s->hi=r[rs];
         		mult_function := MULT_WRITE_HI;
				-- END ENABLE_(MTHI)

				-- BEGIN ENABLE_(MFLO)
      		when "010010" =>   --MFLO  r[rd]=s->lo;
         		c_source      := C_FROM_MULT;
         		mult_function := MULT_READ_LO;
				-- END ENABLE_(MFLO)

				-- BEGIN ENABLE_(MTLO)
      		when "010011" =>   --MTLO  s->lo=r[rs];
         		mult_function := MULT_WRITE_LO;
				-- END ENABLE_(MTLO)

				-- BEGIN ENABLE_(MULT)
      		when "011000" =>   --MULT  s->lo=r[rs]*r[rt]; s->hi=0;
         		mult_function := MULT_SIGNED_MULT;
				-- END ENABLE_(MULT)

				-- BEGIN ENABLE_(MULTU)
      		when "011001" =>   --MULTU s->lo=r[rs]*r[rt]; s->hi=0;
         		mult_function := MULT_MULT;
				-- END ENABLE_(MULTU)

				-- BEGIN ENABLE_(DIV)
      		when "011010" =>   --DIV   s->lo=r[rs]/r[rt]; s->hi=r[rs]%r[rt];
         		mult_function := MULT_SIGNED_DIVIDE;
				-- END ENABLE_(DIV)

				-- BEGIN ENABLE_(DIVU)
     	 		when "011011" =>   --DIVU  s->lo=r[rs]/r[rt]; s->hi=r[rs]%r[rt];
         		mult_function := MULT_DIVIDE;
				-- END ENABLE_(DIVU)

				-- BEGIN ENABLE_(ADD)
      		when "100000" =>   --ADD   r[rd]=r[rs]+r[rt];
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_ADD;
				-- END ENABLE_(ADD)

				-- BEGIN ENABLE_(ADDU)
      		when "100001" =>   --ADDU  r[rd]=r[rs]+r[rt];
      		   c_source     := C_FROM_ALU;
      		   alu_function := ALU_ADD;
				-- END ENABLE_(ADDU)

				-- BEGIN ENABLE_(SUB)
      		when "100010" =>   --SUB   r[rd]=r[rs]-r[rt];
      		   c_source     := C_FROM_ALU;
      		   alu_function := ALU_SUBTRACT;
				-- END ENABLE_(SUB)

				-- BEGIN ENABLE_(SUBU)
      		when "100011" =>   --SUBU  r[rd]=r[rs]-r[rt];
      		   c_source     := C_FROM_ALU;
      		   alu_function := ALU_SUBTRACT;
				-- END ENABLE_(SUBU)

				-- BEGIN ENABLE_(AND)
      		when "100100" =>   --AND   r[rd]=r[rs]&r[rt];
      		   c_source     := C_FROM_ALU;
      		   alu_function := ALU_AND;
				-- END ENABLE_(AND)

				-- BEGIN ENABLE_(OR)
      		when "100101" =>   --OR    r[rd]=r[rs]|r[rt];
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_OR;
				-- END ENABLE_(OR)

				-- BEGIN ENABLE_(XOR)
      		when "100110" =>   --XOR   r[rd]=r[rs]^r[rt];
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_XOR;
				-- END ENABLE_(XOR)

				-- BEGIN ENABLE_(NOR)
      		when "100111" =>   --NOR   r[rd]=~(r[rs]|r[rt]);
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_NOR;
				-- END ENABLE_(NOR)

				-- BEGIN ENABLE_(SLT)
      		when "101010" =>   --SLT   r[rd]=r[rs]<r[rt];
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_LESS_THAN_SIGNED;
				-- END ENABLE_(SLT)

				-- BEGIN ENABLE_(SLTU)
      		when "101011" =>   --SLTU  r[rd]=u[rs]<u[rt];
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_LESS_THAN;
				-- END ENABLE_(SLTU)

 				-- BEGIN ENABLE_(DADDU)
	     		when "101101" =>   --DADDU r[rd]=r[rs]+u[rt];
         		c_source     := C_FROM_ALU;
         		alu_function := ALU_ADD;
				-- END ENABLE_(DADDU)

 				-- BEGIN ENABLE_(TGEU)
	      	--when "110001" =>   --TGEU
				-- END ENABLE_(TGEU)

 				-- BEGIN ENABLE_(TLT)
   	   	--when "110010" =>   --TLT
				-- END ENABLE_(TLT)

 				-- BEGIN ENABLE_(TLTU)
   	   	--when "110011" =>   --TLTU
				-- END ENABLE_(TLTU)

 				-- BEGIN ENABLE_(TEQ)
   	   	--when "110100" =>   --TEQ 
				-- END ENABLE_(TEQ)

 				-- BEGIN ENABLE_(TNE)
   	   	--when "110110" =>   --TNE 
				-- END ENABLE_(TNE)

				-- BEGIN ENABLE_(COMB_ALU_1)	
				when "000001" => --X01
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "000101" => --X05
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "001010" => --X0A
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "011110" => --X1E
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "011111" => --X1F
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "101000" => --X28
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "101001" => --X29
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "101100" => --X2C
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "101110" => --X2E
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "101111" => --X2F
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "110000" => --X30
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "110101" => --X35
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "110111" => --X37
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "111000" => --X38
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "111001" => --X39
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "111010" => --X3A
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "111011" => --X3B
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;
					
				when "111100" => --X3C
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;
					
				when "111101" => --X3D
					c_source     	 := C_FROM_ALU;
					func_alu_comb_1 := func;

				when "111110" => --X3E
					c_source     	 := C_FROM_ALU;
					func_alu_sequ_1 := "000001";

				when "111111" =>  --X3F
					c_source     	 := C_FROM_ALU;
					func_alu_sequ_1 := func;
				-- END ENABLE_(COMB_ALU_1)


      
				when others =>
					--ASSERT false REPORT "INSTRUCTION INCONNUE (0)" SEVERITY WARNING;

      	end case;

   	when "000001" =>   --REGIMM
      	rt              := "000000";
      	rd              := "011111";
      	a_source 		 := A_FROM_PC;
      	b_source 		 := B_FROM_IMMX4;
      	alu_function 	 := ALU_ADD;
      	pc_source 		 := FROM_BRANCH;
      	branch_function := BRANCH_GTZ;
      	--if(test) pc=pc+imm*4

      	case rtx is

 				-- BEGIN ENABLE_(BLTZAL)
      		when "10000" =>   --BLTZAL  r[31]=s->pc_next; branch=r[rs]<0;
         		c_source        := C_FROM_PC_PLUS4;
         		branch_function := BRANCH_LTZ;
 				-- END ENABLE_(BLTZAL)

 				-- BEGIN ENABLE_(BLTZ)
      		when "00000" =>   --BLTZ    branch=r[rs]<0;
         		branch_function := BRANCH_LTZ;
 				-- END ENABLE_(BLTZ)

 				-- BEGIN ENABLE_(BGEZAL)
      		when "10001" =>   --BGEZAL  r[31]=s->pc_next; branch=r[rs]>=0;
         		c_source        := C_FROM_PC_PLUS4;
         		branch_function := BRANCH_GEZ;
 				-- END ENABLE_(BGEZAL)

 				-- BEGIN ENABLE_(BGEZ)
      		when "00001" =>   --BGEZ    branch=r[rs]>=0;
         		branch_function := BRANCH_GEZ;
 				-- END ENABLE_(BGEZ)

 				-- BEGIN ENABLE_(BLTZALL)
	      	--when "10010" =>   --BLTZALL r[31]=s->pc_next; lbranch=r[rs]<0;
 				-- END ENABLE_(BLTZALL)

 				-- BEGIN ENABLE_(BLTZL)
	      	--when "00010" =>   --BLTZL   lbranch=r[rs]<0;
 				-- END ENABLE_(BLTZL)

 				-- BEGIN ENABLE_(BGEZALL)
	      	--when "10011" =>   --BGEZALL r[31]=s->pc_next; lbranch=r[rs]>=0;
 				-- END ENABLE_(BGEZALL)

 				-- BEGIN ENABLE_(BGEZL)
	      	--when "00011" =>   --BGEZL   lbranch=r[rs]>=0;	
 				-- END ENABLE_(BGEZL)

				when others =>
					--ASSERT false REPORT "INSTRUCTION INCONNUE (1)" SEVERITY WARNING;
      	end case;

 		-- BEGIN ENABLE_(JAL)
   	when "000011" =>   --JAL    r[31]=s->pc_next; s->pc_next=(s->pc&0xf0000000)|target;
      	c_source  := C_FROM_PC_PLUS4;
      	rd        := "011111";
      	pc_source := FROM_OPCODE25_0;
 		-- END ENABLE_(JAL)

 		-- BEGIN ENABLE_(J)
   	when "000010" =>   --J      s->pc_next=(s->pc&0xf0000000)|target; 
      	pc_source := FROM_OPCODE25_0;
 		-- END ENABLE_(J)

 		-- BEGIN ENABLE_(BEQ)
	   when "000100" =>   --BEQ    branch=r[rs]==r[rt];
   	   a_source        := A_FROM_PC;
   	   b_source        := B_FROM_IMMX4;
   	   alu_function    := ALU_ADD;
   	   pc_source       := FROM_BRANCH;
   	   branch_function := BRANCH_EQ;
 		-- END ENABLE_(BEQ)

 		-- BEGIN ENABLE_(BNE)
   	when "000101" =>   --BNE    branch=r[rs]!=r[rt];
   	   a_source        := A_FROM_PC;
   	   b_source        := B_FROM_IMMX4;
   	   alu_function    := ALU_ADD;
   	   pc_source       := FROM_BRANCH;
   	   branch_function := BRANCH_NE;
 		-- END ENABLE_(BNE)

 		-- BEGIN ENABLE_(BLEZ)
	   when "000110" =>   --BLEZ   branch=r[rs]<=0;
   	   a_source        := A_FROM_PC;
   	   b_source        := b_FROM_IMMX4;
   	   alu_function    := ALU_ADD;
   	   pc_source       := FROM_BRANCH;
   	   branch_function := BRANCH_LEZ;
 		-- END ENABLE_(BLEZ)

 		-- BEGIN ENABLE_(BGTZ)
	   when "000111" =>   --BGTZ   branch=r[rs]>0;
   	   a_source 	    := A_FROM_PC;
   	   b_source 	    := B_FROM_IMMX4;
   	   alu_function    := ALU_ADD;
   	   pc_source       := FROM_BRANCH;
   	   branch_function := BRANCH_GTZ;
 		-- END ENABLE_(BGTZ)

 		-- BEGIN ENABLE_(ADDI)
		when "001000" =>   --ADDI   r[rt]=r[rs]+(short)imm;
		   b_source := B_FROM_SIGNED_IMM;
		   c_source := C_FROM_ALU;
		   rd := rt;
		   alu_function := ALU_ADD;
 		-- END ENABLE_(ADDI)

 		-- BEGIN ENABLE_(ADDIU)
		when "001001" =>   --ADDIU  u[rt]=u[rs]+(short)imm;
		   b_source := B_FROM_SIGNED_IMM;
		   c_source := C_FROM_ALU;
		   rd := rt;
		   alu_function := ALU_ADD;
 		-- END ENABLE_(ADDIU)

 		-- BEGIN ENABLE_(SLTI)
		when "001010" =>   --SLTI   r[rt]=r[rs]<(short)imm;
		   b_source     := B_FROM_SIGNED_IMM;
		   c_source     := C_FROM_ALU;
		   rd           := rt;
		   alu_function := ALU_LESS_THAN_SIGNED;
 		-- END ENABLE_(SLTI)

 		-- BEGIN ENABLE_(SLTIU)
		when "001011" =>   --SLTIU  u[rt]=u[rs]<(unsigned long)(short)imm;
		   b_source     := B_FROM_SIGNED_IMM;
		   c_source     := C_FROM_ALU;
		   rd           := rt;
		   alu_function := ALU_LESS_THAN;
 		-- END ENABLE_(SLTIU)

 		-- BEGIN ENABLE_(ANDI)
		when "001100" =>   --ANDI   r[rt]=r[rs]&imm;
		   b_source     := B_FROM_IMM;
		   c_source     := C_FROM_ALU;
		   rd           := rt;
		   alu_function := ALU_AND;
 		-- END ENABLE_(ANDI)

 		-- BEGIN ENABLE_(ORI)
		when "001101" =>   --ORI    r[rt]=r[rs]|imm;
		   b_source     := B_FROM_IMM;
		   c_source     := C_FROM_ALU;
		   rd           := rt;
		   alu_function := ALU_OR;
 		-- END ENABLE_(ORI)

 		-- BEGIN ENABLE_(XORI)
		when "001110" =>   --XORI   r[rt]=r[rs]^imm;
		   b_source     := B_FROM_IMM;
		   c_source     := C_FROM_ALU;
		   rd           := rt;
		   alu_function := ALU_XOR;
 		-- END ENABLE_(XORI)

 		-- BEGIN ENABLE_(LUI)
		when "001111" =>   --LUI    r[rt]=(imm<<16);
		   c_source := C_FROM_IMM_SHIFT16;
		   rd       := rt;
 		-- END ENABLE_(LUI)

 		-- BEGIN ENABLE_(COP0)
		when "010000" =>   --COP0
		   alu_function := ALU_OR;
		   c_source     := C_FROM_ALU;
		   if opcode(23) = '0' then  --move from CP0
		      rs := '1' & opcode(15 downto 11);
		      rt := "000000";
		      rd := '0' & opcode(20 downto 16);
		   else                      --move to CP0
		      rs := "000000";
		      rd(5) := '1';
		      pc_source       := FROM_BRANCH;   --delay possible interrupt
		      branch_function := BRANCH_NO;
		   end if;
 		-- END ENABLE_(COP0)

 		-- BEGIN ENABLE_(COP1)
		--when "010001" =>   --COP1
 		-- END ENABLE_(COP1)

 		-- BEGIN ENABLE_(COP2)
		--when "010010" =>   --COP2
 		-- END ENABLE_(COP2)

 		-- BEGIN ENABLE_(COP3)
		--when "010011" =>   --COP3
 		-- END ENABLE_(COP3)

 		-- BEGIN ENABLE_(BEQL)
		--when "010100" =>   --BEQL   lbranch=r[rs]==r[rt];
 		-- END ENABLE_(BEQL)

 		-- BEGIN ENABLE_(BNEL)
		--when "010101" =>   --BNEL   lbranch=r[rs]!=r[rt];
 		-- END ENABLE_(BNEL)

 		-- BEGIN ENABLE_(BLEZL)
		--when "010110" =>   --BLEZL  lbranch=r[rs]<=0;
 		-- END ENABLE_(BLEZL)

 		-- BEGIN ENABLE_(BGTZL)
		--when "010111" =>   --BGTZL  lbranch=r[rs]>0;
 		-- END ENABLE_(BGTZL)

 		-- BEGIN ENABLE_(LB)
		when "100000" =>   --LB     r[rt]=*(signed char*)ptr;
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   rd           := rt;
		   c_source     := C_FROM_MEMORY;
		   mem_source   := MEM_READ8S;    --address=(short)imm+r[rs];
 		-- END ENABLE_(LB)

 		-- BEGIN ENABLE_(LH)
		when "100001" =>   --LH     r[rt]=*(signed short*)ptr;
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   rd           := rt;
		   c_source     := C_FROM_MEMORY;
		   mem_source   := MEM_READ16S;   --address=(short)imm+r[rs];
 		-- END ENABLE_(LH)

 		-- BEGIN ENABLE_(LWL)
		when "100010" =>   --LWL    //Not Implemented
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   rd           := rt;
		   c_source     := C_FROM_MEMORY;
		   mem_source   := MEM_READ32;
 		-- END ENABLE_(LWL)

 		-- BEGIN ENABLE_(LW)
		when "100011" =>   --LW     r[rt]=*(long*)ptr;
		   a_source 	 := A_FROM_REG_SOURCE;
		   b_source 	 := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   rd 			 := rt;
		   c_source 	 := C_FROM_MEMORY;
		   mem_source 	 := MEM_READ32;
 		-- END ENABLE_(LW)

 		-- BEGIN ENABLE_(LBU)
		when "100100" =>   --LBU    r[rt]=*(unsigned char*)ptr;
		   a_source 	 := A_FROM_REG_SOURCE;
			b_source 	 := B_FROM_SIGNED_IMM;
			alu_function := ALU_ADD;
			rd 			 := rt;
			c_source 	 := C_FROM_MEMORY;
			mem_source 	 := MEM_READ8;    --address=(short)imm+r[rs];
 		-- END ENABLE_(LBU)

 		-- BEGIN ENABLE_(LHU)
		when "100101" =>   --LHU    r[rt]=*(unsigned short*)ptr;
		   a_source 	 := A_FROM_REG_SOURCE;
		   b_source 	 := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   rd 			 := rt;
		   c_source 	 := C_FROM_MEMORY;
		   mem_source 	 := MEM_READ16;    --address=(short)imm+r[rs];
 		-- END ENABLE_(LHU)

 		-- BEGIN ENABLE_(LWR)
		--when "100110" =>   --LWR    //Not Implemented
 		-- END ENABLE_(LWR)

	 	-- BEGIN ENABLE_(SB)
		when "101000" =>   --SB     *(char*)ptr=(char)r[rt];
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   mem_source   := MEM_WRITE8;   --address=(short)imm+r[rs];
 		-- END ENABLE_(SB)

 		-- BEGIN ENABLE_(SH)
		when "101001" =>   --SH     *(short*)ptr=(short)r[rt];
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   mem_source   := MEM_WRITE16;
 		-- END ENABLE_(SH)

 		-- BEGIN ENABLE_(SWL)
		when "101010" =>   --SWL    //Not Implemented
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   mem_source   := MEM_WRITE32;  --address=(short)imm+r[rs];
 		-- END ENABLE_(SWL)

 		-- BEGIN ENABLE_(SW)
		when "101011" =>   --SW     *(long*)ptr=r[rt];
		   a_source     := A_FROM_REG_SOURCE;
		   b_source     := B_FROM_SIGNED_IMM;
		   alu_function := ALU_ADD;
		   mem_source   := MEM_WRITE32;  --address=(short)imm+r[rs];
 		-- END ENABLE_(SW)

 		-- BEGIN ENABLE_(SWR)
		--when "101110" =>   --SWR    //Not Implemented
 		-- END ENABLE_(SWR)

 		-- BEGIN ENABLE_(CACHE)
		--when "101111" =>   --CACHE
 		-- END ENABLE_(CACHE)

 		-- BEGIN ENABLE_(LL)
		--when "110000" =>   --LL     r[rt]=*(long*)ptr;
 		-- END ENABLE_(LL)

 		-- BEGIN ENABLE_(LWC1)
		--when "110001" =>   --LWC1 
 		-- END ENABLE_(LWC1)

 		-- BEGIN ENABLE_(LWC2)
		--when "110010" =>   --LWC2 
 		-- END ENABLE_(LWC2)

 		-- BEGIN ENABLE_(LWC3)
		--when "110011" =>   --LWC3 
 		-- END ENABLE_(LWC3)

 		-- BEGIN ENABLE_(LDC1)
		--when "110101" =>   --LDC1 
 		-- END ENABLE_(LDC1)

 		-- BEGIN ENABLE_(LDC2)
		--when "110110" =>   --LDC2 
 		-- END ENABLE_(LDC2)

 		-- BEGIN ENABLE_(LDC3)
		--when "110111" =>   --LDC3 
 		-- END ENABLE_(LDC3)

 		-- BEGIN ENABLE_(SC)
		--when "111000" =>   --SC     *(long*)ptr=r[rt]; r[rt]=1;
 		-- END ENABLE_(SC)

 		-- BEGIN ENABLE_(SWC1)
		--when "111001" =>   --SWC1 
 		-- END ENABLE_(SWC1)

 		-- BEGIN ENABLE_(SWC2)
		--when "111010" =>   --SWC2 
 		-- END ENABLE_(SWC2)

 		-- BEGIN ENABLE_(SWC3)
		--when "111011" =>   --SWC3 
 		-- END ENABLE_(SWC3)

 		-- BEGIN ENABLE_(SDC1)
		--when "111101" =>   --SDC1 
 		-- END ENABLE_(SDC1)

 		-- BEGIN ENABLE_(SDC2)
		--when "111110" =>   --SDC2 
 		-- END ENABLE_(SDC2)

 		-- BEGIN ENABLE_(SDC3)
		--when "111111" =>   --SDC3 
 		-- END ENABLE_(SDC3)

	  	when others => 
			--IF op /= "XXXXXX" THEN
			--ASSERT false REPORT "INSTRUCTION INCONNUE (2)" SEVERITY WARNING;
			--END IF;
	   end case;

	   if c_source = C_FROM_NULL then
	      rd := "000000";
	   end if;

		if intr_signal = '1' or is_syscall = '1' then
		   rs              := "111111";  --interrupt vector
		   rt              := "000000";	
		   rd              := "101110";  --save PC in EPC
		   alu_function    := ALU_OR;
		   shift_function  := SHIFT_NOTHING;
		   mult_function   := MULT_NOTHING;
		   branch_function := BRANCH_YES;

			func_alu_comb_1 := "000000";
		   a_source        := A_FROM_REG_SOURCE;
		   b_source        := B_FROM_REG_TARGET;
		   c_source        := C_FROM_PC;
		   pc_source       := FROM_LBRANCH;
		   mem_source      := MEM_FETCH;
		   exception_out   <= '1';
		else
		   exception_out   <= '0';
		end if;

		rs_index       <= rs;
		rt_index       <= rt;
		rd_index       <= rd;
		imm_out        <= imm;
		alu_func       <= alu_function;
		shift_func     <= shift_function;
		mult_func      <= mult_function;
		branch_func    <= branch_function;

		calu_1_func		<= func_alu_comb_1;
		salu_1_func		<= func_alu_sequ_1;
		
		a_source_out   <= a_source;
		b_source_out   <= b_source;
		c_source_out   <= c_source;
		pc_source_out  <= pc_source;
		mem_source_out <= mem_source;
end process;

end; --logic

