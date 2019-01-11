library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.imem_altera;

use work.core_pack.all;

entity fetch is
	
	port (
		clk, reset : in	 std_logic;
		stall      : in  std_logic;
		pcsrc	   : in	 std_logic;  -- use pc_in or incremented PC as new PC 
		pc_in	   : in	 std_logic_vector(PC_WIDTH-1 downto 0); -- indicates the address of the next intrusction
		pc_out	   : out std_logic_vector(PC_WIDTH-1 downto 0); -- points to the current instruction
		instr	   : out std_logic_vector(INSTR_WIDTH-1 downto 0)); -- fetched instruction

end fetch;

architecture rtl of fetch is

    signal pc_next : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
    signal pc      : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');
    signal pc_buf  : std_logic_vector(PC_WIDTH-1 downto 0) := (others => '0');

    signal instr_next : std_logic_vector(INSTR_WIDTH-1 downto 0) := (others => '0');
    signal instr_saved : std_logic_vector(INSTR_WIDTH-1 downto 0) := (others => '0');
    signal instr_buf : std_logic_vector(INSTR_WIDTH-1 downto 0) := (others => '0');

    signal stall_prev : std_logic := '0';
    signal reset_flag : std_logic := '0';


begin  -- rtl



imem: entity work.imem_altera 
    port map (  
        address => pc_buf(PC_WIDTH-1 downto 2),
        clock => clk,
        q => instr_next
	);


process(all)
begin

if reset = '0' then

	-- clear latched signals
    pc <= (others => '0');
    instr_saved <= (others => '0');
    stall_prev <= '0';
    reset_flag <= '0';
    
  elsif rising_edge(clk) then

    reset_flag <= '1';
    -- if not stalled, change the internal PC
    if stall = '0' then
      if pcsrc = '0' then
        pc <= pc_next;
      else 
        pc <= pc_in;
      end if;   
    end if;
    
    -- latch imem output and the stall signal
	instr_saved <= instr_buf;

    stall_prev <= stall;
    
  end if;
  
end process;



process(all)
begin

  -- reset_flag is set to '1' on the first rising edge of the clk
  -- => first(zeroth) instruction is held for the whole clk cycle after the reset signal goes high
  if reset = '1' and reset_flag = '1' then
  
      -- if stalled, output previously latched instruction
      if stall_prev = '0' then
        instr_buf <= instr_next;
      else
        instr_buf <= instr_saved;
      end if;
      
      pc_next <= std_logic_vector(unsigned(pc) + to_unsigned(4, PC_WIDTH));
  else
    instr_buf <= (others => '0');
    pc_next <= (others => '0');
  end if;

end process;

-- pc_buf is connected with the address input of the imem. It gets incremented by 4 on the first rising edge of the clk signal after the reset signal goes high IF pcsrc = '0'
-- If pcsrc = '1', pc_buf is set to pc_in.

pc_buf <=  std_logic_vector(unsigned(pc) + to_unsigned(4, PC_WIDTH)) when pcsrc = '0' and reset = '1' and reset_flag = '1' else pc_in 
                                                                     when pcsrc = '1' and reset = '1' and reset_flag = '1' else (others => '0');
pc_out <= pc_buf;
instr <= instr_buf;

end rtl;
