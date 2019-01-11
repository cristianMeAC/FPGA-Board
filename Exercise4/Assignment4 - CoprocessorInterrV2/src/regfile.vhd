library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
use work.core_pack.all;
 
entity regfile is
   
	port (
		clk, reset	   : in  std_logic;
		stall			: in  std_logic;
		rdaddr1, rdaddr2 : in  std_logic_vector(REG_BITS-1 downto 0);
		rddata1, rddata2 : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wraddr		   : in  std_logic_vector(REG_BITS-1 downto 0);
		wrdata		   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		regwrite		 : in  std_logic);
 
end regfile;
 
architecture rtl of regfile is

constant REG_EMPTY : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
 
type MEM is array
	(2**REG_BITS - 1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal memory : MEM := (others => REG_EMPTY);
 
-- latched addresses for input and output
signal rdaddr1_saved, rdaddr2_saved : std_logic_vector(REG_BITS-1 downto 0) :=
															(others => '0');
-- no need to latch regwrite, writing once enough,
-- doesn't matter if same value written multiple times
 
begin  -- rtl
 
 
 
	process(all)
	--variable rdaddr1_use, rdaddr2_use : std_logic_vector(REG_BITS-1 downto 0);
	--variable wraddr_use : std_logic_vector(REG_BITS-1 downto 0);
	begin
   
	if reset = '0' then
		rdaddr1_saved <= (others => '0');
		rdaddr2_saved <= (others => '0');
	elsif rising_edge(clk) and stall = '0' then
		-- determine which signals to use for reading/writing addresses:
		-- if stalling, use saved values
		-- if not stalling, use values provided as input(and update saved vals)
		rdaddr1_saved <= rdaddr1;
		rdaddr2_saved <= rdaddr2;
		-- WRITE
		if regwrite = '1' and wraddr /= (0 to REG_BITS-1 => '0') then
			-- writing is enabled and we are not writing to address 0
			memory(to_integer(unsigned(wraddr))) <= wrdata;
		end if;
	end if;
	end process;
 
 
 
 
	process(all)
	begin
		-- READ 1
		if rdaddr1_saved = (0 to REG_BITS-1 => '0') then
			-- reading from addres 0
			rddata1 <= (others => '0');
		elsif regwrite = '1' and rdaddr1_saved = wraddr and stall = '0' then
			-- reading and writing to the same register, return new value
			rddata1 <= wrdata;
		else
			-- normal read
			rddata1 <= memory(to_integer(unsigned(rdaddr1_saved)));
		end if;
		-- READ 2
		if rdaddr2_saved = (0 to REG_BITS-1 => '0') then
			-- reading from addres 0
			rddata2 <= (others => '0');
		elsif regwrite = '1' and rdaddr2_saved = wraddr and stall = '0' then
			-- reading and writing to the same register, return new value
			rddata2 <= wrdata;
		else
			-- normal read
			rddata2 <= memory(to_integer(unsigned(rdaddr2_saved)));
		end if;	
	end process;
   
   
   
end rtl;
