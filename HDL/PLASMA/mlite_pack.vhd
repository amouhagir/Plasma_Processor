---------------------------------------------------------------------
-- TITLE: Plasma Misc. Package
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/15/01
-- FILENAME: mlite_pack.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Data types, constants, and add functions needed for the Plasma CPU.
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE mlite_pack IS

    -----------------------------------------------------------------------------------
    --
    --
    CONSTANT ZERO : std_logic_vector(31 DOWNTO 0) :=
        "00000000000000000000000000000000";
    CONSTANT ONES : std_logic_vector(31 DOWNTO 0) :=
        "11111111111111111111111111111111";
    --make HIGH_Z equal to ZERO if compiler complains
    CONSTANT HIGH_Z : std_logic_vector(31 DOWNTO 0) :=
        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

    -----------------------------------------------------------------------------------
    --
    --
    --subtype alu_function_type is std_logic_vector(3 downto 0);
    --constant ALU_NOTHING          : alu_function_type := "0000";
    --constant ALU_ADD              : alu_function_type := "0001";
    --constant ALU_SUBTRACT         : alu_function_type := "0010";
    --constant ALU_LESS_THAN        : alu_function_type := "0011";
    --constant ALU_LESS_THAN_SIGNED : alu_function_type := "0100";
    --constant ALU_OR               : alu_function_type := "0101";
    --constant ALU_AND              : alu_function_type := "0110";
    --constant ALU_XOR              : alu_function_type := "0111";
    --constant ALU_NOR              : alu_function_type := "1000";

    TYPE alu_function_type IS (
        ALU_NOTHING
        , ALU_ADD
        , ALU_SUBTRACT

        -- BEGIN ENABLE_(SLT,SLTU,SLTI,SLTIU)
        , ALU_LESS_THAN
        , ALU_LESS_THAN_SIGNED
        -- END ENABLE_(SLT,SLTU,SLTI,SLTIU)

        , ALU_OR

        -- BEGIN ENABLE_(AND,ANDI)
        , ALU_AND
        -- END ENABLE_(AND,ANDI)

        -- BEGIN ENABLE_(XOR,XORI)
        , ALU_XOR
        -- END ENABLE_(XOR,XORI)

        -- BEGIN ENABLE_(NOR)
        , ALU_NOR
        -- END ENABLE_(NOR)
        );

    -----------------------------------------------------------------------------------
    --
    --
    --subtype shift_function_type is std_logic_vector(1 downto 0);
    --constant SHIFT_NOTHING        : shift_function_type := "00";
    --constant SHIFT_LEFT_UNSIGNED  : shift_function_type := "01";
    --constant SHIFT_RIGHT_SIGNED   : shift_function_type := "11";
    --constant SHIFT_RIGHT_UNSIGNED : shift_function_type := "10";
    TYPE shift_function_type IS (
        SHIFT_NOTHING
        -- IMPOSSIBLE A SUPPRIMER A CAUSE DE L'INSTRUCTION (NOP)
        , SHIFT_LEFT_UNSIGNED
        -- FIN DE NOP

        -- BEGIN ENABLE_(SRA,SRAV)
        , SHIFT_RIGHT_SIGNED
        -- END ENABLE_(SRA,SRAV)

        -- BEGIN ENABLE_(SRL,SRLV)
        , SHIFT_RIGHT_UNSIGNED
        -- END ENABLE_(SRL,SRLV)
        );


    -----------------------------------------------------------------------------------
    --
    --
