library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

use work.alu;

entity exec is
	
	port (
		clk, reset       : in  std_logic;
		stall      		 : in  std_logic;
		flush            : in  std_logic;
		pc_in            : in  std_logic_vector(PC_WIDTH-1 downto 0);
		op	   	         : in  exec_op_type;
		pc_out           : out std_logic_vector(PC_WIDTH-1 downto 0);
		rd, rs, rt       : out std_logic_vector(REG_BITS-1 downto 0);
		aluresult	     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wrdata           : out std_logic_vector(DATA_WIDTH-1 downto 0);
		zero, neg        : out std_logic;
		new_pc           : out std_logic_vector(PC_WIDTH-1 downto 0);		
		memop_in         : in  mem_op_type;
		memop_out        : out mem_op_type;
		jmpop_in         : in  jmp_op_type;
		jmpop_out        : out jmp_op_type;
		wbop_in          : in  wb_op_type;
		wbop_out         : out wb_op_type;
		forwardA         : in  fwd_type;
		forwardB         : in  fwd_type;
		cop0_rddata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		cop0_op_in	 : in cop0_op_type;				-- TODO: from decode
		cop0_read_reg_in : in std_logic_vector(REG_BITS-1 downto 0);
		mem_aluresult    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_result        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		exc_ovf          : out std_logic;
		regA             : out std_logic_vector(REG_BITS-1 downto 0);
		regB             : out std_logic_vector(REG_BITS-1 downto 0);
		regDest          : out std_logic_vector(REG_BITS-1 downto 0));

end exec;

architecture rtl of exec is

	constant ADDR_STATUS : std_logic_vector(REG_BITS-1 downto 0) := "01100";
	constant ADDR_CAUSE  : std_logic_vector(REG_BITS-1 downto 0) := "01101";
	constant ADDR_EPC    : std_logic_vector(REG_BITS-1 downto 0) := "01110";
	constant ADDR_NPC    : std_logic_vector(REG_BITS-1 downto 0) := "01111";

	signal pc_in_saved : std_logic_vector(PC_WIDTH-1 downto 0) := 
														(others => '0');
	signal op_saved : exec_op_type  := EXEC_NOP;
	signal memop_saved : mem_op_type := MEM_NOP;
	signal jmpop_saved : jmp_op_type := JMP_NOP;
	signal wbop_saved  : wb_op_type  := WB_NOP;

	signal cop0op_saved : cop0_op_type := COP0_NOP;
	signal cop0_read_reg_saved : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');

	signal alu_op : alu_op_type := ALU_NOP;
	signal alu_A  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal alu_B  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal alu_R  : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal alu_Z  : std_logic;
	signal alu_V  : std_logic;
	
	constant PC_FOUR : std_logic_vector(PC_WIDTH-1 downto 0) := (2 => '1', others => '0');
	
	signal wbop_out_prepare : wb_op_type := WB_NOP;

	signal flush_lat : std_logic := '0';

