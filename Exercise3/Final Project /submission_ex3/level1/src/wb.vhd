library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity wb is
	
	port (
		clk, reset : in  std_logic;
		stall      : in  std_logic;
		flush      : in  std_logic;
		op	   	   : in  wb_op_type;
		rd_in      : in  std_logic_vector(REG_BITS-1 downto 0);
		aluresult  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		memresult  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		rd_out     : out std_logic_vector(REG_BITS-1 downto 0);
		result     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		regwrite   : out std_logic);

end wb;

architecture rtl of wb is


	signal aluresult_saved : std_logic_vector(DATA_WIDTH-1 downto 0) :=
															(others => '0');
	signal memresult_saved : std_logic_vector(DATA_WIDTH-1 downto 0) :=
															(others => '0');
	signal rd_in_saved  : std_logic_vector(REG_BITS-1 downto 0) :=
															(others => '0');
	signal op_saved     : wb_op_type := WB_NOP;

begin  -- rtl
	
	
	prepare_output : process(all)
	variable result_b   : std_logic_vector(DATA_WIDTH-1 downto 0) := 
															(others => '0');
	variable regwrite_b : std_logic := '0';
	variable rd_out_b   : std_logic_vector(REG_BITS-1 downto 0) := 
															(others => '0');
	begin
	

	-- AICI
		if op_saved.memtoreg = '0' then -- use ALU result
			result_b := aluresult_saved;
		else -- use MEM result
			result_b := memresult_saved;
		end if;

    -- kopieren ob es eigentlich geschrieben soll oder nicht 
		regwrite_b := op_saved.regwrite;
        
    -- in dem register wo ich schreiben soll
		rd_out_b   := rd_in_saved;
		

	
		result   <= result_b;
		regwrite <= regwrite_b;
		rd_out   <= rd_out_b;
	
	end process;
	
	
	
	process(all)
	begin
	
		if reset = '0' then
			
			aluresult_saved <= (others => '0');
			memresult_saved <= (others => '0');
			rd_in_saved  <= (others => '0');
			op_saved     <= WB_NOP;
			
		elsif rising_edge(clk) then
			
			if flush = '1' then
			
				aluresult_saved <= (others => '0');
				memresult_saved <= (others => '0');
				rd_in_saved  <= (others => '0');
				op_saved     <= WB_NOP;
				
			elsif stall = '0' then
			
				aluresult_saved <= aluresult;
				memresult_saved <= memresult;
				rd_in_saved  <= rd_in;
				op_saved     <= op;
				
			end if;
			
		end if;
	
	end process;
	
	
	
end rtl;
