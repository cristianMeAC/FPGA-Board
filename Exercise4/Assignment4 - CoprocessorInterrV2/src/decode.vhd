library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

use work.regfile;


entity decode is
	
	port (
		clk, reset : in  std_logic;
		stall      : in  std_logic;
		flush      : in  std_logic;
		pc_in      : in  std_logic_vector(PC_WIDTH-1 downto 0);
		instr	   : in  std_logic_vector(INSTR_WIDTH-1 downto 0);
		wraddr     : in  std_logic_vector(REG_BITS-1 downto 0);
		wrdata     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		regwrite   : in  std_logic;
		pc_out     : out std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
		exec_op    : out exec_op_type;
		cop0_op    : out cop0_op_type;
		jmp_op     : out jmp_op_type;
		mem_op     : out mem_op_type;
		wb_op      : out wb_op_type;
		exc_dec    : out std_logic;
		cop0_read_reg : out std_logic_vector(REG_BITS-1 downto 0));

end decode;

architecture rtl of decode is

-------------------------------------------------------------------------------
-- (R) <31_opcode_26> <25_rs_21> <20_rt_16> <15_rd_11> <10_shamt_6> <5_func_0> 
-- (I) <31_opcode_26> <25_rs_21> <20_rd_16> <15______address/immediate______0>
-- (J) <31_opcode_26> <25__________________target_address___________________0>
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- ALU ops | R
----------------
-- ALU_NOP   A
-- ALU_LUI   B sll 16
-- ALU_SLT   A < B ? 1 : 0, signed
-- ALU_SLTU  A < B ? 1 : 0, unsigned
-- ALU_SLL   B sll A(DATA_WIDTH_BITS-1 downto 0)
-- ALU_SRL   B srl A(DATA_WIDTH_BITS-1 downto 0)
-- ALU_SRA   B sra A(DATA_WIDTH_BITS-1 downto 0)
-- ALU_ADD   A + B
-- ALU_SUB   A - B
-- ALU_AND   A and B
-- ALU_OR    A or B
-- ALU_XOR   A xor B
-- ALU_NOR   not (A or B)
-------------------------------------------------------------------------------





	-- positional constants
	constant OPCODE_END : integer := 26;
	constant SHAMT_END  : integer := 6;
	constant RS_END     : integer := 21;
	constant I_RD_END   : integer := 16;
	constant RT_END   : integer := 16;
	constant R_RD_END   : integer := 11;
	
	constant INSTR_NOP  : std_logic_vector(INSTR_WIDTH-1 downto 0) := 
															(others => '0');
	
	-- opcodes
	constant OP_SPEC   : std_logic_vector(5 downto 0) := "000000";
	constant OP_REGIMM : std_logic_vector(5 downto 0) := "000001";
	constant OP_J      : std_logic_vector(5 downto 0) := "000010";
	constant OP_JAL    : std_logic_vector(5 downto 0) := "000011";
	constant OP_BEQ    : std_logic_vector(5 downto 0) := "000100";
	constant OP_BNE    : std_logic_vector(5 downto 0) := "000101";
	constant OP_BLEZ   : std_logic_vector(5 downto 0) := "000110";
	constant OP_BGTZ   : std_logic_vector(5 downto 0) := "000111";
	constant OP_ADDI   : std_logic_vector(5 downto 0) := "001000";
	constant OP_ADDIU  : std_logic_vector(5 downto 0) := "001001";
	constant OP_SLTI   : std_logic_vector(5 downto 0) := "001010";
	constant OP_SLTIU  : std_logic_vector(5 downto 0) := "001011";
	constant OP_ANDI   : std_logic_vector(5 downto 0) := "001100";
	constant OP_ORI    : std_logic_vector(5 downto 0) := "001101";
	constant OP_XORI   : std_logic_vector(5 downto 0) := "001110";
	constant OP_LUI    : std_logic_vector(5 downto 0) := "001111";
	constant OP_COP0   : std_logic_vector(5 downto 0) := "010000";
	constant OP_LB     : std_logic_vector(5 downto 0) := "100000";
	constant OP_LH     : std_logic_vector(5 downto 0) := "100001";
	constant OP_LW     : std_logic_vector(5 downto 0) := "100011";
	constant OP_LBU    : std_logic_vector(5 downto 0) := "100100";
	constant OP_LHU    : std_logic_vector(5 downto 0) := "100101";
	constant OP_SB     : std_logic_vector(5 downto 0) := "101000";
	constant OP_SH     : std_logic_vector(5 downto 0) := "101001";
	constant OP_SW     : std_logic_vector(5 downto 0) := "101011";

	-- (R) func codes
	constant RF_SLL    : std_logic_vector(5 downto 0) := "000000";
	constant RF_SRL    : std_logic_vector(5 downto 0) := "000010";
	constant RF_SRA    : std_logic_vector(5 downto 0) := "000011";
	constant RF_SLLV   : std_logic_vector(5 downto 0) := "000100";
	constant RF_SRLV   : std_logic_vector(5 downto 0) := "000110";
	constant RF_SRAV   : std_logic_vector(5 downto 0) := "000111";
	constant RF_JR     : std_logic_vector(5 downto 0) := "001000";
	constant RF_JALR   : std_logic_vector(5 downto 0) := "001001";
	constant RF_ADD    : std_logic_vector(5 downto 0) := "100000";
	constant RF_ADDU   : std_logic_vector(5 downto 0) := "100001";
	constant RF_SUB    : std_logic_vector(5 downto 0) := "100010";
	constant RF_SUBU   : std_logic_vector(5 downto 0) := "100011";
	constant RF_AND    : std_logic_vector(5 downto 0) := "100100";
	constant RF_OR     : std_logic_vector(5 downto 0) := "100101";
	constant RF_XOR    : std_logic_vector(5 downto 0) := "100110";
	constant RF_NOR    : std_logic_vector(5 downto 0) := "100111";
	constant RF_SLT    : std_logic_vector(5 downto 0) := "101010";
	constant RF_SLTU   : std_logic_vector(5 downto 0) := "101011";

	-- RegImm Instruction rd codes
	constant RII_RD_BLTZ   : std_logic_vector(4 downto 0) := "00000";
	constant RII_RD_BGEZ   : std_logic_vector(4 downto 0) := "00001";
	constant RII_RD_BLTZAL : std_logic_vector(4 downto 0) := "10000";
	constant RII_RD_BGEZAL : std_logic_vector(4 downto 0) := "10001";
	
	-- Cop0 Instructions
	constant CI_MFC0 : std_logic_vector(4 downto 0) := "00000";
	constant CI_MTC0 : std_logic_vector(4 downto 0) := "00100";


	-- internal signals
	signal rdaddr1, rdaddr2 : std_logic_vector(REG_BITS-1 downto 0) := 
															(others => '0');
	signal rddata1, rddata2 : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal instr_saved      : std_logic_vector(INSTR_WIDTH-1 downto 0) :=
															(others => '0');
	
	-- pc_out is pc_in delayed for one clock
	signal pc_out_next  : std_logic_vector(PC_WIDTH-1 downto 0) := 
															(others => '0');

	
	signal flush_lat : std_logic := '0';
	
