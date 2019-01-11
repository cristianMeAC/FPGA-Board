library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity mem is
	
	port (
		clk, reset    : in  std_logic;
		stall         : in  std_logic;
		flush         : in  std_logic;
		mem_op        : in  mem_op_type;  -- memory operation from execute stage
		jmp_op        : in  jmp_op_type;  --   jump operation from execute stage
		
		wrdata        : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- data to be written to memory
		memresult     : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- result of memory load
		
		zero, neg     : in  std_logic;  -- zero / negative flag from ALU
		
		pcsrc         : out std_logic;  -- asserted if a jump is to be executed
		
		
		new_pc_in     : in  std_logic_vector(PC_WIDTH-1 downto 0); -- jump target from execute stage
		new_pc_out    : out std_logic_vector(PC_WIDTH-1 downto 0); -- jump target to fetch     stage
		
		pc_in         : in  std_logic_vector(PC_WIDTH-1 downto 0);  -- program counter from execute stage
		pc_out        : out std_logic_vector(PC_WIDTH-1 downto 0);  -- program counter to write-back stage
		
		rd_in         : in  std_logic_vector(REG_BITS-1 downto 0);	-- destination register from execute stage
		rd_out        : out std_logic_vector(REG_BITS-1 downto 0);  -- destination register to write-back stage
		
		aluresult_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- result from ALU from execute stage	
		aluresult_out : out std_logic_vector(DATA_WIDTH-1 downto 0); -- result from ALU to write-back stage	
		
		
		
		wbop_in       : in  wb_op_type;  -- write_back operation from execute stage
		wbop_out      : out wb_op_type;  -- write-back operation to write-back stage
		
		mem_data      : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- memory load result from outside the pipeline
		mem_out       : out mem_out_type; 									 -- memory operation to outside the pipeline
		
		exc_load      : out std_logic; -- load exception
		exc_store     : out std_logic  -- store exeption
		);

end mem;

architecture rtl of mem is

	component jmpu is
	
		port (
			op   : in  jmp_op_type;  -- operation
			N    : in  std_logic;    -- negative flag 
			Z    : in  std_logic;    -- zero flag
			J    : out std_logic     -- jump
		);
        
	end component;
	
	
	component memu is
	
		port (
			op   : in  mem_op_type;
			A    : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- Address
			
			W    : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Write Data
			
			D    : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data from Memory
			M    : out mem_out_type;									 -- Inteface to memory
			R    : out std_logic_vector(DATA_WIDTH-1 downto 0); -- Result of memory load
			
			XL   : out std_logic; -- load  exception
			XS   : out std_logic  -- store exception 
		
		);
			
	end component;
	
	--signal mem_op_temp : mem_op_type;
	--signal jmp_op_temp : jmp_op_type;
	
	signal N_temp : std_logic;
	signal Z_temp : std_logic;
	signal W_temp :  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal aluresult_in_temp : std_logic_vector(DATA_WIDTH-1 downto 0); 
	

begin  -- rtl
	
	--------------------------
	-- Jump Unit Instance   --
	--------------------------
	
	jmpu_instance : jmpu
		port map(
		
			op   => jmp_op,
			N    => N_temp,
			Z 	  => Z_temp,  	
			J    => pcsrc   -- if a Jump is to be executed
	
		);
		
	--------------------------
	-- Memory Unit Instance --
	--------------------------
	
	memu_instance : memu
		port map(
		
			op   => mem_op,
			A    => aluresult_in_temp,
			
			W    => W_temp,
			
			D    => mem_data,
			M    => mem_out,
			
			R    => memresult,
			
			XL   => exc_load,
			XS   => exc_store
		
		);
		
		
	process(all)

	begin
	
		if res_n = '0' then 
		
		
		
		
		elsif rising_edge(clk) and stall = '0' then 
		
		
			elsif rising_edge(clk) and stall = '1' then 
		
		
		
		end if;


	end process;



end rtl;