--   subtype mult_function_type is std_logic_vector(3 downto 0);
--   constant MULT_NOTHING       : mult_function_type := "0000";
--   constant MULT_READ_LO       : mult_function_type := "0001";
--   constant MULT_READ_HI       : mult_function_type := "0010";
--   constant MULT_WRITE_LO      : mult_function_type := "0011";
--   constant MULT_WRITE_HI      : mult_function_type := "0100";
--   constant MULT_MULT          : mult_function_type := "0101";
--   constant MULT_SIGNED_MULT   : mult_function_type := "0110";
--   constant MULT_DIVIDE        : mult_function_type := "0111";
--   constant MULT_SIGNED_DIVIDE : mult_function_type := "1000";

    TYPE mult_function_type IS (MULT_NOTHING
                                -- BEGIN ENABLE_(MFLO)
                                , MULT_READ_LO
                                -- END ENABLE_(MFLO)

                                -- BEGIN ENABLE_(MFHI)
                                , MULT_READ_HI
                                -- END ENABLE_(MFHI)

                                -- BEGIN ENABLE_(MTLO)
                                , MULT_WRITE_LO
                                -- END ENABLE_(MTLO)

                                -- BEGIN ENABLE_(MTHI)
                                , MULT_WRITE_HI
                                -- END ENABLE_(MTHI)

                                -- BEGIN ENABLE_(MULTU)
                                , MULT_MULT
                                -- END ENABLE_(MULTU)

                                -- BEGIN ENABLE_(MULT)
                                , MULT_SIGNED_MULT
                                -- END ENABLE_(MULT)

                                -- BEGIN ENABLE_(DIVU)
                                , MULT_DIVIDE
                                -- END ENABLE_(DIVU)

                                -- BEGIN ENABLE_(DIV)
                                , MULT_SIGNED_DIVIDE
                                -- END ENABLE_(DIV)
                                );


    -----------------------------------------------------------------------------------
    --
    --
    SUBTYPE  a_source_type IS std_logic_vector(1 DOWNTO 0);
    CONSTANT A_FROM_REG_SOURCE : a_source_type := "00";
    CONSTANT A_FROM_IMM10_6    : a_source_type := "01";
    CONSTANT A_FROM_PC         : a_source_type := "10";

    -----------------------------------------------------------------------------------
    --
    --
    SUBTYPE  b_source_type IS std_logic_vector(1 DOWNTO 0);
    CONSTANT B_FROM_REG_TARGET : b_source_type := "00";
    CONSTANT B_FROM_IMM        : b_source_type := "01";
    CONSTANT B_FROM_SIGNED_IMM : b_source_type := "10";
    CONSTANT B_FROM_IMMX4      : b_source_type := "11";

    -----------------------------------------------------------------------------------
    --
    --
    SUBTYPE  c_source_type IS std_logic_vector(2 DOWNTO 0);
    CONSTANT C_FROM_NULL        : c_source_type := "000";
    CONSTANT C_FROM_ALU         : c_source_type := "001";
    CONSTANT C_FROM_SHIFT       : c_source_type := "001";  --same as alu
    CONSTANT C_FROM_MULT        : c_source_type := "001";  --same as alu
    CONSTANT C_FROM_MEMORY      : c_source_type := "010";
    CONSTANT C_FROM_PC          : c_source_type := "011";
    CONSTANT C_FROM_PC_PLUS4    : c_source_type := "100";
    CONSTANT C_FROM_IMM_SHIFT16 : c_source_type := "101";
    CONSTANT C_FROM_REG_SOURCEN : c_source_type := "110";
    CONSTANT C_FROM_EXTENSIONS  : c_source_type := "111";

    -----------------------------------------------------------------------------------
    --
    --
    SUBTYPE  pc_source_type IS std_logic_vector(1 DOWNTO 0);
    CONSTANT FROM_INC4       : pc_source_type := "00";
    CONSTANT FROM_OPCODE25_0 : pc_source_type := "01";
    CONSTANT FROM_BRANCH     : pc_source_type := "10";
    CONSTANT FROM_LBRANCH    : pc_source_type := "11";

    -----------------------------------------------------------------------------------
    --
    --
--   subtype branch_function_type is std_logic_vector(2 downto 0);
--   constant BRANCH_LTZ : branch_function_type := "000";
--   constant BRANCH_LEZ : branch_function_type := "001";
--   constant BRANCH_EQ  : branch_function_type := "010";
--   constant BRANCH_NE  : branch_function_type := "011";
--   constant BRANCH_GEZ : branch_function_type := "100";
--   constant BRANCH_GTZ : branch_function_type := "101";
--   constant BRANCH_YES : branch_function_type := "110";
--   constant BRANCH_NO  : branch_function_type := "111";

    TYPE branch_function_type IS (
        BRANCH_EQ

        -- BEGIN ENABLE_(BLTZ,BLTZAL)
        , BRANCH_LTZ
        -- END ENABLE_(BLTZ,BLTZAL)

        -- BEGIN ENABLE_(BLEZ)             
        , BRANCH_LEZ
        -- END ENABLE_(BLEZ)               

-- ON DEPLACE                   ,BRANCH_EQ

        -- BEGIN ENABLE_(BNE)
        , BRANCH_NE
        -- END ENABLE_(BNE)

        -- BEGIN ENABLE_(BGEZ,BGEZAL)
        , BRANCH_GEZ
        -- END ENABLE_(BGEZ,BGEZAL)

        -- NE PEUT PAS ETRE ENLEVE FACILEMENT...
        , BRANCH_GTZ

        , BRANCH_YES
        , BRANCH_NO
        );


    -----------------------------------------------------------------------------------
    --
    --
    -- mode(32=1,16=2,8=3), signed, write
