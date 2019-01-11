library ieee;
use ieee.std_logic_1164.all;

package input_manager_pkg is

	component input_manager is

		port(
			clk 	: in std_logic;
			res_n : in std_logic;
			
			switches 				: in std_logic_vector ( 15 downto 0 );
			
			change_color_button  : in std_logic;
			change_mode_button   : in std_logic;
			
			hex7						: out std_logic_vector ( 6 downto 0 );
			
			instr_wr					: out std_logic;
			instr						: out std_logic_vector ( 55 downto 0 );   
			instr_full				: in std_logic;
			
			x_input					: in std_logic_vector ( 11 downto 0 );
			y_input 					: in std_logic_vector ( 11 downto 0 )
			

		);
		
	end component;	
	
end package;	


		
	
	