begin  -- rtl

	alu_inst : entity work.alu
	port map(op => alu_op, A => alu_A, B => alu_B, R => alu_R, Z => alu_Z,
			V => alu_V);

			
			
			
	prepare_fwd_regs : process(all)
		variable regA_use, regB_use : std_logic_vector(REG_BITS-1 downto 0);
	begin
	
	regA_use := (others => '0');
	regB_use := (others => '0');
	
	case op.aluop is
	
			when ALU_NOP  =>		-- R = A
				-- (R) instruction : NOP, JR, MTC, MFC
				-- (J) instruction : J

				
			when ALU_LUI  =>		-- R = B sll 16
				-- (I) instruction: LUI
				
				
			when ALU_SLT  =>		-- R = A < B ? 1 : 0, signed
				-- (R) instruction: SLT
				-- (I) instruction: SLTI
				
				if op.useimm = '0' then -- SLT
				
					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- SLTI
				
					regA_use := op.rs;
				
				end if;
				
			when ALU_SLTU =>		-- R = A < B ? 1 : 0, unsigned
				-- (R) instruction: SLTU
				-- (I) instruction: SLTIU
				
				if op.useimm = '0' then -- SLTU
				
					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- SLTIU
				
					regA_use := op.rs;
				
				end if;
				
			when ALU_SLL  =>		-- R = B sll A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SLL, SLLV
				
				if op.useamt = '0' then -- SLLV

					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- SLL
			
					regB_use := op.rt;
				
				end if;
				
			when ALU_SRL  =>		-- R = B srl A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SRL, SRLV
				
				if op.useamt = '0' then -- SRLV

					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- SRL

					regB_use := op.rt;
				
				end if;
				
			when ALU_SRA  =>		-- R = B sra A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SRA, SRAV
				
				if op.useamt = '0' then -- SRAV
					
					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- SRA
				
					regB_use := op.rt;
				
				end if;
				
			when ALU_ADD  =>		-- R = A + B
				-- (R) instruction: JALR, ADD, ADDU
				-- (I) instruction: ADDI, ADDIU, LB, LH, LW, LBU, LHU, SB, SH, SW
				-- (J) instruction: JAL
				
				if wbop_in.memtoreg = '0' then
					-- JALR, ADD, ADDU, ADDI, ADDIU, JAL, SB, SH, SW
					
					if memop_in.memwrite = '0' then
						-- JALR, ADD, ADDU, ADDI, ADDIU, JAL
						
						if op.link = '0' then
							-- ADD, ADDU, ADDI, ADDIU
							if op.useimm = '0' then
								-- ADD, ADDU
								
								regA_use := op.rs;
								regB_use := op.rt;
								
							else
								-- ADDI, ADDIU
								
								regA_use := op.rs;
								
							end if;
						else
							-- JALR, JAL

						end if;
					else
						-- SB, SH, SW
						
						regA_use := op.rs;
						regB_use := op.rt; -- use regB to check if rd (which is in rt) has been modified within last 2 cycles
						
					end if;
				
				else
					-- LB, LH, LW, LBU, LHU
					
					regA_use := op.rs;
					
				end if;
				
			when ALU_SUB  =>		-- R = A - B
				-- (R) instruction: SUB, SUBU
				-- (I) instruction: BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ, BLTZAL, BGEZAL
				
				if op.branch = '0' then
					-- SUB and SUBU
					
					regA_use := op.rs;
					regB_use := op.rt;
					
				else
					-- BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ, BLTZAL, BGEZAL
					
					if op.link = '0' then
						-- BEQ and BNE
						
						if jmpop_in = JMP_BEQ or jmpop_in = JMP_BNE then

							regA_use := op.rs;
							regB_use := op.rt;
							
						else
							-- BLTZ, BGEZ, BLEZ, BGTZ
							
							regA_use := op.rs;
						
						end if;
						
					else
						-- BLTZAL, BGEZAL
						
						regA_use := op.rs;
						
					end if;
					
				end if;
				
			when ALU_AND  =>		-- R = A and B
				-- (R) instruction: AND
				-- (I) instruction: ANDI
				
				if op.useimm = '0' then -- AND
					
					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- ANDI
				
					regA_use := op.rs;
				
				end if;
				
			when ALU_OR   =>		-- R = A or B
				-- (R) instruction: OR
				-- (I) instruction: ORI
				
				if op.useimm = '0' then -- OR
					
					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- ORI
				
					regA_use := op.rs;
				
				end if;
				
			when ALU_XOR  =>		-- R = A xor B
				-- (R) instruction: XOR
				-- (I) instruction: XORI
				
				if op.useimm = '0' then -- XOR
					
					regA_use := op.rs;
					regB_use := op.rt;
					
				else -- XORI
				
					regA_use := op.rs;
				
				end if;
				
			when ALU_NOR  =>		-- R = not (A or B)
				-- (R) instruction: NOR
				
				regA_use := op.rs;
				regB_use := op.rt;
				
			when others   =>
				-- impossible
		
		
		end case;

		regA <= regA_use;
		regB <= regB_use;
	
	end process;
			
			
	prepare_output : process(all)

	variable alu_op_use : alu_op_type := ALU_NOP;
	variable alu_A_use  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	variable alu_B_use  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	variable pc_out_use : std_logic_vector(PC_WIDTH-1 downto 0);
	variable rd_use, rs_use, rt_use : std_logic_vector(REG_BITS-1 downto 0);
	variable new_pc_use : std_logic_vector(PC_WIDTH-1 downto 0);
	variable new_pc_prepare : std_logic_vector(PC_WIDTH-1 downto 0);
	variable pc_incr_prepare : std_logic_vector(PC_WIDTH-1 downto 0);
	--variable regA_use, regB_use : std_logic_vector(REG_BITS-1 downto 0);
	variable regDest_use : std_logic_vector(REG_BITS-1 downto 0);
	
	begin

		alu_op_use := ALU_NOP;
		alu_A_use  := (others => '0');
		alu_B_use  := (others => '0');
		pc_out_use := (others => '0');
		rd_use := (others => '0');
		rs_use := (others => '0');
		rt_use := (others => '0');
		new_pc_use := (others => '0');
		
		-- only taking lower 14 bits of the 16 (18 after shifting in decode) immediate (because pc is 14 bit)
		new_pc_prepare := std_logic_vector(signed(pc_in_saved) + signed(op_saved.imm(PC_WIDTH-1 downto 0)));
		pc_incr_prepare := std_logic_vector(signed(pc_in_saved) + signed(PC_FOUR)); -- PC+4 
		
		
		--regA_use := (others => '0');
		--regB_use := (others => '0');
		regDest_use := (others => '0');
		
		
		
		case op_saved.aluop is
			when ALU_NOP  =>		-- R = A
				-- (R) instruction : NOP, JR, MTC, MFC
				-- (J) instruction : J

				if cop0op_saved.wr = '1' then
					-- MTC
					alu_op_use := ALU_NOP;
					alu_A_use := op_saved.readdata1;
					alu_B_use := (others => '0');
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;

				elsif cop0_read_reg_saved = ADDR_STATUS or cop0_read_reg_saved = ADDR_CAUSE
				   or cop0_read_reg_saved = ADDR_EPC    or cop0_read_reg_saved = ADDR_NPC  then
					-- MFC
					alu_op_use := ALU_NOP;
					alu_A_use := cop0_rddata;
					alu_B_use := (others => '0');
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- TODO: op_saved.rd
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;

				elsif jmpop_saved = JMP_NOP then
					-- NOP
					alu_op_use := ALU_NOP;
					alu_A_use := (others => '0');
					alu_B_use := (others => '0');
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;

				else
					-- J, JR
					if op_saved.useimm = '0' then
						-- JR
						alu_op_use := ALU_NOP;
						alu_A_use := (others => '0');
						alu_B_use := (others => '0');
						rs_use := op_saved.rs;
						rt_use := op_saved.rt;
						rd_use := op_saved.rd;
						pc_out_use := pc_in_saved;
						new_pc_use := op_saved.readdata1(PC_WIDTH-1 downto 0); -- rs
					
					else
						-- J
						alu_op_use := ALU_NOP;
						alu_A_use := (others => '0');
						alu_B_use := (others => '0');
						rs_use := op_saved.rs;
						rt_use := op_saved.rt;
						rd_use := op_saved.rd;
						pc_out_use := pc_in_saved;
						new_pc_use := op_saved.imm(PC_WIDTH-1 downto 0);
					
					end if;
					
				end if;
				
			when ALU_LUI  =>		-- R = B sll 16
				-- (I) instruction: LUI
				
				alu_op_use := ALU_LUI;
				alu_A_use := (others => '0');
				alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
				rs_use := op_saved.rs;
				rt_use := op_saved.rt;
				rd_use := op_saved.rt; -- Dest is rt
				pc_out_use := pc_in_saved;
				new_pc_use := pc_in_saved;
				
			when ALU_SLT  =>		-- R = A < B ? 1 : 0, signed
				-- (R) instruction: SLT
				-- (I) instruction: SLTI
				
				if op_saved.useimm = '0' then -- SLT
				
					alu_op_use := ALU_SLT;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- SLTI
				
					alu_op_use := ALU_SLT;
					alu_A_use := op_saved.readdata1; -- rs
					if op_saved.imm(15) = '0' then -- if positive then fill left with 0s
						alu_B_use := (others => '0');
					else 						-- if negative then fill left with 1s
						alu_B_use := (others => '1');
					end if;
					alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
				
				end if;
				
			when ALU_SLTU =>		-- R = A < B ? 1 : 0, unsigned
				-- (R) instruction: SLTU
				-- (I) instruction: SLTIU
				
				if op_saved.useimm = '0' then -- SLTU
				
					alu_op_use := ALU_SLTU;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- SLTIU
				
					alu_op_use := ALU_SLTU;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
				
				end if;
				
			when ALU_SLL  =>		-- R = B sll A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SLL, SLLV
				
				if op_saved.useamt = '0' then -- SLLV
					
					alu_op_use := ALU_SLL;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- SLL
				
					alu_op_use := ALU_SLL;
					alu_A_use := op_saved.imm; -- shamt
					alu_B_use := op_saved.readdata1; -- rt
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regB_use := op_saved.rt;
				
				end if;
				
			when ALU_SRL  =>		-- R = B srl A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SRL, SRLV
				
				if op_saved.useamt = '0' then -- SRLV
					
					alu_op_use := ALU_SRL;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- SRL
				
					alu_op_use := ALU_SRL;
					alu_A_use := op_saved.imm; -- shamt
					alu_B_use := op_saved.readdata1; -- rt
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regB_use := op_saved.rt;
				
				end if;
				
			when ALU_SRA  =>		-- R = B sra A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SRA, SRAV
				
				if op_saved.useamt = '0' then -- SRAV
					
					alu_op_use := ALU_SRA;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- SRA
				
					alu_op_use := ALU_SRA;
					alu_A_use := op_saved.imm; -- shamt
					alu_B_use := op_saved.readdata1; -- rt
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regB_use := op_saved.rt;
				
				end if;
				
			when ALU_ADD  =>		-- R = A + B
				-- (R) instruction: JALR, ADD, ADDU
				-- (I) instruction: ADDI, ADDIU, LB, LH, LW, LBU, LHU, SB, SH, SW
				-- (J) instruction: JAL
				
				if wbop_saved.memtoreg = '0' then
					-- JALR, ADD, ADDU, ADDI, ADDIU, JAL, SB, SH, SW
					
					if memop_saved.memwrite = '0' then
						-- JALR, ADD, ADDU, ADDI, ADDIU, JAL
						
						if op_saved.link = '0' then
							-- ADD, ADDU, ADDI, ADDIU
							if op_saved.useimm = '0' then
								-- ADD, ADDU
								
								alu_op_use := ALU_ADD;
								alu_A_use := op_saved.readdata1; -- rs
								alu_B_use := op_saved.readdata2; -- rt
								if forwardA = FWD_ALU then
									alu_A_use := mem_aluresult;
								elsif forwardA = FWD_WB then
									alu_A_use := wb_result;
								end if;
								if forwardB = FWD_ALU then
									alu_B_use := mem_aluresult;
								elsif forwardB = FWD_WB then
									alu_B_use := wb_result;
								end if;
								rs_use := op_saved.rs;
								rt_use := op_saved.rt;
								rd_use := op_saved.rd;
								pc_out_use := pc_in_saved;
								new_pc_use := pc_in_saved;
								--regA_use := op_saved.rs;
								--regB_use := op_saved.rt;
								
							else
								-- ADDI, ADDIU
								
								alu_op_use := ALU_ADD;
								alu_A_use := op_saved.readdata1; -- rs
								alu_B_use := op_saved.imm;
								if forwardA = FWD_ALU then
									alu_A_use := mem_aluresult;
								elsif forwardA = FWD_WB then
									alu_A_use := wb_result;
								end if;
								rs_use := op_saved.rs;
								rt_use := op_saved.rt;
								rd_use := op_saved.rt; -- Dest is rt
								pc_out_use := pc_in_saved;
								new_pc_use := pc_in_saved;
								--regA_use := op_saved.rs;
								
							end if;
						else
							-- JALR, JAL
							if op_saved.regdst = '0' then
								-- JAL
								
								alu_op_use := ALU_ADD;
								alu_A_use := (others => '0');
								alu_A_use(PC_WIDTH-1 downto 0) := pc_in_saved(PC_WIDTH-1 downto 0);
								alu_B_use := (2 => '1', others => '0'); -- load 4
								rs_use := op_saved.rs;
								rt_use := op_saved.rt;
								rd_use := op_saved.rt; -- Dist is rt (r31)
								pc_out_use := pc_in_saved;
								new_pc_use := op_saved.imm(PC_WIDTH-1 downto 0);
								
							else
								-- JALR
								
								alu_op_use := ALU_ADD;
								alu_A_use := (others => '0');
								alu_A_use(PC_WIDTH-1 downto 0) := pc_in_saved(PC_WIDTH-1 downto 0);
								alu_B_use := (2 => '1', others => '0'); -- load 4
								rs_use := op_saved.rs;
								rt_use := op_saved.rt;
								rd_use := op_saved.rd;
								pc_out_use := pc_in_saved;
								new_pc_use := op_saved.readdata1(PC_WIDTH-1 downto 0); -- rs
								
							end if;
						end if;
					else
						-- SB, SH, SW
						
						alu_op_use := ALU_ADD;
						alu_A_use := op_saved.readdata1; -- rs
						if op_saved.imm(15) = '0' then -- if positive then fill left with 0s
							alu_B_use := (others => '0');
						else 						-- if negative then fill left with 1s
							alu_B_use := (others => '1');
						end if;
						alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
						if forwardA = FWD_ALU then
							alu_A_use := mem_aluresult;
						elsif forwardA = FWD_WB then
							alu_A_use := wb_result;
						end if;
						rs_use := op_saved.rs;
						rt_use := op_saved.rt;
						rd_use := op_saved.rd;
						pc_out_use := pc_in_saved;
						new_pc_use := pc_in_saved;
						--regA_use := op_saved.rs;
						--regB_use := op_saved.rt; -- use regB to check if rd (which is in rt) has been modified within last 2 cycles
						
					end if;
				
				else
					-- LB, LH, LW, LBU, LHU
					
					alu_op_use := ALU_ADD;
					alu_A_use := op_saved.readdata1; -- rs
					if op_saved.imm(15) = '0' then -- if positive then fill left with 0s
						alu_B_use := (others => '0');
					else 						-- if negative then fill left with 1s
						alu_B_use := (others => '1');
					end if;
					alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dist is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					
				end if;
				
			when ALU_SUB  =>		-- R = A - B
				-- (R) instruction: SUB, SUBU
				-- (I) instruction: BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ, BLTZAL, BGEZAL
				
				if op_saved.branch = '0' then
					-- SUB and SUBU
					
					alu_op_use := ALU_SUB;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else
					-- BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ, BLTZAL, BGEZAL
					
					if op_saved.link = '0' then
						-- BEQ and BNE
						
						if jmpop_saved = JMP_BEQ or jmpop_saved = JMP_BNE then
							
							alu_op_use := ALU_SUB;
							alu_A_use := op_saved.readdata1; -- rs
							alu_B_use := op_saved.readdata2; -- rt
							if forwardA = FWD_ALU then
								alu_A_use := mem_aluresult;
							elsif forwardA = FWD_WB then
								alu_A_use := wb_result;
							end if;
							if forwardB = FWD_ALU then
								alu_B_use := mem_aluresult;
							elsif forwardB = FWD_WB then
								alu_B_use := wb_result;
							end if;
							rs_use := op_saved.rs;
							rt_use := op_saved.rt;
							-- rd_use := op_saved.rd; -- nothing will be saved
							pc_out_use := pc_in_saved;
							new_pc_use := new_pc_prepare;
							--regA_use := op_saved.rs;
							--regB_use := op_saved.rt;
							
						else
							-- BLTZ, BGEZ, BLEZ, BGTZ
							
							alu_op_use := ALU_SUB;
							alu_A_use := op_saved.readdata1; -- rs
							alu_B_use := (others => '0');
							if forwardA = FWD_ALU then
								alu_A_use := mem_aluresult;
							elsif forwardA = FWD_WB then
								alu_A_use := wb_result;
							end if;
							rs_use := op_saved.rs;
							rt_use := op_saved.rt;
							rd_use := op_saved.rd;
							pc_out_use := pc_in_saved;
							new_pc_use := new_pc_prepare;
							--regA_use := op_saved.rs;
						
						end if;
						
					else
						-- BLTZAL, BGEZAL
						
						alu_op_use := ALU_SUB;
						alu_A_use := op_saved.readdata1; -- rs
						alu_B_use := (others => '0');
						if forwardA = FWD_ALU then
							alu_A_use := mem_aluresult;
						elsif forwardA = FWD_WB then
							alu_A_use := wb_result;
						end if;
						rs_use := op_saved.rs;
						rt_use := op_saved.rt;
						rd_use := op_saved.rt; -- Dest is rt
						pc_out_use := pc_in_saved;
						new_pc_use := new_pc_prepare;
						--regA_use := op_saved.rs;
					end if;
					
				end if;
				
			when ALU_AND  =>		-- R = A and B
				-- (R) instruction: AND
				-- (I) instruction: ANDI
				
				if op_saved.useimm = '0' then -- AND
					
					alu_op_use := ALU_AND;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- ANDI
				
					alu_op_use := ALU_AND;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
				
				end if;
				
			when ALU_OR   =>		-- R = A or B
				-- (R) instruction: OR
				-- (I) instruction: ORI
				
				if op_saved.useimm = '0' then -- OR
					
					alu_op_use := ALU_OR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- ORI
				
					alu_op_use := ALU_OR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
				
				end if;
				
			when ALU_XOR  =>		-- R = A xor B
				-- (R) instruction: XOR
				-- (I) instruction: XORI
				
				if op_saved.useimm = '0' then -- XOR
					
					alu_op_use := ALU_XOR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					if forwardB = FWD_ALU then
						alu_B_use := mem_aluresult;
					elsif forwardB = FWD_WB then
						alu_B_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
					--regB_use := op_saved.rt;
					
				else -- XORI
				
					alu_op_use := ALU_XOR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					if forwardA = FWD_ALU then
						alu_A_use := mem_aluresult;
					elsif forwardA = FWD_WB then
						alu_A_use := wb_result;
					end if;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					--regA_use := op_saved.rs;
				
				end if;
				
			when ALU_NOR  =>		-- R = not (A or B)
				-- (R) instruction: NOR
				
				alu_op_use := ALU_NOR;
				alu_A_use := op_saved.readdata1; -- rs
				alu_B_use := op_saved.readdata2; -- rt
				if forwardA = FWD_ALU then
					alu_A_use := mem_aluresult;
				elsif forwardA = FWD_WB then
					alu_A_use := wb_result;
				end if;
				if forwardB = FWD_ALU then
					alu_B_use := mem_aluresult;
				elsif forwardB = FWD_WB then
					alu_B_use := wb_result;
				end if;
				rs_use := op_saved.rs;
				rt_use := op_saved.rt;
				rd_use := op_saved.rd;
				pc_out_use := pc_in_saved;
				new_pc_use := pc_in_saved;	
				--regA_use := op_saved.rs;
				--regB_use := op_saved.rt;
				
			when others   =>
				-- impossible
		
		
		end case;


		alu_op <= alu_op_use;
		alu_A  <= alu_A_use;
		alu_B  <= alu_B_use;
		pc_out <= pc_out_use;


		if op_saved.ovf = '1' then -- if overflow trap is enabled, we set overflow output to ALU's overflow flag
			exc_ovf <= alu_V;
			
		else -- otherwise, overflow is disabled
			exc_ovf <= '0';
		end if;

		if (alu_V = '1' and op_saved.ovf = '1') or flush_lat = '1' or reset = '0' then --TODOTODO self flush?
			--wbop_out_prepare <= WB_NOP;
			wbop_out <= WB_NOP;
		else
			--wbop_out_prepare <= wbop_saved;
			wbop_out <= wbop_saved;
		end if;

