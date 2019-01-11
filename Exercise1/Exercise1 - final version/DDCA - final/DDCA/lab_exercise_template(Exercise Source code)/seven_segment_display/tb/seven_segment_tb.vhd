-- ADD YOUR CODE HERE

library ieee;
use ieee.std_logic_1164.all;
use work.seven_segment_display_pkg.all;

entity seven_segment_tb is
end entity;

architecture beh of seven_segment_tb is

	constant CLK_PERIOD : time := 20 ns;

	component seven_segment_display is
		port(
			color : in  std_logic_vector ( 15 downto 0);
			
			hex0	: out std_logic_vector ( 6 downto 0);
			hex1	: out std_logic_vector ( 6 downto 0);
			hex2	: out	std_logic_vector ( 6 downto 0);
			hex3	: out	std_logic_vector ( 6 downto 0);
			
			-- Task5 added signals
			clk 	 : in std_logic;
			res_n  : in std_logic;
			button : in std_logic;
			hex4	: out	std_logic_vector ( 6 downto 0);
			hex5	: out	std_logic_vector ( 6 downto 0)		
		);
	end component;	
	
	-- my Matriculation number % 2^16
	signal color : std_logic_vector ( 15 downto 0 ) := "1110011110010110";
	
	signal hex0	: std_logic_vector ( 6 downto 0);
	signal hex1	: std_logic_vector ( 6 downto 0);
	signal hex2	: std_logic_vector ( 6 downto 0);
	signal hex3	: std_logic_vector ( 6 downto 0);
	signal hex4	: std_logic_vector ( 6 downto 0);
	signal hex5	: std_logic_vector ( 6 downto 0);
	
	signal button : std_logic := '1'; 
	signal clk	  : std_logic := '0';
	signal res_n  : std_logic := '1';


begin

		-- Generates the clock signal
		clkgen : process
		begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
		end process clkgen;

		
		testbench : process
		begin
		
		  wait for 5 ms;
		  
		  -- transition from red -> blue
		  button <= '0';
		  wait for 2 ms;
		  button <= '1';
		  
		  -- if not, they happen simultaneously
		  wait for 2 ms;
	
		  -- transition from blue -> green
		  button <= '0';
		  wait for 2 ms;
		  button <= '1';
		  
		  wait for 2 ms;
		  
		  -- transition from green -> red
		  button <= '0';
		  wait for 2 ms;
		  button <= '1';
		  
		  wait;
		  
		end process;
		
	  seven_segment_display_instace : seven_segment_display
		port map(
		
			color => color,
		
			hex0 => hex0,	
			hex1 => hex1,
			hex2 => hex2,
			hex3 => hex3,	
			
			-- Task5 added signals
			clk => clk, 	 
			res_n => res_n, 
			button => button,
			hex4 => hex4,	
			hex5 => hex5		
	
		);	

end architecture;
