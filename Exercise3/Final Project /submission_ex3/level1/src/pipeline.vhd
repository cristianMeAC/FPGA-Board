library ieee;
use ieee.std_logic_1164.all;

use work.core_pack.all;
use work.op_pack.all;

use work.fetch;
use work.decode;
use work.exec;
use work.mem;
use work.wb;

entity pipeline is
	
	port (
		clk, reset : in	 std_logic;
		mem_in     : in  mem_in_type;
		mem_out    : out mem_out_type;
		intr       : in  std_logic_vector(INTR_COUNT-1 downto 0));

end pipeline;

architecture rtl of pipeline is

	-- fetch
	signal stall        : std_logic := '0';
	signal pcsrc        : std_logic := '0';
	signal pc_in        : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
	signal pc_out_fetch : std_logic_vector(PC_WIDTH-1 downto 0);
	signal instr        : std_logic_vector(INSTR_WIDTH-1 downto 0); 
	
	-- decode
	signal flush         : std_logic := '0';
	signal wraddr        : std_logic_vector(REG_BITS-1 downto 0);
	signal wrdata        : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal regwrite      : std_logic;
	signal pc_out_decode : std_logic_vector(PC_WIDTH-1 downto 0);
	signal exec_op       : exec_op_type;
	--signal cop0_op       : cop0_op_type; -- TODO: not used in level1
	signal jmp_op        : jmp_op_type;
	signal mem_op        : mem_op_type;
	signal wb_op         : wb_op_type;
	--signal exc_dec       : std_logic; -- TODO: not used in level1
	
	-- execute
	signal rd            : std_logic_vector(REG_BITS-1 downto 0);
	signal rs            : std_logic_vector(REG_BITS-1 downto 0);
	signal rt            : std_logic_vector(REG_BITS-1 downto 0);
	signal aluresult     : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal wrdata_exec   : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal zero          : std_logic;
	signal neg           : std_logic;
	signal new_pc        : std_logic_vector(PC_WIDTH-1 downto 0);
	signal pc_out_exec   : std_logic_vector(PC_WIDTH-1 downto 0);
	signal memop_out     : mem_op_type;
	signal jmpop_out     : jmp_op_type;
	signal wbop_out      : wb_op_type;
	signal exc_ovf       : std_logic; -- TODO: not used in level1
	-- TODO: unused
	signal forwardA      : fwd_type := FWD_NONE;
	signal forwardB      : fwd_type := FWD_NONE;
	signal cop0_rddata   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal mem_aluresult : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal wb_result     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	-- memory
	signal memresult     : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal pc_out_mem    : std_logic_vector(PC_WIDTH-1 downto 0);
	signal rd_out        : std_logic_vector(REG_BITS-1 downto 0);
	signal aluresult_out : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal wbop_out_mem  : wb_op_type;
	signal exc_load      : std_logic; -- TODO: not used in level1
	signal exc_store     : std_logic; -- TODO: not used in level1
	
	-- writeback - nothing
	
begin  -- rtl
	
	stall <= mem_in.busy;
	flush <= '0';
	
	fetch_inst : entity work.fetch
	port map(	clk    => clk, 
				reset  => reset, 
				stall  => stall, 
				pcsrc  => pcsrc,
				pc_in  => pc_in, 
				pc_out => pc_out_fetch, 
				instr  => instr);
	
	decode_inst : entity work.decode
	port map(	clk      => clk, 
				reset    => reset,
				stall    => stall,
				flush    => flush,
				pc_in    => pc_out_fetch,
				instr    => instr,
				wraddr   => wraddr,
				wrdata   => wrdata,
				regwrite => regwrite,
				pc_out   => pc_out_decode,
				exec_op  => exec_op,
				cop0_op  => open, --TODO: cop0_op,
				jmp_op   => jmp_op,
				mem_op   => mem_op,
				wb_op    => wb_op,
				exc_dec  => open); --TODO: exc_dec);
	
	exec_inst : entity work.exec
	port map(	clk           => clk,
				reset         => reset,
				stall         => stall,
				flush         => flush,
				op            => exec_op,
				rd            => rd,
				rs            => rs,
				rt            => rt,
				aluresult     => aluresult,
				wrdata        => wrdata_exec,
				zero          => zero,
				neg           => neg,
				new_pc        => new_pc,
				pc_in         => pc_out_decode,
				pc_out        => pc_out_exec,
				memop_in      => mem_op,
				memop_out     => memop_out,
				jmpop_in      => jmp_op,
				jmpop_out     => jmpop_out,
				wbop_in       => wb_op,
				wbop_out      => wbop_out,
				forwardA      => forwardA,
				forwardB      => forwardB,
				cop0_rddata   => cop0_rddata,
				mem_aluresult => mem_aluresult,
				wb_result     => wb_result,
				exc_ovf       => exc_ovf);
	
	mem_inst : entity work.mem
	port map(	clk           => clk,
				reset         => reset,
				stall         => stall,
				flush         => flush,
				mem_op        => memop_out,
				jmp_op        => jmpop_out,
				wrdata        => wrdata_exec,
				memresult     => memresult,
				zero          => zero,
				neg           => neg,
				pcsrc         => pcsrc,
				new_pc_in     => new_pc,
				new_pc_out    => pc_in, -- to fetch
				pc_in         => pc_out_exec,
				pc_out        => pc_out_mem,
				rd_in         => rd,
				rd_out        => rd_out,
				aluresult_in  => aluresult,
				aluresult_out => aluresult_out,
				wbop_in       => wbop_out,
				wbop_out      => wbop_out_mem,
				mem_out       => mem_out,
				mem_data      => mem_in.rddata,
				exc_load      => exc_load,
				exc_store     => exc_store);
	
	
	wb_inst : entity work.wb
	port map(	clk       => clk,
				reset     => reset,
				stall     => stall,
				flush     => flush,
				op        => wbop_out_mem,
				aluresult => aluresult_out,
				memresult => memresult,
				result    => wrdata,
				regwrite  => regwrite,
				rd_in     => rd_out,
				rd_out    => wraddr);
	
	
end rtl;