--   subtype mem_source_type is std_logic_vector(3 downto 0);
--   constant MEM_FETCH   : mem_source_type := "0000";
--   constant MEM_READ32  : mem_source_type := "0100";
--   constant MEM_WRITE32 : mem_source_type := "0101";
--   constant MEM_READ16  : mem_source_type := "1000";
--   constant MEM_READ16S : mem_source_type := "1010";
--   constant MEM_WRITE16 : mem_source_type := "1001";
--   constant MEM_READ8   : mem_source_type := "1100";
--   constant MEM_READ8S  : mem_source_type := "1110";
--   constant MEM_WRITE8  : mem_source_type := "1101";

    TYPE mem_source_type IS (
        MEM_FETCH
        , MEM_READ32
        , MEM_WRITE32

        -- BEGIN ENABLE_(LHU)
        , MEM_READ16
        -- END ENABLE_(LHU)

        -- BEGIN ENABLE_(LH)
        , MEM_READ16S
        -- END ENABLE_(LH)

        -- BEGIN ENABLE_(SH)
        , MEM_WRITE16
        -- END ENABLE_(SH)

        -- BEGIN ENABLE_(LBU)
        , MEM_READ8
        -- END ENABLE_(LBU)

        -- BEGIN ENABLE_(LB)
        , MEM_READ8S
        -- END ENABLE_(LB)

        -- BEGIN ENABLE_(SB)
        , MEM_WRITE8
        -- END ENABLE_(SB)
        );


    -----------------------------------------------------------------------------------
    --
    --
    FUNCTION bv_adder(a      : IN std_logic_vector;
                      b      : IN std_logic_vector;
                      do_add : IN std_logic) RETURN std_logic_vector;
    FUNCTION bv_negate(a : IN std_logic_vector) RETURN std_logic_vector;
    FUNCTION bv_increment(a : IN std_logic_vector(31 DOWNTO 2)
                          ) RETURN std_logic_vector;
    FUNCTION bv_inc(a : IN std_logic_vector
                    ) RETURN std_logic_vector;

    -- For Altera
    COMPONENT lpm_ram_dp
        GENERIC (
            LPM_WIDTH              : natural;  -- MUST be greater than 0
            LPM_WIDTHAD            : natural;  -- MUST be greater than 0
            LPM_NUMWORDS           : natural := 0;
            LPM_INDATA             : string  := "REGISTERED";
            LPM_OUTDATA            : string  := "REGISTERED";
            LPM_RDADDRESS_CONTROL  : string  := "REGISTERED";
            LPM_WRADDRESS_CONTROL  : string  := "REGISTERED";
            LPM_FILE               : string  := "UNUSED";
            LPM_TYPE               : string  := "LPM_RAM_DP";
            USE_EAB                : string  := "OFF";
            INTENDED_DEVICE_FAMILY : string  := "UNUSED";
            RDEN_USED              : string  := "TRUE";
            LPM_HINT               : string  := "UNUSED");
        PORT (
            RDCLOCK   : IN  std_logic := '0';
            RDCLKEN   : IN  std_logic := '1';
            RDADDRESS : IN  std_logic_vector(LPM_WIDTHAD-1 DOWNTO 0);
            RDEN      : IN  std_logic := '1';
            DATA      : IN  std_logic_vector(LPM_WIDTH-1 DOWNTO 0);
            WRADDRESS : IN  std_logic_vector(LPM_WIDTHAD-1 DOWNTO 0);
            WREN      : IN  std_logic;
            WRCLOCK   : IN  std_logic := '0';
            WRCLKEN   : IN  std_logic := '1';
            Q         : OUT std_logic_vector(LPM_WIDTH-1 DOWNTO 0));
    END COMPONENT;

    -- For Altera
    COMPONENT LPM_RAM_DQ
        GENERIC (
            LPM_WIDTH              : natural;  -- MUST be greater than 0
            LPM_WIDTHAD            : natural;  -- MUST be greater than 0
            LPM_NUMWORDS           : natural := 0;
            LPM_INDATA             : string  := "REGISTERED";
            LPM_ADDRESS_CONTROL    : string  := "REGISTERED";
            LPM_OUTDATA            : string  := "REGISTERED";
            LPM_FILE               : string  := "UNUSED";
            LPM_TYPE               : string  := "LPM_RAM_DQ";
            USE_EAB                : string  := "OFF";
            INTENDED_DEVICE_FAMILY : string  := "UNUSED";
            LPM_HINT               : string  := "UNUSED");
        PORT (
            DATA     : IN  std_logic_vector(LPM_WIDTH-1 DOWNTO 0);
            ADDRESS  : IN  std_logic_vector(LPM_WIDTHAD-1 DOWNTO 0);
            INCLOCK  : IN  std_logic := '0';
            OUTCLOCK : IN  std_logic := '0';
            WE       : IN  std_logic;
            Q        : OUT std_logic_vector(LPM_WIDTH-1 DOWNTO 0));
    END COMPONENT;

    -- For Xilinx
    COMPONENT RAM16X1D
        -- synthesis translate_off 
        GENERIC (INIT : bit_vector := X"16");
        -- synthesis translate_on 
        PORT (DPO   : OUT std_ulogic;
              SPO   : OUT std_ulogic;
              A0    : IN  std_ulogic;
              A1    : IN  std_ulogic;
              A2    : IN  std_ulogic;
              A3    : IN  std_ulogic;
              D     : IN  std_ulogic;
              DPRA0 : IN  std_ulogic;
              DPRA1 : IN  std_ulogic;
              DPRA2 : IN  std_ulogic;
              DPRA3 : IN  std_ulogic;
              WCLK  : IN  std_ulogic;
              WE    : IN  std_ulogic); 
    END COMPONENT;

    -- For Xilinx Virtex-5
    COMPONENT RAM32X1D
        -- synthesis translate_off 
        GENERIC (INIT : bit_vector := X"32");
        -- synthesis translate_on 
        PORT (DPO   : OUT std_ulogic;
              SPO   : OUT std_ulogic;
              A0    : IN  std_ulogic;
              A1    : IN  std_ulogic;
              A2    : IN  std_ulogic;
              A3    : IN  std_ulogic;
              A4    : IN  std_ulogic;
              D     : IN  std_ulogic;
              DPRA0 : IN  std_ulogic;
              DPRA1 : IN  std_ulogic;
              DPRA2 : IN  std_ulogic;
              DPRA3 : IN  std_ulogic;
              DPRA4 : IN  std_ulogic;
              WCLK  : IN  std_ulogic;
              WE    : IN  std_ulogic); 
    END COMPONENT;

    COMPONENT pc_next
        PORT(clk         : IN  std_logic;
             reset_in    : IN  std_logic;
             pc_new      : IN  std_logic_vector(31 DOWNTO 2);
             take_branch : IN  std_logic;
             pause_in    : IN  std_logic;
             opcode25_0  : IN  std_logic_vector(25 DOWNTO 0);
             pc_source   : IN  pc_source_type;
             pc_future   : OUT std_logic_vector(31 DOWNTO 2);
             pc_current  : OUT std_logic_vector(31 DOWNTO 2);
             pc_plus4    : OUT std_logic_vector(31 DOWNTO 2));
    END COMPONENT;

    COMPONENT mem_ctrl
        PORT(clk        : IN  std_logic;
             reset_in   : IN  std_logic;
             pause_in   : IN  std_logic;
             nullify_op : IN  std_logic;
             address_pc : IN  std_logic_vector(31 DOWNTO 2);
             opcode_out : OUT std_logic_vector(31 DOWNTO 0);

             address_in : IN  std_logic_vector(31 DOWNTO 0);
             mem_source : IN  mem_source_type;
             data_write : IN  std_logic_vector(31 DOWNTO 0);
             data_read  : OUT std_logic_vector(31 DOWNTO 0);
             pause_out  : OUT std_logic;

             address_next : OUT std_logic_vector(31 DOWNTO 2);
             byte_we_next : OUT std_logic_vector(3 DOWNTO 0);

             address : OUT std_logic_vector(31 DOWNTO 2);
             byte_we : OUT std_logic_vector(3 DOWNTO 0);
             data_w  : OUT std_logic_vector(31 DOWNTO 0);
             data_r  : IN  std_logic_vector(31 DOWNTO 0));
    END COMPONENT;

    COMPONENT control
        PORT(opcode         : IN  std_logic_vector(31 DOWNTO 0);
             intr_signal    : IN  std_logic;
             rs_index       : OUT std_logic_vector(5 DOWNTO 0);
             rt_index       : OUT std_logic_vector(5 DOWNTO 0);
             rd_index       : OUT std_logic_vector(5 DOWNTO 0);
             imm_out        : OUT std_logic_vector(15 DOWNTO 0);
             alu_func       : OUT alu_function_type;
             shift_func     : OUT shift_function_type;
             mult_func      : OUT mult_function_type;
             branch_func    : OUT branch_function_type;
             calu_1_func    : OUT std_logic_vector(5 DOWNTO 0);
             salu_1_func    : OUT std_logic_vector(5 DOWNTO 0);
             a_source_out   : OUT a_source_type;
             b_source_out   : OUT b_source_type;
             c_source_out   : OUT c_source_type;
             pc_source_out  : OUT pc_source_type;
             mem_source_out : OUT mem_source_type;
             exception_out  : OUT std_logic);
    END COMPONENT;

    COMPONENT reg_bank
        GENERIC(memory_type : string := "XILINX_16X");
        PORT(clk            : IN  std_logic;
             reset_in       : IN  std_logic;
             pause          : IN  std_logic;
             rs_index       : IN  std_logic_vector(5 DOWNTO 0);
             rt_index       : IN  std_logic_vector(5 DOWNTO 0);
             rd_index       : IN  std_logic_vector(5 DOWNTO 0);
             reg_source_out : OUT std_logic_vector(31 DOWNTO 0);
             reg_target_out : OUT std_logic_vector(31 DOWNTO 0);
             reg_dest_new   : IN  std_logic_vector(31 DOWNTO 0);
             intr_enable    : OUT std_logic);
    END COMPONENT;

    COMPONENT bus_mux
        PORT(imm_in     : IN  std_logic_vector(15 DOWNTO 0);
             reg_source : IN  std_logic_vector(31 DOWNTO 0);
             a_mux      : IN  a_source_type;
             a_out      : OUT std_logic_vector(31 DOWNTO 0);

             reg_target : IN  std_logic_vector(31 DOWNTO 0);
             b_mux      : IN  b_source_type;
             b_out      : OUT std_logic_vector(31 DOWNTO 0);

             c_bus        : IN  std_logic_vector(31 DOWNTO 0);
             c_memory     : IN  std_logic_vector(31 DOWNTO 0);
             c_pc         : IN  std_logic_vector(31 DOWNTO 2);
             c_pc_plus4   : IN  std_logic_vector(31 DOWNTO 2);
             c_mux        : IN  c_source_type;
             reg_dest_out : OUT std_logic_vector(31 DOWNTO 0);

             branch_func : IN  branch_function_type;
             take_branch : OUT std_logic);
    END COMPONENT;

    ---------------------------------------------------------------------------------------
    COMPONENT alu
        GENERIC(
            alu_type : string := "DEFAULT"
            );
        PORT(
            a_in         : IN  std_logic_vector(31 DOWNTO 0);
            b_in         : IN  std_logic_vector(31 DOWNTO 0);
            alu_function : IN  alu_function_type;
            c_alu        : OUT std_logic_vector(31 DOWNTO 0)
            );
    END COMPONENT;
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT shifter
        GENERIC(
            shifter_type : string := "DEFAULT"
            );
        PORT(value        : IN  std_logic_vector(31 DOWNTO 0);
             shift_amount : IN  std_logic_vector(4 DOWNTO 0);
             shift_func   : IN  shift_function_type;
             c_shift      : OUT std_logic_vector(31 DOWNTO 0)
             );
    END COMPONENT;
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT mult
        GENERIC(
            mult_type : string := "DEFAULT"
            );
        PORT(
            clk       : IN  std_logic;
            reset_in  : IN  std_logic;
            a         : IN  std_logic_vector(31 DOWNTO 0);
            b         : IN  std_logic_vector(31 DOWNTO 0);
            mult_func : IN  mult_function_type;
            c_mult    : OUT std_logic_vector(31 DOWNTO 0);
            pause_out : OUT std_logic
            ); 
    END COMPONENT;
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT pipeline
        PORT(
            clk            : IN  std_logic;
            reset          : IN  std_logic;
            a_bus          : IN  std_logic_vector(31 DOWNTO 0);
            a_busD         : OUT std_logic_vector(31 DOWNTO 0);
            b_bus          : IN  std_logic_vector(31 DOWNTO 0);
            b_busD         : OUT std_logic_vector(31 DOWNTO 0);
            alu_func       : IN  alu_function_type;
            alu_funcD      : OUT alu_function_type;
            shift_func     : IN  shift_function_type;
            shift_funcD    : OUT shift_function_type;
            mult_func      : IN  mult_function_type;
            mult_funcD     : OUT mult_function_type;
            calu_1_func    : IN  std_logic_vector(5 DOWNTO 0);
            calu_1_funcD   : OUT std_logic_vector(5 DOWNTO 0);
            salu_1_func    : IN  std_logic_vector(5 DOWNTO 0);
            salu_1_funcD   : OUT std_logic_vector(5 DOWNTO 0);
            reg_dest       : IN  std_logic_vector(31 DOWNTO 0);
            reg_destD      : OUT std_logic_vector(31 DOWNTO 0);
            rd_index       : IN  std_logic_vector(5 DOWNTO 0);
            rd_indexD      : OUT std_logic_vector(5 DOWNTO 0);
            rs_index       : IN  std_logic_vector(5 DOWNTO 0);
            rt_index       : IN  std_logic_vector(5 DOWNTO 0);
            pc_source      : IN  pc_source_type;
            mem_source     : IN  mem_source_type;
            a_source       : IN  a_source_type;
            b_source       : IN  b_source_type;
            c_source       : IN  c_source_type;
            c_bus          : IN  std_logic_vector(31 DOWNTO 0);
            pause_any      : IN  std_logic;
            pause_pipeline : OUT std_logic
            );
    END COMPONENT;
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT mlite_cpu
        GENERIC(
                memory_type     : string  := "XILINX_16X";  --ALTERA_LPM, or DUAL_PORT_
                mult_type       : string  := "DEFAULT";
                shifter_type    : string  := "DEFAULT";
                alu_type        : string  := "DEFAULT";
                pipeline_stages : natural := 2
                );                      --2 or 3
        PORT(
            clk          : IN  std_logic;
            reset_in     : IN  std_logic;
            intr_in      : IN  std_logic;
            address_next : OUT std_logic_vector(31 DOWNTO 2);  --for synch ram
            byte_we_next : OUT std_logic_vector(3 DOWNTO 0);
            address      : OUT std_logic_vector(31 DOWNTO 2);
            byte_we      : OUT std_logic_vector(3 DOWNTO 0);
            data_w       : OUT std_logic_vector(31 DOWNTO 0);
            data_r       : IN  std_logic_vector(31 DOWNTO 0);
            mem_pause    : IN  std_logic
            );
    END COMPONENT;
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT cache
        GENERIC(
            memory_type : string := "DEFAULT"
            );
        PORT(
            clk            : IN  std_logic;
            reset          : IN  std_logic;
            address_next   : IN  std_logic_vector(31 DOWNTO 2);
            byte_we_next   : IN  std_logic_vector(3 DOWNTO 0);
            cpu_address    : IN  std_logic_vector(31 DOWNTO 2);
            mem_busy       : IN  std_logic;
            cache_access   : OUT std_logic;  --access 4KB cache
            cache_checking : OUT std_logic;  --checking if cache hit
            cache_miss     : OUT std_logic
            );                               --cache miss
    END COMPONENT;  --cache
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT ram
        GENERIC(
            memory_type : string := "DEFAULT"
            );
        PORT(
            clk               : IN  std_logic;
            enable            : IN  std_logic;
            write_byte_enable : IN  std_logic_vector(3 DOWNTO 0);
            address           : IN  std_logic_vector(31 DOWNTO 2);
            data_write        : IN  std_logic_vector(31 DOWNTO 0);
            data_read         : OUT std_logic_vector(31 DOWNTO 0)
            );
    END COMPONENT;  --ram
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT uart
        GENERIC(log_file : string := "UNUSED");
        PORT(clk          : IN  std_logic;
             reset        : IN  std_logic;
             enable_read  : IN  std_logic;
             enable_write : IN  std_logic;
             data_in      : IN  std_logic_vector(7 DOWNTO 0);
             data_out     : OUT std_logic_vector(7 DOWNTO 0);
             uart_read    : IN  std_logic;
             uart_write   : OUT std_logic;
             busy_write   : OUT std_logic;
             data_avail   : OUT std_logic
             );
    END COMPONENT;  --uart
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
component buttons_controller
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		buttons_access : in  std_logic;

		btnC : in std_logic;
		btnU : in std_logic;
		btnD : in std_logic;
		btnL : in std_logic;
		btnR : in std_logic;

		buttons_values : out std_logic_vector(31 downto 0);
		buttons_change : out std_logic_vector(31 downto 0)
	);