begin  -- rtl


	regfile_inst : entity work.regfile
	port map (clk => clk, reset => reset, stall => stall, wraddr => wraddr,
		wrdata => wrdata, regwrite => regwrite, rdaddr1 => rdaddr1, 
		rdaddr2 => rdaddr2, rddata1 => rddata1, rddata2 => rddata2);





	prepare_regfile_addresses : process(all)
	-- prepare addresses to be ready on next rising clock
	-- addresses are valid before the rising clock (just after the 
	-- previous rising clock) so we can read them asynchronously
	
	
	begin
		-- done here because we have to read before instr gets latched to
		-- instr_saved, so we read directly from instr
		

		
		case instr(INSTR_WIDTH-1 downto OPCODE_END) is
			when OP_SPEC   => -- (R) special instructions
			
				case instr(SHAMT_END-1 downto 0) is
					when RF_SLL  => -- SLL  rd, rt, shamt

						if instr = (0 to INSTR_WIDTH-1 => '0') then
							-- leave default values, this is NOP instruction
							rdaddr1 <= (others => '0');
							rdaddr2 <= (others => '0');
						else
							rdaddr1 <= instr(RS_END-1 downto RT_END); -- get rt
							rdaddr2 <= (others => '0');
						end if;
						
					when RF_SRL  => -- SRL  rd, rt, shamt
						
						rdaddr1 <= instr(RS_END-1 downto RT_END); -- get rt
						rdaddr2 <= (others => '0');
						
					when RF_SRA  => -- SRA  rd, rt, shamt
					
						rdaddr1 <= instr(RS_END-1 downto RT_END); -- get rt
						rdaddr2 <= (others => '0');

					when RF_SLLV => -- SLLV rd, rt, shamt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_SRLV => -- SRLV rd, rt, rs
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_SRAV => -- SRAV rd, rt, rs
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_JR   => -- JR   rs
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= (others => '0');
						
					when RF_JALR => -- JALR rd, rs
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= (others => '0');
						
					when RF_ADD  => -- ADD  rd, rs, rt
					
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_ADDU => -- ADDU rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_SUB  => -- SUB  rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_SUBU => -- SUBU rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt	
						
					when RF_AND  => -- AND  rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_OR   => -- OR   rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_XOR  => -- XOR  rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_NOR  => -- NOR  rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_SLT  => -- SLT  rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when RF_SLTU => -- SLTU rd, rs, rt
						
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= instr(RS_END-1 downto RT_END); -- get rt
						
					when others  => -- unrecognized function
					
						rdaddr1 <= (others => '0');
						rdaddr2 <= (others => '0');
						
				end case;
			
			when OP_REGIMM => -- (I) regimm instructions
			
				case instr(RS_END-1 downto I_RD_END) is
					when RII_RD_BLTZ   => -- BLTZ  rs, imm18
					
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= (others => '0');
						
					when RII_RD_BGEZ   => -- BGEZ  rs, imm18
					
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= (others => '0');
						
					when RII_RD_BLTZAL => -- BLTZAL rs, imm18
					
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= (others => '0');
						
					when RII_RD_BGEZAL => -- BGEZAL rs, imm18
					
						rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
						rdaddr2 <= (others => '0');
						
					when others        => -- unrecognized rd
					
						rdaddr1 <= (others => '0');
						rdaddr2 <= (others => '0');
						
				end case;
			
			when OP_J      => -- (J) J address
				
				rdaddr1 <= (others => '0');
				rdaddr2 <= (others => '0');
				
			when OP_JAL    => -- (J) JAL address
				
				rdaddr1 <= (others => '0');
				rdaddr2 <= (others => '0');
				
			when OP_BEQ    => -- (I) BEQ rd, rs, imm18
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= instr(RS_END-1 downto I_RD_END); -- get rd
				
			when OP_BNE    => -- (I) BNE rd, rs, imm18
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= instr(RS_END-1 downto I_RD_END); -- get rd

			when OP_BLEZ   => -- (I) BLEZ rs, imm18
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');
				
			when OP_BGTZ   => -- (I) BGTZ rs, imm18
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_ADDI   => -- (I) ADDI rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_ADDIU  => -- (I) ADDIU rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_SLTI   => -- (I) SLTI rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_SLTIU  => -- (I) SLTIU rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_ANDI   => -- (I) ANDI rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_ORI    => -- (I) ORI rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_XORI   => -- (I) XORI rd, rs, imm16
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_LUI    => -- (I) LUI rd, imm16
				
				rdaddr1 <= (others => '0');
				rdaddr2 <= (others => '0');	
				
			when OP_COP0   => -- (R) cop0 instructions
				
				case instr(OPCODE_END-1 downto RS_END) is
					when CI_MFC0 => -- MFC0 rt, rd
						rdaddr1 <= (others => '0');
						rdaddr2 <= (others => '0');
					when CI_MTC0 => -- MTC0 rt, rd
						rdaddr1 <= instr(RS_END-1 downto RT_END); -- get rt
						rdaddr2 <= (others => '0');
					when others  => -- unrecognized rs
						rdaddr1 <= (others => '0');
						rdaddr2 <= (others => '0');
				end case;
			
			when OP_LB     => -- (I) LB rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_LH     => -- (I) LH rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_LW     => -- (I) LW rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_LBU    => -- (I) LBU rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');	
				
			when OP_LHU    => -- (I) LHU rd, imm16(rs)
			
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= (others => '0');
					
			when OP_SB     => -- (I) SB rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= instr(RS_END-1 downto I_RD_END); -- get rd
				
			when OP_SH     => -- (I) SH rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= instr(RS_END-1 downto I_RD_END); -- get rd	
				
			when OP_SW     => -- (I) SW rd, imm16(rs)
				
				rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				rdaddr2 <= instr(RS_END-1 downto I_RD_END); -- get rd
				
			when others    => -- unrecognized opcode
			
				rdaddr1 <= (others => '0');
				rdaddr2 <= (others => '0');	
	
		end case;

	
	end process;

	
	
	prepare_next_output : process(all)
	-- Decode the instruction
	
	variable exc_dec_use : std_logic := '0';
	variable exec_op_use : EXEC_OP_TYPE := EXEC_NOP;
	variable cop0_op_use : COP0_OP_TYPE := COP0_NOP;
	variable jmp_op_use  : JMP_OP_TYPE  := JMP_NOP;
	variable mem_op_use  : MEM_OP_TYPE  := MEM_NOP;
	variable wb_op_use   : WB_OP_TYPE   := WB_NOP;
	variable pc_out_use  : std_logic_vector(PC_WIDTH-1 downto 0) := 
															(others => '0');
	
	variable rddata1_b : std_logic_vector(DATA_WIDTH-1 downto 0) :=
															(others => '0');
	variable rddata2_b : std_logic_vector(DATA_WIDTH-1 downto 0) :=
															(others => '0');
	variable cop0_read_reg_use : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');

	begin
		
		
		-- Set defaults	
		exc_dec_use := '0'; -- Decoding exception
		-- Operation for execute stage
		exec_op_use := EXEC_NOP;
		-- Operation for coprocessor 0
		cop0_op_use := COP0_NOP;
		-- Operation for jump unit
		jmp_op_use  := JMP_NOP;
		-- Operation for memory unit
		mem_op_use  := MEM_NOP;
		-- Operation for write-back stage
		wb_op_use   := WB_NOP;
		-- Program counter
		pc_out_use  := pc_in;
		-- Cop0 read addr
		cop0_read_reg_use := (others => '0');
		

		rddata1_b := rddata1;
		rddata2_b := rddata2;

	
		-- decode opcode
		case instr_saved(INSTR_WIDTH-1 downto OPCODE_END) is
			when OP_SPEC   => -- (R) special instructions
			
				case instr_saved(SHAMT_END-1 downto 0) is
					when RF_SLL  => -- SLL  rd, rt, shamt
						
						if instr_saved = (0 to INSTR_WIDTH-1 => '0') then
							-- leave default values, this is NOP instruction
						else
							exec_op_use.aluop := ALU_SLL;
							
							exec_op_use.readdata1 := rddata1_b; -- rt
							exec_op_use.imm(4 downto 0) := instr_saved(R_RD_END-1 downto SHAMT_END); -- shmt
							exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
							exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
							exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
							exec_op_use.useamt := '1'; -- use shamt
							exec_op_use.regdst := '1'; -- result is in R format rd
							-- cop0 nothing
							-- jmp unit nothing
							-- mem unit nothing
							wb_op_use.memtoreg := '0';
							wb_op_use.regwrite := '1';
						
						end if;
						
					when RF_SRL  => -- SRL  rd, rt, shamt
						exec_op_use.aluop := ALU_SRL;
						
						exec_op_use.readdata1 := rddata1_b; -- rt
						exec_op_use.imm(4 downto 0) := instr_saved(R_RD_END-1 downto SHAMT_END); -- shmt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.useamt := '1'; -- use shamt
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_SRA  => -- SRA  rd, rt, shamt
						exec_op_use.aluop := ALU_SRA;
						
						exec_op_use.readdata1 := rddata1_b; -- rt
						exec_op_use.imm(4 downto 0) := instr_saved(R_RD_END-1 downto SHAMT_END); -- shmt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.useamt := '1'; -- use shamt
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_SLLV => -- SLLV rd, rt, rs
						exec_op_use.aluop := ALU_SLL;
						
						exec_op_use.readdata1(REG_BITS-1 downto 0) := rddata1_b(REG_BITS-1 downto 0); --rs(4:0)
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_SRLV => -- SRLV rd, rt, rs
						exec_op_use.aluop := ALU_SRL;
						
						exec_op_use.readdata1(REG_BITS-1 downto 0) := rddata1_b(REG_BITS-1 downto 0); --rs(4:0)
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_SRAV => -- SRAV rd, rt, rs
						exec_op_use.aluop := ALU_SRA;
						
						exec_op_use.readdata1(REG_BITS-1 downto 0) := rddata1_b(REG_BITS-1 downto 0); --rs(4:0)
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_JR   => -- JR   rs
						exec_op_use.aluop := ALU_NOP; -- not really a NOP, we just don't need to calculate anything
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						-- cop0 nothing
						jmp_op_use := JMP_JMP; -- unconditional jump
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						
					when RF_JALR => -- JALR rd, rs
						exec_op_use.aluop := ALU_ADD;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.imm := (2 => '1', others => '0'); -- put 4 in imm
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.useimm := '1';
						exec_op_use.link := '1';
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						jmp_op_use := JMP_JMP;
						-- mem unit nothing
						wb_op_use.memtoreg := '0'; -- use alu result
						wb_op_use.regwrite := '1';
						
					when RF_ADD  => -- ADD  rd, rs, rt
						exec_op_use.aluop := ALU_ADD;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						exec_op_use.ovf := '1'; -- pass on overflow
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_ADDU => -- ADDU rd, rs, rt
						exec_op_use.aluop := ALU_ADD;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						exec_op_use.ovf := '0'; -- don't pass on overflow
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_SUB  => -- SUB  rd, rs, rt
						exec_op_use.aluop := ALU_SUB;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						exec_op_use.ovf := '1'; -- pass on overflow
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when RF_SUBU => -- SUBU rd, rs, rt
						exec_op_use.aluop := ALU_SUB;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						exec_op_use.ovf := '0'; -- don't pass on overflow
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
											
					when RF_AND  => -- AND  rd, rs, rt
						exec_op_use.aluop := ALU_AND;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
										
					when RF_OR   => -- OR   rd, rs, rt
						exec_op_use.aluop := ALU_OR;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
									
					when RF_XOR  => -- XOR  rd, rs, rt
						exec_op_use.aluop := ALU_XOR;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
									
					when RF_NOR  => -- NOR  rd, rs, rt
						exec_op_use.aluop := ALU_NOR;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
									
					when RF_SLT  => -- SLT  rd, rs, rt
						exec_op_use.aluop := ALU_SLT;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
									
					when RF_SLTU => -- SLTU rd, rs, rt
						exec_op_use.aluop := ALU_SLTU;
						
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.readdata2 := rddata2_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						exec_op_use.regdst := '1'; -- result is in R format rd
						-- cop0 nothing
						-- jmp unit nothing
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when others  => -- unrecognized function
						
						exc_dec_use := '1';
						
				end case;
			
			when OP_REGIMM => -- (I) regimm instructions
			
				case instr_saved(RS_END-1 downto I_RD_END) is
					when RII_RD_BLTZ   => -- BLTZ  rs, imm18
						exec_op_use.aluop := ALU_SUB; -- not actually sub
				
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
						--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
						exec_op_use.useimm := '1';
						exec_op_use.branch := '1';
						-- cop0 nothing
						jmp_op_use := JMP_BLTZ;
						-- mem unit nothing
						-- wb unit nothing
						
					when RII_RD_BGEZ   => -- BGEZ  rs, imm18
						exec_op_use.aluop := ALU_SUB; -- not actually sub
				
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
						--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
						exec_op_use.useimm := '1';
						exec_op_use.branch := '1';
						-- cop0 nothing
						jmp_op_use := JMP_BGEZ;
						-- mem unit nothing
						-- wb unit nothing
						
					when RII_RD_BLTZAL => -- BLTZAL rs, imm18
						exec_op_use.aluop := ALU_SUB; -- not actually sub
				
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := (others => '1'); -- this is actually rd, we want results in r31
						--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
						exec_op_use.useimm := '1';
						exec_op_use.link   := '1';
						exec_op_use.branch := '1';
						exec_op_use.regdst := '0'; -- result is in R format rt (set manually to r31)
						-- cop0 nothing
						jmp_op_use := JMP_BLTZ;
						-- mem unit nothing
						wb_op_use.memtoreg := '0'; -- use alu result
						wb_op_use.regwrite := '1';
						
						
					when RII_RD_BGEZAL => -- BGEZAL rs, imm18
						exec_op_use.aluop := ALU_SUB; -- not actually sub
				
						exec_op_use.readdata1 := rddata1_b; -- rs
						exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := (others => '1'); -- this is actually rd, we want results in r31
						--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
						exec_op_use.useimm := '1';
						exec_op_use.link   := '1';
						exec_op_use.branch := '1';
						exec_op_use.regdst := '0'; -- result is in R format rt (set manually to r31)
						-- cop0 nothing
						jmp_op_use := JMP_BGEZ;
						-- mem unit nothing
						wb_op_use.memtoreg := '0'; -- use alu result
						wb_op_use.regwrite := '1';
						
					when others        => -- unrecognized rd
						
						exc_dec_use := '1';
						
				end case;
			
			when OP_J      => -- (J) J address
				exec_op_use.aluop := ALU_NOP; -- not really a nop
				
				exec_op_use.imm(OPCODE_END-1+2 downto 0+2) := instr_saved(OPCODE_END-1 downto 0); -- address, shifted by 2 left
				exec_op_use.useimm := '1';
				-- cop0 nothing
				jmp_op_use := JMP_JMP; -- unconditional jump
				-- mem unit nothing
				-- wb unit nothing
				
			when OP_JAL    => -- (J) JAL address
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.imm(OPCODE_END-1+2 downto 0+2) := instr_saved(OPCODE_END-1 downto 0);
				--exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END); -- no need
				exec_op_use.rt := (others => '1'); -- artificially write r31
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no need
				exec_op_use.useimm := '1';
				exec_op_use.link := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (set manually to r31)
				-- cop0 nothing
				jmp_op_use := JMP_JMP;
				-- mem unit nothing
				wb_op_use.memtoreg := '0'; -- use alu result
				wb_op_use.regwrite := '1';
						
			when OP_BEQ    => -- (I) BEQ rd, rs, imm18
				exec_op_use.aluop := ALU_SUB;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.readdata2 := rddata2_b; -- rd
				exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.branch := '1';
				-- cop0 nothing
				jmp_op_use := JMP_BEQ;
				-- mem unit nothing
				-- wb unit nothing
				
			when OP_BNE    => -- (I) BNE rd, rs, imm18
				exec_op_use.aluop := ALU_SUB;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.readdata2 := rddata2_b; -- rd
				exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.branch := '1';
				-- cop0 nothing
				jmp_op_use := JMP_BNE;
				-- mem unit nothing
				-- wb unit nothing
				
			when OP_BLEZ   => -- (I) BLEZ rs, imm18
				exec_op_use.aluop := ALU_SUB; -- not actually sub
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.branch := '1';
				-- cop0 nothing
				jmp_op_use := JMP_BLEZ;
				-- mem unit nothing
				-- wb unit nothing
				
			when OP_BGTZ   => -- (I) BGTZ rs, imm18
				exec_op_use.aluop := ALU_SUB; -- not actually sub
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1+2 downto 0+2) := instr_saved(I_RD_END-1 downto 0); -- imm shifted by 2 to the left
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.branch := '1';
				-- cop0 nothing
				jmp_op_use := JMP_BGTZ;
				-- mem unit nothing
				-- wb unit nothing
				
			when OP_ADDI   => -- (I) ADDI rd, rs, imm16
				exec_op_use.aluop := ALU_ADD;

				exec_op_use.readdata1 := rddata1_b; -- rs
				if instr_saved(I_RD_END-1) = '0' then
					exec_op_use.imm := (others => '0');
				else
					exec_op_use.imm := (others => '1');
				end if;
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				exec_op_use.ovf := '1'; -- pass on overflow
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_ADDIU  => -- (I) ADDIU rd, rs, imm16
				exec_op_use.aluop := ALU_ADD; -- not important if imm positive or negative as it will just wrap around if negative
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				if instr_saved(I_RD_END-1) = '0' then -- addi also needsr sign extended immediate
					exec_op_use.imm := (others => '0');
				else
					exec_op_use.imm := (others => '1');
				end if;
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_SLTI   => -- (I) SLTI rd, rs, imm16
				exec_op_use.aluop := ALU_SLT;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_SLTIU  => -- (I) SLTIU rd, rs, imm16
				exec_op_use.aluop := ALU_SLTU;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_ANDI   => -- (I) ANDI rd, rs, imm16
				exec_op_use.aluop := ALU_AND;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_ORI    => -- (I) ORI rd, rs, imm16
				exec_op_use.aluop := ALU_OR;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_XORI   => -- (I) XORI rd, rs, imm16
				exec_op_use.aluop := ALU_XOR;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_LUI    => -- (I) LUI rd, imm16
				exec_op_use.aluop := ALU_LUI;
				
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				--exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END); -- no sense, actually part of imm
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				-- mem unit nothing
				wb_op_use.memtoreg := '0';
				wb_op_use.regwrite := '1';
				
			when OP_COP0   => -- (R) cop0 instructions
				
				
				case instr_saved(OPCODE_END-1 downto RS_END) is
					when CI_MFC0 => -- MFC0 rt, rd
						exec_op_use.aluop := ALU_NOP; -- not really a NOP, we just don't need to calculate anything
						
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						-- cop0.op nothing
						cop0_read_reg_use := instr_saved(RT_END-1 downto R_RD_END); 
						jmp_op_use := JMP_NOP; -- unconditional jump
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						wb_op_use.regwrite := '1';
						
					when CI_MTC0 => -- MTC0 rt, rd
						
						exec_op_use.aluop := ALU_NOP; -- not really a NOP, we just don't need to calculate anything
						
						exec_op_use.readdata1 := rddata1_b; -- rt
						exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
						exec_op_use.rt := instr_saved(RS_END-1 downto RT_END);
						exec_op_use.rd := instr_saved(RT_END-1 downto R_RD_END);
						cop0_op_use.wr := '1';
						cop0_op_use.addr := instr_saved(RT_END-1 downto R_RD_END); -- save to COP0 addr = rd
						jmp_op_use := JMP_NOP; -- unconditional jump
						-- mem unit nothing
						wb_op_use.memtoreg := '0';
						
					when others  => -- unrecognized rs
						
						exc_dec_use := '1';
						
				end case;
			
			when OP_LB     => -- (I) LB rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '1';
				mem_op_use.memwrite := '0';
				mem_op_use.memtype := MEM_B;
				wb_op_use.memtoreg := '1'; -- use memory result
				wb_op_use.regwrite := '1'; -- write to register			
				
			when OP_LH     => -- (I) LH rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '1';
				mem_op_use.memwrite := '0';
				mem_op_use.memtype := MEM_H;
				wb_op_use.memtoreg := '1'; -- use memory result
				wb_op_use.regwrite := '1'; -- write to register
				
			when OP_LW     => -- (I) LW rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '1';
				mem_op_use.memwrite := '0';
				mem_op_use.memtype := MEM_W;
				wb_op_use.memtoreg := '1'; -- use memory result
				wb_op_use.regwrite := '1'; -- write to register
				
			when OP_LBU    => -- (I) LBU rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '1';
				mem_op_use.memwrite := '0';
				mem_op_use.memtype := MEM_BU;
				wb_op_use.memtoreg := '1'; -- use memory result
				wb_op_use.regwrite := '1'; -- write to register
				
			when OP_LHU    => -- (I) LHU rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				exec_op_use.regdst := '0'; -- result is in R format rt (I format rd)
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '1';
				mem_op_use.memwrite := '0';
				mem_op_use.memtype := MEM_HU;
				wb_op_use.memtoreg := '1'; -- use memory result
				wb_op_use.regwrite := '1'; -- write to register
				
			when OP_SB     => -- (I) SB rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.readdata2(7 downto 0) := rddata2_b(7 downto 0); -- rd
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '0';
				mem_op_use.memwrite := '1';
				mem_op_use.memtype := MEM_B;
				-- wb unit nothing
				
			when OP_SH     => -- (I) SH rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.readdata2(15 downto 0) := rddata2_b(15 downto 0); -- rd
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '0';
				mem_op_use.memwrite := '1';
				mem_op_use.memtype := MEM_H;
				-- wb unit nothing
				
			when OP_SW     => -- (I) SW rd, imm16(rs)
				exec_op_use.aluop := ALU_ADD;
				
				exec_op_use.readdata1 := rddata1_b; -- rs
				exec_op_use.readdata2 := rddata2_b; -- rd
				exec_op_use.imm(I_RD_END-1 downto 0) := instr_saved(I_RD_END-1 downto 0);
				exec_op_use.rs := instr_saved(OPCODE_END-1 downto RS_END);
				exec_op_use.rt := instr_saved(RS_END-1 downto RT_END); -- this is actually rd
				exec_op_use.useimm := '1';
				-- cop0 nothing
				-- jmp unit nothing
				mem_op_use.memread := '0';
				mem_op_use.memwrite := '1';
				mem_op_use.memtype := MEM_W;
				-- wb unit nothing
				
			when others    => -- unrecognized opcode
				
				exc_dec_use := '1';
	
		end case;
		

		if flush_lat = '0' then
			exc_dec <= exc_dec_use;
			exec_op <= exec_op_use;
			cop0_op <= cop0_op_use;
			jmp_op  <= jmp_op_use;
			mem_op  <= mem_op_use;
			wb_op   <= wb_op_use;
			pc_out_next  <= pc_out_use;
			cop0_read_reg <= cop0_read_reg_use;
		else
			exc_dec <= '0';
			--exc_dec <= exc_dec_use;
			exec_op <= EXEC_NOP;
			cop0_op <= COP0_NOP;
			jmp_op  <= JMP_NOP;
			mem_op  <= MEM_NOP;
			wb_op   <= WB_NOP;
			pc_out_next  <= pc_out_use;
			cop0_read_reg <= (others => '0');
		end if;


	end process;
	
	
	
	

	process(all)
	
	
	begin
	
		if reset = '0' then
			
			instr_saved <= INSTR_NOP;
			pc_out <= (others => '0');
			flush_lat <= '0';

		/*elsif flush = '1' then


				-- ***
				instr_saved <= INSTR_NOP;
				pc_out <= pc_out_next; -- TODO remove this to make decode hold last pc during flush*/
			
		elsif rising_edge(clk) then

			flush_lat <= flush;
			if stall = '0' then
							
				instr_saved <= instr;
				pc_out <= pc_out_next;
				
			end if;			
			
			
		
		end if;
	
	
	end process;





end rtl;
