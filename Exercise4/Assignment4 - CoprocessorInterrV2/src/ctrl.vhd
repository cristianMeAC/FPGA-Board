 library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity ctrl is
	
	port (
		-- define input and output ports as needed
		clk, reset : in std_logic;
		stall : in std_logic;
		pcsrc_in : in std_logic;
		pc_j_in : in std_logic_vector(PC_WIDTH-1 downto 0);
		pcsrc_out : out std_logic;
		flush : out std_logic;
		pc_j_out : out std_logic_vector(PC_WIDTH-1 downto 0);
		
		
		
			
		op : in cop0_op_type;
		exc_load : in std_logic;
		exc_store : in std_logic;
		exc_dec : in std_logic;
		exc_ovf : in std_logic;
		aluresult_exec : in std_logic_vector(DATA_WIDTH-1 downto 0);
		mem_jmpop : in jmp_op_type;
		exec_jmpop : in jmp_op_type;
		exec_epc : in std_logic_vector(PC_WIDTH-1 downto 0);
		mem_epc  : in std_logic_vector(PC_WIDTH-1 downto 0);
		dec_epc  : in std_logic_vector(PC_WIDTH-1 downto 0);
		read_reg : in std_logic_vector(REG_BITS-1 downto 0);
		intr : in std_logic_vector(INTR_COUNT-1 downto 0);

		cop0_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
		flush_exec : out std_logic;
		flush_mem : out std_logic;
		flush_wb : out std_logic
		
);

end ctrl;

