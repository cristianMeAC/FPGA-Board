library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

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
		pc_out     : out std_logic_vector(PC_WIDTH-1 downto 0);
		exec_op    : out exec_op_type;
		cop0_op    : out cop0_op_type;
		jmp_op     : out jmp_op_type;
		mem_op     : out mem_op_type;
		wb_op      : out wb_op_type;
		exc_dec    : out std_logic);

end decode;

architecture rtl of decode is

begin  -- rtl

    
	prepare_regfile_addresses : process(all)
	-- prepare addresses to be ready on next rising clock
	-- addresses are valid before the rising clock (just after the 
	-- previous rising clock) so we can read them asynchronously
	
	
	begin
		-- done here because we have to read before instr gets latched to
		-- instr_saved, so we read directly from instr
		

    
    case instr(INSTR_WIDTH - 1 downto OPCODE_END) is
    
        when OP_SPEC => -- (R) special instructions(Table 3.7) Mimi special instr
        
            case instr(SHAMT_END - 1 downto 0 ) is
        
                when RF_SLL => -- SLL rd, rs, shamt

                    if (instr = (0 to INSTR_WIDTH - 1 => '0') ) then
                        -- NOP
                        rdaddr1 <= (others => '0');
                        rdaddr2 <= (others => '0');
                    else
                        rdaddr1 <= instr(RS_END - 1 downto RT_END); -- get rt
                        rdaddr2 <= (others => '0');
                    end if;  
                    
                when SRL => -- SRL rd, rt, shamt
                    
                    rdaddr1 <= instr(RS_END - 1 downto RT_END);  -- get rt
                    rdaddr2 <= (others => '0');
                
                when SRA => -- SRA  rd, rt, shamt
                
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

                when JR => -- JR   rs
                
                    rdaddr1 <= instr(OPCODE_END-1 downto RS_END); -- get rs
				    rdaddr2 <= (others => '0');
                
                when JALR =>
                
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
            
            -- TODO currently NOPs
            case instr(OPCODE_END-1 downto RS_END) is
                when CI_MFC0 => -- MFC0 rt, rd
                    rdaddr1 <= (others => '0');
                    rdaddr2 <= (others => '0');
                when CI_MTC0 => -- MTC0 rt, rd
                    rdaddr1 <= (others => '0');
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
        -- end from opcode Case

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
            
            
        -- lese ich
		rddata1_b := rddata1;
		rddata2_b := rddata2;  
        
        -- decode opcode
		case instr_saved(INSTR_WIDTH-1 downto OPCODE_END) is
        
			when OP_SPEC   => -- (R) special instructions
                
                case instr_saved(SHAMT_END-1 downto 0) is
                
                     when RF_SLL  => -- SLL  rd, rt, shamt
                    
            
            
            
            
                    
            
            
            
            
                    
            
            
            
            
                    
            
            
            
            
        
        
    

end rtl;
