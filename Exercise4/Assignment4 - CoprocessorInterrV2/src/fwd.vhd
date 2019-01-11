library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity fwd is
	port (
		-- define input and output ports as needed
		clk, reset : in std_logic;
		stall      : in std_logic;
		flush      : in std_logic;
		regA       : in std_logic_vector(REG_BITS-1 downto 0);
		regB       : in std_logic_vector(REG_BITS-1 downto 0);
		regDest    : in std_logic_vector(REG_BITS-1 downto 0);
		forwardA   : out fwd_type;
		forwardB   : out fwd_type
);
	
end fwd;

architecture rtl of fwd is


	signal reg_mem : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');
	signal reg_wb  : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');
	signal regA_lat : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');
	signal regB_lat : std_logic_vector(REG_BITS-1 downto 0) := (others => '0');


begin  -- rtl


	
	prepare_out : process(all)
	begin
		-- regA and regB are connected directly from exec, asynchronously
		-- type fwd_type is (FWD_NONE, FWD_ALU, FWD_WB);
		/*if regA = std_logic_vector(to_unsigned(0, REG_BITS)) then
			forwardA <= FWD_NONE;
		elsif regA = reg_mem then
			forwardA <= FWD_ALU;
		elsif regA = reg_wb then
			forwardA <= FWD_WB;
		else
			forwardA <= FWD_NONE;
		end if;

		if regB = std_logic_vector(to_unsigned(0, REG_BITS)) then
			forwardB <= FWD_NONE;
		elsif regB = reg_mem then
			forwardB <= FWD_ALU;
		elsif regB = reg_wb then
			forwardB <= FWD_WB;
		else
			forwardB <= FWD_NONE;
		end if;*/
		
		if regA_lat = std_logic_vector(to_unsigned(0, REG_BITS)) then
			forwardA <= FWD_NONE;
		elsif regA_lat = reg_mem then
			forwardA <= FWD_ALU;
		elsif regA_lat = reg_wb then
			forwardA <= FWD_WB;
		else
			forwardA <= FWD_NONE;
		end if;

		if regB_lat = std_logic_vector(to_unsigned(0, REG_BITS)) then
			forwardB <= FWD_NONE;
		elsif regB_lat = reg_mem then
			forwardB <= FWD_ALU;
		elsif regB_lat = reg_wb then
			forwardB <= FWD_WB;
		else
			forwardB <= FWD_NONE;
		end if;


	
	end process;


	process(all)
	begin
	
	
	
		if reset = '0' then
		
			reg_mem <= (others => '0');
			reg_wb <= (others => '0');
			regA_lat <= (others => '0');
			regB_lat <= (others => '0');
			
		elsif rising_edge(clk) then
		
			if flush = '1' then
				-- flushing

				reg_mem <= (others => '0');
				reg_wb <= reg_mem;
				
			elsif stall = '0' then
				-- normal operation
				
				reg_mem <= regDest;
				reg_wb <= reg_mem;
				regA_lat <= regA;
				regB_lat <= regB;
								
			end if;


	
		end if;
	
	end process;

end rtl;