/*
		if flush_lat = '1' or (op_saved.ovf = '1' and alu_V = '1') then -- if flush from ctrl or overflow detected

			rd <= (others => '0');
			rs <= (others => '0');
			rt <= (others => '0');
			regA <= (others => '0');
			regB <= (others => '0');
			regDest <= (others => '0');
			aluresult <= (others => '0');
			zero <= '0';
			neg <= '0';
			new_pc <= new_pc_use;
			wrdata <= (others => '0');

		else
*/
			rd <= rd_use;
			rs <= rs_use;
			rt <= rt_use;
			
			
			
			regDest_use := rd_use;
			
--			regA <= regA_use;
--			regB <= regB_use;
			regDest <= regDest_use;
			
			
			
			
			if op_saved.aluop = ALU_SUB and op_saved.link = '1' and op_saved.branch = '1' then -- if we have branch and link command, we have to set aluresult to pc+4 (pc_incr_prepare)
				aluresult(PC_WIDTH-1 downto 0) <= pc_incr_prepare;
				aluresult(DATA_WIDTH-1 downto PC_WIDTH) <= (others => '0');
				
			-- elsif -- TODO for cop0 commands TODOTODO not needed, done by NOP and using A
			
			else -- otherwise, the aluresult is the actual result from ALU
				aluresult <= alu_R;
			end if; 
			
			zero      <= alu_Z;
			neg       <= alu_R(DATA_WIDTH-1); -- negative flag corresponds to the left-most bit of the result
			new_pc    <= new_pc_use;
		
			
			
			
			if op_saved.aluop = ALU_ADD and wbop_saved.memtoreg = '0' and memop_saved.memwrite = '1' then -- in case of store commands, the value to be written to memory is in rd register
				if forwardB = FWD_ALU then -- register of value to be written was given to regB
					wrdata <= mem_aluresult;
				elsif forwardB = FWD_WB then
					wrdata <= wb_result;
				else
					wrdata <= op_saved.readdata2; -- value of rd register
				end if;
				
			else -- otherwise we write nothing to memory
				wrdata <= (others => '0');
			end if;
