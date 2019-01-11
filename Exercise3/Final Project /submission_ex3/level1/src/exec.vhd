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
		mem_aluresult    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_result        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		exc_ovf          : out std_logic);

end exec;

architecture rtl of exec is


	signal pc_in_saved : std_logic_vector(PC_WIDTH-1 downto 0) := 
														(others => '0');
	signal op_saved : exec_op_type  := EXEC_NOP;
	signal memop_saved : mem_op_type := MEM_NOP;
	signal jmpop_saved : jmp_op_type := JMP_NOP;
	signal wbop_saved  : wb_op_type  := WB_NOP;

	signal alu_op : alu_op_type := ALU_NOP;
	signal alu_A  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal alu_B  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal alu_R  : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal alu_Z  : std_logic;
	signal alu_V  : std_logic;
	
	constant PC_FOUR : std_logic_vector(PC_WIDTH-1 downto 0) := (2 => '1', others => '0');
	

begin  -- rtl

	alu_inst : entity work.alu
	port map(
        op => alu_op, 
        A => alu_A, 
        B => alu_B, 
        R => alu_R, 
        Z => alu_Z,
        V => alu_V);

	prepare_output : process(all)

	variable alu_op_use : alu_op_type := ALU_NOP;
	variable alu_A_use  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	variable alu_B_use  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	variable pc_out_use : std_logic_vector(PC_WIDTH-1 downto 0);
	variable rd_use, rs_use, rt_use : std_logic_vector(REG_BITS-1 downto 0);
	variable new_pc_use : std_logic_vector(PC_WIDTH-1 downto 0);
	variable new_pc_prepare : std_logic_vector(PC_WIDTH-1 downto 0);
	variable pc_incr_prepare : std_logic_vector(PC_WIDTH-1 downto 0);
	
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

    -- wir schauen alu_op von decode
		case op_saved.aluop is
			when ALU_NOP  =>		-- R = A
            
            -- alle moegliche Instr
				-- (R) instruction : NOP, JR
				-- (J) instruction : J
				
				if jmpop_saved = JMP_NOP then
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
                    
                -- JR verwendet nicht useimm und J verwendet es
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
                        
                    -- normale Abfolge    
						pc_out_use := pc_in_saved;
                        
                    -- wirt dort gesprungen in mem
						new_pc_use := op_saved.imm(PC_WIDTH-1 downto 0);
					
					end if;
					
				end if;
                
        -- was er eigentlich machen soll(pe randul 2)        
			when ALU_LUI  =>		-- R = B sll 16
				-- (I) instruction: LUI
				
				alu_op_use := ALU_LUI;
				alu_A_use := (others => '0');
        
        -- wir lesen von imm weil decode so vorbereitet hat    
				alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
				rs_use := op_saved.rs;
				rt_use := op_saved.rt;
				rd_use := op_saved.rt; -- Dest is rt
				
            -- beide sind JumPunit entscheidet ob er sprungen soll    
            -- wenn kein Sprung passiert    
                pc_out_use := pc_in_saved;
				
            -- was passier wenn er gesprungen wird
                new_pc_use := pc_in_saved;
				
			when ALU_SLT  =>		-- R = A < B ? 1 : 0, signed
				-- (R) instruction: SLT
				-- (I) instruction: SLTI
				
				if op_saved.useimm = '0' then -- SLT
				
					alu_op_use := ALU_SLT;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- SLTI
				
					alu_op_use := ALU_SLT;
					alu_A_use := op_saved.readdata1; -- rs
					if op_saved.imm(15) = '0' then -- if positive then fill left with 0s
						alu_B_use := (others => '0');
					else 						-- if negative then fill left with 1s
						alu_B_use := (others => '1');
					end if;
					alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_SLTU =>		-- R = A < B ? 1 : 0, unsigned
				-- (R) instruction: SLTU
				-- (I) instruction: SLTIU
				
				if op_saved.useimm = '0' then -- SLTU
				
					alu_op_use := ALU_SLTU;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- SLTIU
				
					alu_op_use := ALU_SLTU;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_SLL  =>		-- R = B sll A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SLL, SLLV
				
				if op_saved.useamt = '0' then -- SLLV
					
					alu_op_use := ALU_SLL;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- SLL
				
					alu_op_use := ALU_SLL;
					alu_A_use := op_saved.imm; -- shamt
					alu_B_use := op_saved.readdata1; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_SRL  =>		-- R = B srl A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SRL, SRLV
				
				if op_saved.useamt = '0' then -- SRLV
					
					alu_op_use := ALU_SRL;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- SRL
				
					alu_op_use := ALU_SRL;
					alu_A_use := op_saved.imm; -- shamt
					alu_B_use := op_saved.readdata1; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_SRA  =>		-- R = B sra A(DATA_WIDTH_BITS-1 downto 0)
				-- (R) instruction: SRA, SRAV
				
				if op_saved.useamt = '0' then -- SRAV
					
					alu_op_use := ALU_SRA;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- SRA
				
					alu_op_use := ALU_SRA;
					alu_A_use := op_saved.imm; -- shamt
					alu_B_use := op_saved.readdata1; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_ADD  =>		-- R = A + B
				-- (R) instruction: JALR, ADD, ADDU
				-- (I) instruction: ADDI, ADDIU, LB, LH, LW, LBU, LHU, SB, SH, SW
				-- (J) instruction: JAL
				
            -- von register gelesen wird
				if wbop_saved.memtoreg = '0' then
					-- JALR, ADD, ADDU, ADDI, ADDIU, JAL, SB, SH, SW
					
            -- von Speciher gelesen wird
					if memop_saved.memwrite = '0' then
						-- JALR, ADD, ADDU, ADDI, ADDIU, JAL
						
						if op_saved.link = '0' then
							-- ADD, ADDU, ADDI, ADDIU
							if op_saved.useimm = '0' then
								-- ADD, ADDU
								
								alu_op_use := ALU_ADD;
								alu_A_use := op_saved.readdata1;
								alu_B_use := op_saved.readdata2;
								rs_use := op_saved.rs;
								rt_use := op_saved.rt;
								rd_use := op_saved.rd;
								pc_out_use := pc_in_saved;
								new_pc_use := pc_in_saved;
								
							else
								-- ADDI, ADDIU
								
								alu_op_use := ALU_ADD;
								alu_A_use := op_saved.readdata1;
								alu_B_use := op_saved.imm;
								rs_use := op_saved.rs;
								rt_use := op_saved.rt;
								rd_use := op_saved.rt; -- Dist is rt
								pc_out_use := pc_in_saved;
								new_pc_use := pc_in_saved;
								
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
						alu_A_use := op_saved.readdata1;
						if op_saved.imm(15) = '0' then -- if positive then fill left with 0s
							alu_B_use := (others => '0');
						else 						-- if negative then fill left with 1s
							alu_B_use := (others => '1');
						end if;
						alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
						rs_use := op_saved.rs;
						rt_use := op_saved.rt;
						rd_use := op_saved.rd;
						pc_out_use := pc_in_saved;
						new_pc_use := pc_in_saved;
						
					end if;
				
				else
					-- LB, LH, LW, LBU, LHU
					
					alu_op_use := ALU_ADD;
					alu_A_use := op_saved.readdata1;
					if op_saved.imm(15) = '0' then -- if positive then fill left with 0s
						alu_B_use := (others => '0');
					else 						-- if negative then fill left with 1s
						alu_B_use := (others => '1');
					end if;
					alu_B_use(15 downto 0) := op_saved.imm(15 downto 0);
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dist is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				end if;
				
			when ALU_SUB  =>		-- R = A - B
				-- (R) instruction: SUB, SUBU
				-- (I) instruction: BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ, BLTZAL, BGEZAL
				
				if op_saved.branch = '0' then
					-- SUB and SUBU
					
					alu_op_use := ALU_SUB;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else
					-- BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ, BLTZAL, BGEZAL
					
					if op_saved.link = '0' then
						-- BEQ and BNE
						
						if jmpop_saved = JMP_BEQ or jmpop_saved = JMP_BNE then
							
							alu_op_use := ALU_SUB;
							alu_A_use := op_saved.readdata1; -- rs
							alu_B_use := op_saved.readdata2; -- rt
							rs_use := op_saved.rs;
							rt_use := op_saved.rt;
							-- rd_use := op_saved.rd; -- nothing will be saved
							pc_out_use := pc_in_saved;
							new_pc_use := new_pc_prepare;
							
						else
							-- BLTZ, BGEZ, BLEZ, BGTZ
							
							alu_op_use := ALU_SUB;
							alu_A_use := op_saved.readdata1; -- rs
							alu_B_use := (others => '0');
							rs_use := op_saved.rs;
							rt_use := op_saved.rt;
							rd_use := op_saved.rd;
							pc_out_use := pc_in_saved;
							new_pc_use := new_pc_prepare;
						
						end if;
						
					else
						-- BLTZAL, BGEZAL
						
						alu_op_use := ALU_SUB;
						alu_A_use := op_saved.readdata1; -- rs
						alu_B_use := (others => '0');
						rs_use := op_saved.rs;
						rt_use := op_saved.rt;
						rd_use := op_saved.rt; -- Dest is rt
						pc_out_use := pc_in_saved;
						new_pc_use := new_pc_prepare;
						
					end if;
					
				end if;
				
			when ALU_AND  =>		-- R = A and B
				-- (R) instruction: AND
				-- (I) instruction: ANDI
				
				if op_saved.useimm = '0' then -- AND
					
					alu_op_use := ALU_AND;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- ANDI
				
					alu_op_use := ALU_AND;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_OR   =>		-- R = A or B
				-- (R) instruction: OR
				-- (I) instruction: ORI
				
				if op_saved.useimm = '0' then -- OR
					
					alu_op_use := ALU_OR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- ORI
				
					alu_op_use := ALU_OR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_XOR  =>		-- R = A xor B
				-- (R) instruction: XOR
				-- (I) instruction: XORI
				
				if op_saved.useimm = '0' then -- XOR
					
					alu_op_use := ALU_XOR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.readdata2; -- rt
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rd;
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
					
				else -- XORI
				
					alu_op_use := ALU_XOR;
					alu_A_use := op_saved.readdata1; -- rs
					alu_B_use := op_saved.imm;
					rs_use := op_saved.rs;
					rt_use := op_saved.rt;
					rd_use := op_saved.rt; -- Dest is rt
					pc_out_use := pc_in_saved;
					new_pc_use := pc_in_saved;
				
				end if;
				
			when ALU_NOR  =>		-- R = not (A or B)
				-- (R) instruction: NOR
				
				alu_op_use := ALU_NOR;
				alu_A_use := op_saved.readdata1; -- rs
				alu_B_use := op_saved.readdata2; -- rt
				rs_use := op_saved.rs;
				rt_use := op_saved.rt;
				rd_use := op_saved.rd;
				pc_out_use := pc_in_saved;
				new_pc_use := pc_in_saved;	
				
			when others   =>
				-- impossible
		
		
		end case;


		alu_op <= alu_op_use;
		alu_A  <= alu_A_use;
		alu_B  <= alu_B_use;
		pc_out <= pc_out_use;
		rd <= rd_use;
		rs <= rs_use;
		rt <= rt_use;
		
    -- fuer branch and linked commands BLTZAL    
        if op_saved.aluop = ALU_SUB and op_saved.link = '1' and op_saved.branch = '1' then -- if we have branch and link command, we have to set aluresult to pc+4 (pc_incr_prepare)
			aluresult(PC_WIDTH-1 downto 0) <= pc_incr_prepare;  -- 
			aluresult(DATA_WIDTH-1 downto PC_WIDTH) <= (others => '0');
			
		-- elsif -- TODO for cop0 commands
		
		else -- otherwise, the aluresult is the actual result from ALU
			aluresult <= alu_R;
		end if; 
	-- leiten wir direct von ALU	
		zero      <= alu_Z;
		neg       <= alu_R(DATA_WIDTH-1); -- negative flag corresponds to the left-most bit of the result
		new_pc    <= new_pc_use;		
		
    -- overflow, wenn decode sagt zBsp beim ADDI    
        if op_saved.ovf = '1' then -- if overflow trap is enabled, we set overflow output to ALU's overflow flag
			exc_ovf <= alu_V;
		else -- otherwise, overflow is disabled
			exc_ovf <= '0';
		end if;
		
    -- hier erkennen wir dass ein STORE ist    
		if op_saved.aluop = ALU_ADD and wbop_saved.memtoreg = '0' and memop_saved.memwrite = '1' then -- in case of store commands, the value to be written to memory is in rd register
			wrdata <= op_saved.readdata2; -- value of rd register
		else -- otherwise we write nothing to memory
			wrdata <= (others => '0');
		end if;


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
			wbop_out  <= WB_NOP;
			memop_saved <= MEM_NOP;
			jmpop_saved <= JMP_NOP;
			wbop_saved  <= WB_NOP;
			
		elsif rising_edge(clk) then
		
			if flush = '1' then
			
				pc_in_saved <= pc_in; -- TODO
				op_saved <= EXEC_NOP;
				memop_out <= MEM_NOP;
				jmpop_out <= JMP_NOP;
				wbop_out  <= WB_NOP;
				memop_saved <= MEM_NOP;
				jmpop_saved <= JMP_NOP;
				wbop_saved  <= WB_NOP;
				
			elsif stall = '0' then
			
				pc_in_saved <= pc_in;
				op_saved <= op;
				memop_out <= memop_in;
				jmpop_out <= jmpop_in;
				wbop_out  <= wbop_in;
				memop_saved <= memop_in;
				jmpop_saved <= jmpop_in;
				wbop_saved  <= wbop_in; 
								
			end if;



	
		end if;
	
	end process;


end rtl;
