---------------------------------------------------------------------
-- TITLE: Plasma CPU core
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/15/01
-- FILENAME: mlite_cpu.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- NOTE:  MIPS(tm) and MIPS I(tm) are registered trademarks of MIPS 
--    Technologies.  MIPS Technologies does not endorse and is not 
--    associated with this project.
-- DESCRIPTION:
--    Top level VHDL document that ties the nine other entities together.
--
-- Executes all MIPS I(tm) opcodes but exceptions and non-aligned
-- memory accesses.  Based on information found in:
--    "MIPS RISC Architecture" by Gerry Kane and Joe Heinrich
--    and "The Designer's Guide to VHDL" by Peter J. Ashenden
--
-- The CPU is implemented as a two or three stage pipeline.
-- An add instruction would take the following steps (see cpu.gif):
-- Stage #0:
--    1.  The "pc_next" entity passes the program counter (PC) to the 
--        "mem_ctrl" entity which fetches the opcode from memory.
-- Stage #1:
--    2.  The memory returns the opcode.
-- Stage #2:
--    3.  "Mem_ctrl" passes the opcode to the "control" entity.
--    4.  "Control" converts the 32-bit opcode to a 60-bit VLWI opcode
--        and sends control signals to the other entities.
--    5.  Based on the rs_index and rt_index control signals, "reg_bank" 
--        sends the 32-bit reg_source and reg_target to "bus_mux".
--    6.  Based on the a_source and b_source control signals, "bus_mux"
--        multiplexes reg_source onto a_bus and reg_target onto b_bus.
-- Stage #3 (part of stage #2 if using two stage pipeline):
--    7.  Based on the alu_func control signals, "alu" adds the values
--        from a_bus and b_bus and places the result on c_bus.
--    8.  Based on the c_source control signals, "bus_bux" multiplexes
--        c_bus onto reg_dest.
--    9.  Based on the rd_index control signal, "reg_bank" saves
--        reg_dest into the correct register.
-- Stage #3b:
--   10.  Read or write memory if needed.
--
-- All signals are active high. 
-- Here are the signals for writing a character to address 0xffff
-- when using a two stage pipeline:
--
-- Program:
-- addr     value  opcode 
-- =============================
--   3c: 00000000  nop
--   40: 34040041  li $a0,0x41
--   44: 3405ffff  li $a1,0xffff
--   48: a0a40000  sb $a0,0($a1)
--   4c: 00000000  nop
--   50: 00000000  nop
--
--      intr_in                             mem_pause 
--  reset_in                               byte_we     Stages
--     ns         address     data_w     data_r        40 44 48 4c 50
--   3600  0  0  00000040   00000000   34040041  0  0   1  
--   3700  0  0  00000044   00000000   3405FFFF  0  0   2  1  
--   3800  0  0  00000048   00000000   A0A40000  0  0      2  1  
--   3900  0  0  0000004C   41414141   00000000  0  0         2  1
--   4000  0  0  0000FFFC   41414141   XXXXXX41  1  0         3  2  
--   4100  0  0  00000050   00000000   00000000  0  0               1
---------------------------------------------------------------------
LIBRARY ieee;
USE work.mlite_pack.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY mlite_cpu IS
    GENERIC(
        memory_type     : string  := "XILINX_16X";  --ALTERA_LPM, or DUAL_PORT_
        mult_type       : string  := "DEFAULT";     --AREA_OPTIMIZED
        shifter_type    : string  := "DEFAULT";     --AREA_OPTIMIZED
        alu_type        : string  := "DEFAULT";     --AREA_OPTIMIZED
        pipeline_stages : natural := 3
        );                                          --2 or 3
    PORT(
        clk      : IN std_logic;
        reset_in : IN std_logic;
        intr_in  : IN std_logic;

        address_next : OUT std_logic_vector(31 DOWNTO 2);  --for synch ram
        byte_we_next : OUT std_logic_vector(3 DOWNTO 0);

        address   : OUT std_logic_vector(31 DOWNTO 2);
        byte_we   : OUT std_logic_vector(3 DOWNTO 0);
        data_w    : OUT std_logic_vector(31 DOWNTO 0);
        data_r    : IN  std_logic_vector(31 DOWNTO 0);
        mem_pause : IN  std_logic
        );
