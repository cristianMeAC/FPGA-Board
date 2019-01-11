library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;
use work.memu;
use work.jmpu;

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


	-- latched inputs
	
	signal mem_op_old  : mem_op_type := MEM_NOP;
	signal jmp_op_old : jmp_op_type := JMP_NOP;
	signal wrdata_old : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal zero_old : std_logic := '0';
	signal neg_old : std_logic := '0';
	signal new_pc_in_old : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
	signal pc_in_old : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
	signal rd_in_old : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');
	signal aluresult_in_old : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal wbop_in_old : wb_op_type := WB_NOP;
	
	

begin  -- rtl
	
	--------------------------
	-- Jump Unit Instance   --
	--------------------------
	
	jmpu_instance : entity work.jmpu
		port map(
		
			op   => jmp_op_old,
			N    => neg_old,
			Z 	 => zero_old,  	
			J    => pcsrc   -- if a Jump is to be executed
	
		);
		
	--------------------------
	-- Memory Unit Instance --
	--------------------------
	
	memu_instance : entity work.memu
		port map(
		
			op   => mem_op_old,
			

			A    => aluresult_in_old(ADDR_WIDTH-1 downto 0),
			
			W    => wrdata_old,
			
			D    => mem_data,
			M    => mem_out,  -- memory operation to outside the pipeline(only one with MEM_OUT_TYPE)
			
			R    => memresult,
			
			XL   => exc_load,
			XS   => exc_store
		
		);
		
		
	process(all)

	begin
	
		if reset = '0' then 
        
        	mem_op_old <= MEM_NOP;
			jmp_op_old <= JMP_NOP;
			wrdata_old <= (others => '0');
			zero_old <= '0';
			neg_old <= '0';
			new_pc_in_old <= (others => '0');
			pc_in_old <= (others => '0');
			rd_in_old <= (others => '0');
			aluresult_in_old <= (others => '0'); 
			wbop_in_old <= WB_NOP;
        
        	new_pc_out <= (others => '0');
        	pc_out <= (others => '0');
        	rd_out <= (others => '0');
        	aluresult_out <= (others => '0');
        	wbop_out <= WB_NOP;
	
		elsif rising_edge(clk) then 
		    
            -- dann fuege ich NOPs hinein wenn flush = '1'
            -- ich werde ausfuehren was ich letztes mal gehabt hatte, von dem letzten Stufe
		    
            -- fuellen alles mit NOPs, ausser PC
            if flush = '1' then
		    	-- flush - store nops
	        	mem_op_old <= MEM_NOP;
				jmp_op_old <= JMP_NOP;
				wrdata_old <= (others => '0');
				zero_old <= '0';
				neg_old <= '0';
				rd_in_old <= (others => '0');
				aluresult_in_old <= (others => '0'); 
				wbop_in_old <= WB_NOP;
		    
		    	rd_out <= (others => '0');
		    	aluresult_out <= (others => '0');
		    	wbop_out <= WB_NOP;
				
				-- dont flush PC
				new_pc_in_old <= new_pc_in;
				pc_in_old <= pc_in;
				new_pc_out <= new_pc_in;
		    	pc_out <= pc_in;
				
				
		    elsif stall = '0' then
		    	-- causes the stage to latch inputs 
		    
	        	mem_op_old <= mem_op;
				jmp_op_old <= jmp_op;
				wrdata_old <= wrdata;
				zero_old <= zero;
				neg_old <= neg;
				rd_in_old <= rd_in;
				aluresult_in_old <= aluresult_in; 
				wbop_in_old <= wbop_in;

		    	rd_out <= rd_in;
		    	aluresult_out <= aluresult_in;
		    	wbop_out <= wbop_in;
				
				new_pc_in_old <= new_pc_in;
				pc_in_old <= pc_in;
				new_pc_out <= new_pc_in;
		    	pc_out <= pc_in;
		    
		    else
		    	-- causes the stage not to latch inputs
            
            -- spezieall dass wir halten sollen(in der ANgabe)
				mem_op_old.memwrite <= '0'; -- has to be forced to zero to ensure progression
				mem_op_old.memread <= '0';  -- has to be forced to zero to ensure progression
		    	rd_out <= rd_in_old;
		    	aluresult_out <= aluresult_in_old;
		    	wbop_out <= wbop_in_old;
				
				new_pc_out <= new_pc_in_old;
		    	pc_out <= pc_in_old;
		    	
		    end if;

		end if;

	end process;

end rtl;