end component; --buttons_controller
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
component i2c_clock
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		enable         : in  std_logic;
		i2c_scl        : inout std_logic;
		i2c_mid        : out std_logic
	);
end component; --i2c_clock

component i2c_controller
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		i2c_access     : in  std_logic;
		i2c_sda        : inout std_logic;
		i2c_scl        : in std_logic;
		i2c_mid        : in std_logic;
		i2c_clock_enable : out std_logic;

		addr : in std_logic_vector(31 downto 0);
		control_in : in std_logic_vector(31 downto 0);
		control_out : out std_logic_vector(31 downto 0);
		control_update : out std_logic;
		status : out std_logic_vector(31 downto 0);
		data_in : in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0);
		data_update : out std_logic
	);
end component; --i2c_controller
    ---------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------
component mux_7seg
    Port ( cmd : in STD_LOGIC_VECTOR (2 downto 0);
           E0 : in STD_LOGIC_VECTOR (6 downto 0);
           E1 : in STD_LOGIC_VECTOR (6 downto 0);
           E2 : in STD_LOGIC_VECTOR (6 downto 0);
           E3 : in STD_LOGIC_VECTOR (6 downto 0);
           E4 : in STD_LOGIC_VECTOR (6 downto 0);
           E5 : in STD_LOGIC_VECTOR (6 downto 0);
           E6 : in STD_LOGIC_VECTOR (6 downto 0);
           E7 : in STD_LOGIC_VECTOR (6 downto 0);
           S : out STD_LOGIC_VECTOR (6 downto 0)
           );