END;  --entity mlite_cpu

ARCHITECTURE logic OF mlite_cpu IS
    --When using a two stage pipeline "sigD <= sig".
    --When using a three stage pipeline "sigD <= sig when rising_edge(clk)",
    --  so sigD is delayed by one clock cycle.
    SIGNAL opcode      : std_logic_vector(31 DOWNTO 0);
    SIGNAL rs_index    : std_logic_vector(5 DOWNTO 0);
    SIGNAL rt_index    : std_logic_vector(5 DOWNTO 0);
    SIGNAL rd_index    : std_logic_vector(5 DOWNTO 0);
    SIGNAL rd_indexD   : std_logic_vector(5 DOWNTO 0);
    SIGNAL reg_source  : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_target  : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_dest    : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_destD   : std_logic_vector(31 DOWNTO 0);
    SIGNAL a_bus       : std_logic_vector(31 DOWNTO 0);
    SIGNAL a_busD      : std_logic_vector(31 DOWNTO 0);
    SIGNAL b_bus       : std_logic_vector(31 DOWNTO 0);
    SIGNAL b_busD      : std_logic_vector(31 DOWNTO 0);
    SIGNAL c_bus       : std_logic_vector(31 DOWNTO 0);
    SIGNAL c_alu       : std_logic_vector(31 DOWNTO 0);
    SIGNAL c_shift     : std_logic_vector(31 DOWNTO 0);
    SIGNAL c_mult      : std_logic_vector(31 DOWNTO 0);
    SIGNAL c_memory    : std_logic_vector(31 DOWNTO 0);
    SIGNAL imm         : std_logic_vector(15 DOWNTO 0);
    SIGNAL pc_future   : std_logic_vector(31 DOWNTO 2);
    SIGNAL pc_current  : std_logic_vector(31 DOWNTO 2);
    SIGNAL pc_plus4    : std_logic_vector(31 DOWNTO 2);
    SIGNAL alu_func    : alu_function_type;
    SIGNAL alu_funcD   : alu_function_type;
    SIGNAL shift_func  : shift_function_type;
    SIGNAL shift_funcD : shift_function_type;
    SIGNAL mult_func   : mult_function_type;
    SIGNAL mult_funcD  : mult_function_type;

    --
    --
    --
    SIGNAL calu_1_func    : std_logic_vector(5 DOWNTO 0);
    SIGNAL calu_1_funcD   : std_logic_vector(5 DOWNTO 0);
    SIGNAL salu_1_func    : std_logic_vector(5 DOWNTO 0);
    SIGNAL salu_1_funcD   : std_logic_vector(5 DOWNTO 0);
    SIGNAL branch_func    : branch_function_type;
    SIGNAL take_branch    : std_logic;
    SIGNAL a_source       : a_source_type;
    SIGNAL b_source       : b_source_type;
    SIGNAL c_source       : c_source_type;
    SIGNAL pc_source      : pc_source_type;
    SIGNAL mem_source     : mem_source_type;
    SIGNAL pause_mult     : std_logic;
    SIGNAL pause_ctrl     : std_logic;
    SIGNAL pause_pipeline : std_logic;
    SIGNAL pause_any      : std_logic;
    SIGNAL pause_non_ctrl : std_logic;
    SIGNAL pause_bank     : std_logic;
    SIGNAL nullify_op     : std_logic;
    SIGNAL intr_enable    : std_logic;
    SIGNAL intr_signal    : std_logic;
    SIGNAL exception_sig  : std_logic;
    SIGNAL reset_reg      : std_logic_vector(3 DOWNTO 0);
    SIGNAL reset          : std_logic;

    --
    -- SIGNAUX NECESSAIRES LA CONNEXION DES ALU D'EXTENSION
    --
    SIGNAL comb_alu_1_func  : std_logic_vector(5 DOWNTO 0);
    SIGNAL comb_alu_1_out   : std_logic_vector(31 DOWNTO 0);
    SIGNAL sequ_alu_1_start : std_logic;
    SIGNAL sequ_alu_1_func  : std_logic_vector(5 DOWNTO 0);
    SIGNAL sequ_alu_1_out   : std_logic_vector(31 DOWNTO 0);
    SIGNAL pause_salu_1     : std_logic;
    
