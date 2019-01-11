-- touch contoller code

library ieee;
use ieee.std_logic_1164.all;

package touch_controller_pkg is

	component touch_controller is

		port(
			din 			: out std_logic;
			dclk 			: out std_logic;
			scen 			: out std_logic;
		
			dout		 	: in std_logic;
			busy		 	: in std_logic;
			penirq_n  	: in std_logic;
		
			x				: out std_logic_vector (11 downto 0);
			y				: out std_logic_vector (11 downto 0);
	
			clk 			: in std_logic;
			res_n 		: in std_logic
		);
	end component;	
	
end package;