end component;

component mod_7seg
	Port (
		    clk : in STD_LOGIC;
		    rst : in STD_LOGIC;
		    AN : out STD_LOGIC_VECTOR (7 downto 0);
        cmd_mux_7seg : out STD_LOGIC_VECTOR (2 downto 0));
end component;

component trans_hexto7seg
  Port ( input_mem : in STD_LOGIC_VECTOR (31 downto 0);
    e0 : out STD_LOGIC_VECTOR (6 downto 0);
    e1 : out STD_LOGIC_VECTOR (6 downto 0);
    e2 : out STD_LOGIC_VECTOR (6 downto 0);
    e3 : out STD_LOGIC_VECTOR (6 downto 0);
    e4 : out STD_LOGIC_VECTOR (6 downto 0);
    e5 : out STD_LOGIC_VECTOR (6 downto 0);
    e6 : out STD_LOGIC_VECTOR (6 downto 0);
    e7 : out STD_LOGIC_VECTOR (6 downto 0)
  );
end component;
    ---------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------
    COMPONENT eth_dma
        PORT(clk         : IN  std_logic;  --25 MHz
             reset       : IN  std_logic;
             enable_eth  : IN  std_logic;
             select_eth  : IN  std_logic;
             rec_isr     : OUT std_logic;
             send_isr    : OUT std_logic;
             address     : OUT std_logic_vector(31 DOWNTO 2);  --to DDR
             byte_we     : OUT std_logic_vector(3 DOWNTO 0);
             data_write  : OUT std_logic_vector(31 DOWNTO 0);
             data_read   : IN  std_logic_vector(31 DOWNTO 0);
             pause_in    : IN  std_logic;
             mem_address : IN  std_logic_vector(31 DOWNTO 2);  --from CPU
             mem_byte_we : IN  std_logic_vector(3 DOWNTO 0);
             data_w      : IN  std_logic_vector(31 DOWNTO 0);
             pause_out   : OUT std_logic;
             E_RX_CLK    : IN  std_logic;  --2.5 MHz receive
             E_RX_DV     : IN  std_logic;  --data valid
             E_RXD       : IN  std_logic_vector(3 DOWNTO 0);   --receive nibble
             E_TX_CLK    : IN  std_logic;  --2.5 MHz transmit
             E_TX_EN     : OUT std_logic;  --transmit enable
             E_TXD       : OUT std_logic_vector(3 DOWNTO 0)
             );                         --transmit nibble
    END COMPONENT;  --eth_dma
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT plasma
        GENERIC(
            memory_type : string    := "XILINX_16X";  --"DUAL_PORT_" "ALTERA_LPM";
            log_file    : string    := "UNUSED";
            ethernet    : std_logic := '0';
            eUart       : std_logic := '0';
            eI2C        : std_logic := '0';
            use_cache   : std_logic := '0';
           CLK_FREQ_HZ : integer := 100000000;        -- by default, we run at 100MHz
           BPP         : integer range 1 to 16 := 16; -- bits per pixel
           GREYSCALE   : boolean := False;			-- color or greyscale ? (only for BPP>6)
           MAX_ON_TOP  : boolean := True;
           LEFT_SIDE   : boolean := False
            );
        PORT(
            clk             : IN  std_logic;
            reset           : IN  std_logic;
            uart_write      : OUT std_logic;
            uart_read       : IN  std_logic;
            address         : OUT std_logic_vector(31 DOWNTO 2);
            byte_we         : OUT std_logic_vector(3 DOWNTO 0);
            data_write      : OUT std_logic_vector(31 DOWNTO 0);
            data_read       : IN  std_logic_vector(31 DOWNTO 0);
            mem_pause_in    : IN  std_logic;
            no_ddr_start    : OUT std_logic;
            no_ddr_stop     : OUT std_logic;
            fifo_1_out_data : IN  std_logic_vector (31 DOWNTO 0);
            fifo_1_read_en  : OUT std_logic;
            fifo_1_empty    : IN  std_logic;
            fifo_2_in_data  : OUT std_logic_vector (31 DOWNTO 0);
            fifo_1_write_en : OUT std_logic;
            fifo_2_full     : IN  std_logic;
            fifo_1_full     : IN  std_logic;
            fifo_1_valid    : IN  std_logic;
            fifo_2_empty    : IN  std_logic;
            fifo_2_valid    : IN  std_logic;
            fifo_1_compteur : IN  std_logic_vector (31 DOWNTO 0);
            fifo_2_compteur : IN  std_logic_vector (31 DOWNTO 0);

				VGA_hs       : out std_logic;   -- horisontal vga syncr.
				VGA_vs       : out std_logic;   -- vertical vga syncr.
				VGA_red      : out std_logic_vector(3 downto 0);   -- red output
				VGA_green    : out std_logic_vector(3 downto 0);   -- green output
				VGA_blue     : out std_logic_vector(3 downto 0);   -- blue output

				btnU : in std_logic;
				btnD : in std_logic;
				btnL : in std_logic;
				btnR : in std_logic;

            gpio0_out       : OUT std_logic_vector(31 DOWNTO 0);
            gpioA_in        : IN  std_logic_vector(31 DOWNTO 0)
            );
    END COMPONENT;  --plasma


    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT ddr_ctrl
        PORT(clk      : IN    std_logic;
             clk_2x   : IN    std_logic;
             reset_in : IN    std_logic;
             address  : IN    std_logic_vector(25 DOWNTO 2);
             byte_we  : IN    std_logic_vector(3 DOWNTO 0);
             data_w   : IN    std_logic_vector(31 DOWNTO 0);
             data_r   : OUT   std_logic_vector(31 DOWNTO 0);
             active   : IN    std_logic;
             no_start : IN    std_logic;
             no_stop  : IN    std_logic;
             pause    : OUT   std_logic;
             SD_CK_P  : OUT   std_logic;  --clock_positive
             SD_CK_N  : OUT   std_logic;  --clock_negative
             SD_CKE   : OUT   std_logic;  --clock_enable
             SD_BA    : OUT   std_logic_vector(1 DOWNTO 0);   --bank_address
             SD_A     : OUT   std_logic_vector(12 DOWNTO 0);  --address(row or col)
             SD_CS    : OUT   std_logic;  --chip_select
             SD_RAS   : OUT   std_logic;  --row_address_strobe
             SD_CAS   : OUT   std_logic;  --column_address_strobe
             SD_WE    : OUT   std_logic;  --write_enable
             SD_DQ    : INOUT std_logic_vector(15 DOWNTO 0);  --data
             SD_UDM   : OUT   std_logic;  --upper_byte_enable
             SD_UDQS  : INOUT std_logic;  --upper_data_strobe
             SD_LDM   : OUT   std_logic;  --low_byte_enable
             SD_LDQS  : INOUT std_logic
             );                         --low_data_strobe
    END COMPONENT;  --ddr
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT disassembler
        PORT(
            clk     : IN std_logic;
            reset   : IN std_logic;
            pause   : IN std_logic;
            opcode  : IN std_logic_vector(31 DOWNTO 0);
            pc_addr : IN std_logic_vector(31 DOWNTO 2)
            );
    END COMPONENT;
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT comb_alu_1
        PORT(
            clk          : IN  std_logic;
            reset_in     : IN  std_logic;
            a_in         : IN  std_logic_vector(31 DOWNTO 0);
            b_in         : IN  std_logic_vector(31 DOWNTO 0);
            alu_function : IN  std_logic_vector(5 DOWNTO 0);
            c_alu        : OUT std_logic_vector(31 DOWNTO 0)
            );
    END COMPONENT;  --comb_alu_1
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    COMPONENT sequ_alu_1
        PORT(
            clk          : IN  std_logic;
            reset_in     : IN  std_logic;
            a_in         : IN  std_logic_vector(31 DOWNTO 0);
            b_in         : IN  std_logic_vector(31 DOWNTO 0);
            alu_function : IN  std_logic_vector(5 DOWNTO 0);
            c_alu        : OUT std_logic_vector(31 DOWNTO 0);
            pause_out    : OUT std_logic
            );
    END COMPONENT;  --sequ_alu_1
    ---------------------------------------------------------------------------------------

    