BEGIN  --architecture

    pause_any      <= (mem_pause OR pause_ctrl) OR (pause_mult OR pause_pipeline OR pause_salu_1);
    pause_non_ctrl <= (mem_pause OR pause_mult OR pause_salu_1) OR pause_pipeline;
    pause_bank     <= (mem_pause OR pause_ctrl OR pause_mult OR pause_salu_1) AND NOT pause_pipeline;
    nullify_op     <= '1' WHEN (pc_source = FROM_LBRANCH AND take_branch = '0') OR intr_signal = '1' OR exception_sig = '1' ELSE '0';
    c_bus          <= c_alu OR c_shift OR c_mult OR comb_alu_1_out OR sequ_alu_1_out;
    reset          <= '1' WHEN reset_in = '1' OR reset_reg /= "1111"                                                        ELSE '0';

    -----------------------------------------------------------------------------------
    --
    --
    --synchronize reset and interrupt pins
    intr_proc : PROCESS(clk, reset_in, reset_reg, intr_in, intr_enable,
                        pc_source, pc_current, pause_any)
    BEGIN
        IF reset_in = '1' THEN
            reset_reg   <= "0000";
            intr_signal <= '0';
        ELSIF rising_edge(clk) THEN
            IF reset_reg /= "1111" THEN
                reset_reg <= reset_reg + 1;
            END IF;

            --don't try to interrupt a multi-cycle instruction
            IF pause_any = '0' THEN
                IF intr_in = '1' AND intr_enable = '1' AND
                    pc_source = FROM_INC4 THEN
                    --the epc will contain pc+4
                    intr_signal <= '1';
                ELSE
                    intr_signal <= '0';
                END IF;
            else
				 -- report "PAUSE";
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------------------------------------------------------
    --
    --
    u1_pc_next : pc_next PORT MAP (
        clk         => clk,
        reset_in    => reset,
        take_branch => take_branch,
        pause_in    => pause_any,
        pc_new      => c_bus(31 DOWNTO 2),
        opcode25_0  => opcode(25 DOWNTO 0),
        pc_source   => pc_source,
        pc_future   => pc_future,
        pc_current  => pc_current,
        pc_plus4    => pc_plus4
        );

    -----------------------------------------------------------------------------------
    --
    --