architecture rtl of ctrl is

	constant ADDR_STATUS : std_logic_vector(REG_BITS-1 downto 0) := "01100";
	constant ADDR_CAUSE  : std_logic_vector(REG_BITS-1 downto 0) := "01101";
	constant ADDR_EPC    : std_logic_vector(REG_BITS-1 downto 0) := "01110";
	constant ADDR_NPC    : std_logic_vector(REG_BITS-1 downto 0) := "01111";
	
	constant EX_INT : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	constant EX_LD  : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000010";
	constant EX_ST  : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000014";
	constant EX_DEC : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000028";
	constant EX_OVF : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000030";

	signal pc_j_lat : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0'); 
	signal pc_j_lat_two_clk  : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0'); 
	signal pc_j_lat_thr_clk  : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0'); 
	signal pcsrc_lat : std_logic := '0';
	signal pcsrc_lat_two_clk : std_logic := '0';
	signal pcsrc_lat_thr_clk : std_logic := '0';
	
	signal op_saved : cop0_op_type := COP0_NOP;

	signal exc_dec_lat : std_logic := '0';
	signal exec_jmpop_lat : jmp_op_type := JMP_NOP;
	signal dec_epc_lat : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');

	signal status : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000001"; -- enable interrupts--(others => '0');
	signal status_lat : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000001";
	signal status_lat_two_clk : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000001";
	signal cause  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal cause_lat  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal epc    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal npc    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal mem_jmpop_lat : jmp_op_type := JMP_NOP;
	signal cause_q : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal status_q : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal npc_q : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
	
	signal br_del_dec_b_q : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal br_del_dec_b_lat : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	signal flush_lat : std_logic := '0';
	signal flush_q : std_logic := '0';

	signal cons_interrupts : std_logic := '0';
	signal cons_interrupts_prev : std_logic := '0';

	signal npc_saved : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal epc_saved : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin  -- rtl




	prepare_output : process(all)
	
	variable cause_b : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	variable status_b : std_logic_vector(DATA_WIDTH-1 downto 0);
	variable br_del_ex_b : std_logic_vector(DATA_WIDTH-1 downto 0);
	variable br_del_mem_b : std_logic_vector(DATA_WIDTH-1 downto 0);
	variable br_del_dec_b : std_logic_vector(DATA_WIDTH-1 downto 0);
	variable pcsrc_out_b : std_logic;
	variable pc_j_out_b : std_logic_vector(PC_WIDTH-1 downto 0);
	variable flush_b : std_logic;
	variable flush_exec_b : std_logic;
	variable flush_mem_b : std_logic;
	variable flush_wb_b  : std_logic;
	variable npc_b : std_logic_vector(PC_WIDTH-1 downto 0);
	begin


		cause_b := cause;
		--cause_b := (others => '0');		
		status_b := status;-- status;

		--cons_interrupts <= cons_interrupts_prev;
		--if status_b(0) = '1' then
			
            cons_interrupts <= cons_interrupts_prev;
			
            -- kommt ein Interrupt, vorher war hier 0 .........wenn vorherige Interrupt '0' ist 
            if (intr(0) = '1' and cause_lat(10) = '0') or (intr(0) = '1' and status(0) = '1') then
				cause_b(10) := '1';
				
            -- sagt uns dass wir Interrupts haben
                cons_interrupts <= '1';
			end if;
	
			if (intr(1) = '1' and cause_lat(11) = '0') or (intr(1) = '1' and status(0) = '1') then
				cause_b(11) := '1';
				cons_interrupts <= '1';
			end if;


			if (intr(2) = '1' and cause_lat(12) = '0') or (intr(2) = '1' and status(0) = '1') then
				cause_b(12) := '1';
				cons_interrupts <= '1';
			end if;

			/*cons_interrupts <= cons_interrupts_prev;
            
         --  3 cycles auf status '1' waren
			if cause_b(12 downto 10) = "000" and status(0) = '1' and status_lat(0) = '1' and status_lat_two_clk(0) = '1' then
				cons_interrupts <= '0';
			end if;
		--end if;

		/*br_del_ex_b := x"80000000" when (mem_jmpop = JMP_JMP or mem_jmpop = JMP_BEQ or
			mem_jmpop = JMP_BNE or mem_jmpop = JMP_BLEZ or mem_jmpop = JMP_BGTZ or
			mem_jmpop = JMP_BLTZ or mem_jmpop = JMP_BGEZ) else x"00000000"; */
			
		if (mem_jmpop = JMP_JMP or mem_jmpop = JMP_BEQ or
			mem_jmpop = JMP_BNE or mem_jmpop = JMP_BLEZ or mem_jmpop = JMP_BGTZ or
			mem_jmpop = JMP_BLTZ or mem_jmpop = JMP_BGEZ) then
			br_del_ex_b := x"80000000";	
		
		else
			br_del_ex_b := x"00000000";
		end if;
		
		/*br_del_mem_b := x"80000000" when (mem_jmpop_lat = JMP_JMP or mem_jmpop_lat = JMP_BEQ or
			mem_jmpop_lat = JMP_BNE or mem_jmpop_lat = JMP_BLEZ or mem_jmpop_lat = JMP_BGTZ or
			mem_jmpop_lat = JMP_BLTZ or mem_jmpop_lat = JMP_BGEZ) else x"00000000";*/
		
		if (mem_jmpop_lat = JMP_JMP or mem_jmpop_lat = JMP_BEQ or
			mem_jmpop_lat = JMP_BNE or mem_jmpop_lat = JMP_BLEZ or mem_jmpop_lat = JMP_BGTZ or
			mem_jmpop_lat = JMP_BLTZ or mem_jmpop_lat = JMP_BGEZ) then
			
			br_del_mem_b := x"80000000";
		
		else
			br_del_mem_b := x"00000000";
		end if;
		
		if (exec_jmpop = JMP_JMP or exec_jmpop = JMP_BEQ or
			exec_jmpop = JMP_BNE or exec_jmpop = JMP_BLEZ or exec_jmpop = JMP_BGTZ or
			exec_jmpop = JMP_BLTZ or exec_jmpop = JMP_BGEZ) then
			br_del_dec_b := x"80000000";	
		
		else
			br_del_dec_b := x"00000000";
		end if;
		
		pcsrc_out_b := '0';
		pc_j_out_b := (others => '0');
		flush_b := '0';
		flush_exec_b := '0';
		flush_mem_b := '0';
		flush_wb_b := '0';
		npc_b := (others => '0');
		
		
		if exc_ovf = '1' then
		
			cause_b := br_del_ex_b(31) & cause_b(30 downto 6) & EX_OVF(5 downto 2) & "00";
			--cause_b := cause_b or br_del_ex_b or EX_OVF;
			pcsrc_out_b := '1';
			pc_j_out_b := EXCEPTION_PC;
			flush_b := '1';
			flush_exec_b := '1';
			flush_mem_b := '1';
			--npc_b := pc_j_in when br_del_ex_b = x"80000000" else std_logic_vector(unsigned(exec_epc) + to_unsigned(4, PC_WIDTH));
			if br_del_ex_b = x"80000000" and pcsrc_in = '1' then
				npc_b := pc_j_in;
			elsif br_del_ex_b = x"80000000" and pcsrc_in = '0' then
				npc_b := exec_epc;
				--npc_b := std_logic_vector(unsigned(exec_epc) - to_unsigned(4, PC_WIDTH));
			else
				--npc_b := std_logic_vector(unsigned(exec_epc) + to_unsigned(4, PC_WIDTH));
				npc_b := exec_epc;
			end if;
			
		elsif exc_load = '1' then
			
			cause_b := br_del_mem_b(31) & cause_b(30 downto 6) & EX_LD(5 downto 2) & "00";
			--cause_b := cause_b or br_del_mem_b or EX_LD;
			pcsrc_out_b := '1';
			pc_j_out_b := EXCEPTION_PC;
			flush_b := '1';
			flush_exec_b := '1';
			flush_mem_b := '1';
			flush_wb_b := '1';
			--npc_b := pc_j_lat when br_del_mem_b = x"80000000" else std_logic_vector(unsigned(mem_epc) + to_unsigned(4, PC_WIDTH));
			if br_del_mem_b = x"80000000" and pcsrc_lat = '1' then
				npc_b := pc_j_lat;
			elsif br_del_mem_b = x"80000000" and pcsrc_lat = '0' then
				npc_b := mem_epc;
			else
				--npc_b := std_logic_vector(unsigned(mem_epc) + to_unsigned(4, PC_WIDTH));
				npc_b := mem_epc;
			end if;
		
		 
		elsif exc_store = '1' then
		
			cause_b := br_del_mem_b(31) & cause_b(30 downto 6) & EX_ST(5 downto 2) & "00";
			--cause_b := cause_b or br_del_mem_b or EX_ST;
			pcsrc_out_b := '1';
			pc_j_out_b := EXCEPTION_PC;
			flush_b := '1';
			flush_exec_b := '1';
			flush_mem_b := '1';
			flush_wb_b := '1';
			--npc_b := pc_j_lat when br_del_mem_b = x"80000000" else std_logic_vector(unsigned(mem_epc) + to_unsigned(4, PC_WIDTH));
			if br_del_mem_b = x"80000000" and pcsrc_lat = '1' then
				npc_b := pc_j_lat;
			elsif br_del_mem_b = x"80000000" and pcsrc_lat = '0' then
				npc_b := mem_epc;
			else
				--npc_b := std_logic_vector(unsigned(mem_epc) + to_unsigned(4, PC_WIDTH));
				npc_b := mem_epc;
			end if;
			
		--elsif pcsrc_lat_two_clk = '0' and pcsrc_lat_thr_clk = '0' and ((exc_dec = '1' and br_del_dec_b = x"00000000") or (exc_dec_lat = '1' and br_del_dec_b_lat = x"80000000")) then
		elsif  ((pcsrc_in = '0' and pcsrc_lat = '0' and exc_dec = '1' and br_del_dec_b = x"00000000") or (exc_dec_lat = '1' and br_del_dec_b_lat = x"80000000")) then
			-- we need to make sure that the exception does not get triggered by instructions that are in slot
			-- 2 and 3 after the branch, that will get flushed anyway
			cause_b := br_del_dec_b_lat(31) & cause_b(30 downto 6) & EX_DEC(5 downto 2) & "00";
			--cause_b := cause_b or EX_DEC or br_del_dec_b_lat;
			pcsrc_out_b := '1';
			pc_j_out_b := EXCEPTION_PC;
			--npc_b := dec_epc;
			
			flush_b := '1';
			if br_del_dec_b_lat = x"80000000" then
				--flush_b := '1';
				flush_exec_b := '1';
				flush_mem_b := '1';
			end if;
			
			-- TODO: 
			if br_del_dec_b_lat = x"80000000" and pcsrc_in = '1' then
					npc_b := pc_j_in;
			elsif br_del_dec_b_lat = x"80000000" and pcsrc_in = '0' then
					npc_b := dec_epc_lat;
			else
					npc_b := dec_epc;
			end if;
 			
		elsif ((cause_b(12 downto 10) /= "000" and status(0) = '1')) then
			status_b := (others => '0');
			cause_b(31) := '0';
			cause_b(5 downto 2) := (others => '0');
			cause_b := cause_b or EX_INT; --or br_del_dec_b;
			pcsrc_out_b := '1';
			pc_j_out_b := EXCEPTION_PC;

			flush_b := '1';
			flush_exec_b := '1';
			flush_mem_b := '1';
			flush_wb_b := '1';
            
            
        -- wenn vorher ein Sprug passiert ist und wenn wir kein Intrerr passiert sind
			if pcsrc_lat = '1' and cons_interrupts_prev = '0' then
				--npc_b := std_logic_vector(unsigned(mem_epc) - to_unsigned(4, PC_WIDTH));
				npc_b := mem_epc;
				
				cause_b := x"80000000" or cause_b;
         -- wenn vor 2 cycles ein Sprung passiert ist, nehmen wir was im Mem da war; wir sind in Mem
            elsif pcsrc_lat_two_clk = '1' then
				npc_b := pc_j_lat_two_clk;
			--elsif pcsrc_lat_thr_clk = '1'
			else
				
				npc_b := mem_epc;
				--cause_b := x"7fffffff" and cause_b;
			end if;

		else
			
			--cause_b := (others => '0');
			
			pcsrc_out_b := pcsrc_in;
			pc_j_out_b := pc_j_in;
			--flush_b := pcsrc_in or pcsrc_lat;
			flush_b := pcsrc_in;
			flush_exec_b := pcsrc_in;
		
		end if;
	
		cause_q <= cause_b;
		status_q <= status_b;
		pcsrc_out <= pcsrc_out_b;
		pc_j_out <= pc_j_out_b;
		flush_q <= flush_b;
		--flush <= flush_q or flush_lat;
		flush <= flush_q;
		flush_wb <= flush_wb_b;
		flush_exec <= flush_exec_b;
		flush_mem <= flush_mem_b;
		npc_q <= npc_b;
		br_del_dec_b_q <= br_del_dec_b;
		
	end process;
	



	process(all)
	begin
		
		if reset = '0' then
		
			-- TODO reset all (latched) signals
			pcsrc_lat <= '0';
			pcsrc_lat_two_clk <= '0';
			pcsrc_lat_thr_clk <= '0';
			pc_j_lat <= (others => '0');
			op_saved <= COP0_NOP;
			mem_jmpop_lat <= JMP_NOP;
			cop0_data <= (others => '0');
			--npc_q <= (others => '0');
			status <= x"00000001";--(others => '0');
			cause <= (others => '0');
			epc <= (others => '0');
			npc <= (others => '0');
			
		elsif rising_edge(clk) then
		
			cause <= cause_q;

			if stall = '0' then
				pcsrc_lat <= pcsrc_in;
				pcsrc_lat_two_clk <= pcsrc_lat;
				pcsrc_lat_thr_clk <= pcsrc_lat_two_clk;

				pc_j_lat <= pc_j_in;
				pc_j_lat_two_clk <= pc_j_lat;
				pc_j_lat_thr_clk <= pc_j_lat_two_clk;

				op_saved <= op;
				mem_jmpop_lat <= mem_jmpop;
				flush_lat <= flush_q;
				
				br_del_dec_b_lat <= br_del_dec_b_q;
				
				exc_dec_lat <= exc_dec;
				exec_jmpop_lat <= exec_jmpop; -- TODO: remove
				
				dec_epc_lat <= dec_epc;

				cons_interrupts_prev <= cons_interrupts;


            -- cand lucram la un Interrupt sa beheben nu vrem sa reapara(wird der Wert von cause gepseichert bis ende vo Exception Handling Routine)
            -- cause_lat, bleibt gleich fuer die ganze Exception Handling routine 
				if status_lat_two_clk(0) = '1' then
					cause_lat <= cause;
				end if;

				if status(0) = '1' then
					cause_lat <= cause;
				end if;

				status_lat <= status;
				status_lat_two_clk <= status_lat;

			-- wenn auf der Rising Edge ein Interrupt kommt 
				if cons_interrupts_prev = '0' and cons_interrupts = '1'then
					if pcsrc_lat_two_clk = '1' then
					  epc_saved <= std_logic_vector(unsigned(("00" & x"0000" & pc_j_lat_two_clk)) - to_unsigned(4, PC_WIDTH));
					  npc_saved <= std_logic_vector(unsigned(("00" & x"0000" & pc_j_lat_two_clk)) - to_unsigned(4, PC_WIDTH));
					else
					  epc_saved <= std_logic_vector(unsigned(("00" & x"0000" & mem_epc)) - to_unsigned(4, PC_WIDTH));
					  npc_saved <= std_logic_vector(unsigned(("00" & x"0000" & mem_epc)) - to_unsigned(4, PC_WIDTH));
					end if;
				end if;
			
				
				--cause <= cause_q;
				if exc_ovf = '1' then
				
					epc <= std_logic_vector(unsigned(("00" & x"0000" & exec_epc)) - to_unsigned(4, PC_WIDTH));
					cause <= cause_q;
					--npc <= std_logic_vector(unsigned(( "00" & x"0000" & npc_q)) - to_unsigned(4, PC_WIDTH)); --( "00" & x"0000" & npc_q);
					npc <= ("00" & x"0000" & npc_q);
			
				elsif exc_store = '1' or exc_load = '1' then
					
					epc <= std_logic_vector(unsigned(("00" & x"0000" & mem_epc)) - to_unsigned(4, PC_WIDTH));
					cause <= cause_q;
					npc <= ("00" & x"0000" & npc_q);
					
				--elsif pcsrc_lat_two_clk = '0' and pcsrc_lat_thr_clk = '0' and ((exc_dec = '1' and br_del_dec_b_q = x"00000000") or (exc_dec_lat = '1' and br_del_dec_b_lat = x"80000000")) then
				elsif ((pcsrc_in = '0' and pcsrc_lat = '0' and  exc_dec = '1' and br_del_dec_b_q = x"00000000") or (exc_dec_lat = '1' and br_del_dec_b_lat = x"80000000")) then
					if br_del_dec_b_lat = x"80000000" then
					  epc <= std_logic_vector(unsigned(("00" & x"0000" & dec_epc_lat)) - to_unsigned(4, PC_WIDTH));
					else
					  epc <= std_logic_vector(unsigned(("00" & x"0000" & dec_epc)) - to_unsigned(4, PC_WIDTH));
					end if;
					cause <= cause_q;
					npc <= ("00" & x"0000" & npc_q); 
                    
            -- 
				elsif (cause_q(12 downto 10) /= "000" and status(0) = '1') then
					--status <= status_q;
					status <= (others => '0');
					cause <= cause_q;
            -- wir behadeln Interr(2-te condition) oder wir sind auf Falling Edge(wir habenn ein Interr erledigt)
					if (cons_interrupts = '0' and cons_interrupts_prev = '1') or (cons_interrupts = '1' and cons_interrupts_prev = '1') then
						epc <= epc_saved;
						npc <= epc_saved;
					else
						epc <= std_logic_vector(unsigned(("00" & x"0000" & npc_q)) - to_unsigned(4, PC_WIDTH));
						npc <= std_logic_vector(unsigned(("00" & x"0000" & npc_q)) - to_unsigned(4, PC_WIDTH));
					end if;
				else
					

					if op_saved.wr = '1' then
				
						case op_saved.addr is
							when ADDR_STATUS =>
								status <= aluresult_exec;
							when ADDR_CAUSE =>
								cause <= aluresult_exec;
							when ADDR_EPC =>
								epc <= aluresult_exec;
							when ADDR_NPC =>
								npc <= aluresult_exec;
							when others =>
								-- nothing
						end case;

						case read_reg is
							when ADDR_STATUS =>
								cop0_data <= aluresult_exec;
							when ADDR_CAUSE =>
								cop0_data <= aluresult_exec;
							when ADDR_EPC =>
								cop0_data <= aluresult_exec;
							when ADDR_NPC =>
								cop0_data <= aluresult_exec;
							when others => 
								cop0_data <= (others => '0');
						end case;

					else

						case read_reg is
							when ADDR_STATUS =>
								cop0_data <= status;
							when ADDR_CAUSE =>
								cop0_data <= cause;
							when ADDR_EPC =>
								cop0_data <= epc;
							when ADDR_NPC =>
								cop0_data <= npc;
							when others => 
								cop0_data <= (others => '0');
						end case;
					
					
					end if;
				end if;
				
				/*
				case read_reg is
					when ADDR_STATUS =>
						cop0_data <= status;
					when ADDR_CAUSE =>
						cop0_data <= cause;
					when ADDR_EPC =>
						cop0_data <= epc;
					when ADDR_NPC =>
						cop0_data <= npc;
					when others => 
						cop0_data <= (others => '0');
				end case;*/

			end if;
		
		end if;
	
	end process;

end rtl;