--		end if;

	end process;



	process(all)
	begin
	
		if reset = '0' then
		
			pc_in_saved <= (others => '0');
			op_saved <= EXEC_NOP;
			memop_saved <= MEM_NOP;
			jmpop_saved <= JMP_NOP;
			wbop_saved  <= WB_NOP;
			
			pc_in_saved <= (others => '0');
			op_saved <= EXEC_NOP;
			memop_out <= MEM_NOP;
			jmpop_out <= JMP_NOP;
			--wbop_out  <= WB_NOP;
			memop_saved <= MEM_NOP;
			jmpop_saved <= JMP_NOP;
			wbop_saved  <= WB_NOP;
			cop0op_saved <= COP0_NOP;
			cop0_read_reg_saved <= (others => '0');

			flush_lat <= '0';
			
		elsif rising_edge(clk) then
		
			flush_lat <= flush;
			if flush = '1' then
			
				pc_in_saved <= pc_in; -- TODO
				op_saved <= EXEC_NOP;
				memop_out <= MEM_NOP;
				jmpop_out <= JMP_NOP;
				--wbop_out  <= WB_NOP;
				memop_saved <= MEM_NOP;
				jmpop_saved <= JMP_NOP;
				wbop_saved  <= WB_NOP;
				cop0op_saved <= COP0_NOP;
				cop0_read_reg_saved <= (others => '0');
				
			elsif stall = '0' then
			
				pc_in_saved <= pc_in;
				op_saved <= op;
				memop_out <= memop_in;
				jmpop_out <= jmpop_in;
				--wbop_out  <= wbop_out_prepare;
				memop_saved <= memop_in;
				jmpop_saved <= jmpop_in;
				wbop_saved  <= wbop_in;
				cop0op_saved <= cop0_op_in;
				cop0_read_reg_saved <= cop0_read_reg_in;
								
			end if;



	
		end if;
	
	end process;


end rtl;