--     INSTANCIATION DU DEBUGGER --
--     synopsys translate_off
--     syn hesis off
--    dis_unit: disassembler PORT MAP (
--              clk,
--              reset_in,
--              pause_any,
--              opcode,
--              pc_current
--    );
--     syn hesis on
--     synopsys translate_on
--     FIN DU DEBUGGER --

    -----------------------------------------------------------------------------------
    --
    --
    u2_mem_ctrl : mem_ctrl
        PORT MAP (
            clk          => clk,
            reset_in     => reset,
            pause_in     => pause_non_ctrl,
            nullify_op   => nullify_op,
            address_pc   => pc_future,
            opcode_out   => opcode,
            address_in   => c_bus,
            mem_source   => mem_source,
            data_write   => reg_target,
            data_read    => c_memory,
            pause_out    => pause_ctrl,
            address_next => address_next,
            byte_we_next => byte_we_next,
            address      => address,
            byte_we      => byte_we,
            data_w       => data_w,
            data_r       => data_r
    );

    -----------------------------------------------------------------------------------
    --
    --
    u3_control : control PORT MAP (
        opcode         => opcode,
        intr_signal    => intr_signal,
        rs_index       => rs_index,
        rt_index       => rt_index,
        rd_index       => rd_index,
        imm_out        => imm,
        alu_func       => alu_func,
        shift_func     => shift_func,
        mult_func      => mult_func,
        branch_func    => branch_func,
        calu_1_func    => calu_1_func,
        salu_1_func    => salu_1_func,
        a_source_out   => a_source,
        b_source_out   => b_source,
        c_source_out   => c_source,
        pc_source_out  => pc_source,
        mem_source_out => mem_source,
        exception_out  => exception_sig);

    -----------------------------------------------------------------------------------
    --
    --
    u4_reg_bank : reg_bank
        GENERIC MAP(memory_type => memory_type)
        PORT MAP (
            clk            => clk,
            reset_in       => reset,
            pause          => pause_bank,
            rs_index       => rs_index,
            rt_index       => rt_index,
            rd_index       => rd_indexD,
            reg_source_out => reg_source,
            reg_target_out => reg_target,
            reg_dest_new   => reg_destD,
            intr_enable    => intr_enable
            );

    -----------------------------------------------------------------------------------
    --
    --    
    u5_bus_mux : bus_mux PORT MAP (
        imm_in       => imm,
        reg_source   => reg_source,
        a_mux        => a_source,
        a_out        => a_bus,
        reg_target   => reg_target,
        b_mux        => b_source,
        b_out        => b_bus,
        c_bus        => c_bus,
        c_memory     => c_memory,
        c_pc         => pc_current,
        c_pc_plus4   => pc_plus4,
        c_mux        => c_source,
        reg_dest_out => reg_dest,
        branch_func  => branch_func,
        take_branch  => take_branch
        );

    -----------------------------------------------------------------------------------
    --
    --    
    u6_alu : alu
        GENERIC MAP (alu_type => alu_type)
        PORT MAP (
            a_in         => a_busD,
            b_in         => b_busD,
            alu_function => alu_funcD,
            c_alu        => c_alu
            );


    -----------------------------------------------------------------------------------
    --
    --
    u61_alu : comb_alu_1
        PORT MAP (
            clk          => clk,
            reset_in     => reset,
            a_in         => a_busD,
            b_in         => b_busD,
            alu_function => calu_1_funcD,
            c_alu        => comb_alu_1_out
            );

    -----------------------------------------------------------------------------------
    --
    --
    u62_alu : sequ_alu_1
        PORT MAP (
            clk          => clk,
            reset_in     => reset,
            a_in         => a_busD,
            b_in         => b_busD,
            alu_function => salu_1_funcD,
            c_alu        => sequ_alu_1_out,
            pause_out    => pause_salu_1
            );

    -----------------------------------------------------------------------------------
    --
    --
    u7_shifter : shifter
        GENERIC MAP (shifter_type => shifter_type)
        PORT MAP (
            value        => b_busD,
            shift_amount => a_busD(4 DOWNTO 0),
            shift_func   => shift_funcD,
            c_shift      => c_shift
            );

    -----------------------------------------------------------------------------------
    --
    --
    u8_mult : mult
        GENERIC MAP (mult_type => mult_type)
        PORT MAP (
            clk       => clk,
            reset_in  => reset,
            a         => a_busD,
            b         => b_busD,
            mult_func => mult_funcD,
            c_mult    => c_mult,
            pause_out => pause_mult
            );

    -----------------------------------------------------------------------------------
    --
    --    
    u9_pipeline : pipeline PORT MAP (
        clk            => clk,
        reset          => reset,
        a_bus          => a_bus,
        a_busD         => a_busD,
        b_bus          => b_bus,
        b_busD         => b_busD,
        alu_func       => alu_func,
        alu_funcD      => alu_funcD,
        shift_func     => shift_func,
        shift_funcD    => shift_funcD,
        mult_func      => mult_func,
        mult_funcD     => mult_funcD,
        calu_1_func    => calu_1_func,
        calu_1_funcD   => calu_1_funcD,
        salu_1_func    => salu_1_func,
        salu_1_funcD   => salu_1_funcD,
        reg_dest       => reg_dest,
        reg_destD      => reg_destD,
        rd_index       => rd_index,
        rd_indexD      => rd_indexD,
        rs_index       => rs_index,
        rt_index       => rt_index,
        pc_source      => pc_source,
        mem_source     => mem_source,
        a_source       => a_source,
        b_source       => b_source,
        c_source       => c_source,
        c_bus          => c_bus,
        pause_any      => pause_any,
        pause_pipeline => pause_pipeline
        );

END;  --architecture logic