END;  --package mlite_pack


PACKAGE BODY mlite_pack IS

    FUNCTION bv_adder(a      : IN std_logic_vector;
                      b      : IN std_logic_vector;
                      do_add : IN std_logic) RETURN std_logic_vector IS
        VARIABLE carry_in : std_logic;
        VARIABLE bb       : std_logic_vector(a'length-1 DOWNTO 0);
        VARIABLE result   : std_logic_vector(a'length DOWNTO 0);
    BEGIN
        IF do_add = '1' THEN
            bb       := b;
            carry_in := '0';
        ELSE
            bb       := NOT b;
            carry_in := '1';
        END IF;
        FOR index IN 0 TO a'length-1 LOOP
            result(index) := a(index) XOR bb(index) XOR carry_in;
            carry_in      := (carry_in AND (a(index) OR bb(index))) OR
                             (a(index) AND bb(index));
        END LOOP;
        result(a'length) := carry_in XNOR do_add;
        RETURN result;
    END;  --function


    FUNCTION bv_negate(a : IN std_logic_vector) RETURN std_logic_vector IS
        VARIABLE carry_in : std_logic;
        VARIABLE not_a    : std_logic_vector(a'length-1 DOWNTO 0);
        VARIABLE result   : std_logic_vector(a'length-1 DOWNTO 0);
    BEGIN
        not_a    := NOT a;
        carry_in := '1';
        FOR index IN a'reverse_range LOOP
            result(index) := not_a(index) XOR carry_in;
            carry_in      := carry_in AND not_a(index);
        END LOOP;
        RETURN result;
    END;  --function


    FUNCTION bv_increment(a : IN std_logic_vector(31 DOWNTO 2)
                          ) RETURN std_logic_vector IS
        VARIABLE carry_in : std_logic;
        VARIABLE result   : std_logic_vector(31 DOWNTO 2);
    BEGIN
        carry_in := '1';
        FOR index IN 2 TO 31 LOOP
            result(index) := a(index) XOR carry_in;
            carry_in      := a(index) AND carry_in;
        END LOOP;
        RETURN result;
    END;  --function


    FUNCTION bv_inc(a : IN std_logic_vector
                    ) RETURN std_logic_vector IS
        VARIABLE carry_in : std_logic;
        VARIABLE result   : std_logic_vector(a'length-1 DOWNTO 0);
    BEGIN
        carry_in := '1';
        FOR index IN 0 TO a'length-1 LOOP
            result(index) := a(index) XOR carry_in;
            carry_in      := a(index) AND carry_in;
        END LOOP;
        RETURN result;
    END;  --function

END;  --package body


