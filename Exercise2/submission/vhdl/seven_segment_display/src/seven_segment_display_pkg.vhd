-- ADD YOUR CODE HERE
library ieee;
use ieee.std_logic_1164.all;

package seven_segment_display_pkg is

	component seven_segment_display is
		
		port(
		
			color : in  std_logic_vector ( 15 downto 0);
			
			hex0	: out std_logic_vector ( 6 downto 0);
			hex1	: out std_logic_vector ( 6 downto 0);
			hex2	: out	std_logic_vector ( 6 downto 0);
			hex3	: out	std_logic_vector ( 6 downto 0);
			
			clk    : in std_logic;
			res_n  : in std_logic;
			button : in std_logic;
			hex4	: out	std_logic_vector ( 6 downto 0);
			hex5	: out	std_logic_vector ( 6 downto 0);
			hex6	: out	std_logic_vector ( 6 downto 0);
			hex7	: out	std_logic_vector ( 6 downto 0);
		
			debugX : in std_logic_vector( 11 downto 0);
			debugY : in std_logic_vector( 11 downto 0)

		);
		
	end component;	
	
end package;	