library ieee;
use ieee.std_logic_1164.all;

entity input_touch_tb is
end entity;

architecture beh of input_touch_tb is

	-- we need to write this
	constant CLK_PERIOD : time := 20 ns;
	
	signal		clk 	:  std_logic;
	signal		res_n :  std_logic;
			
	signal		switches 				:  std_logic_vector  ( 15 downto 0 );
			
	signal		change_color_button  :  std_logic;
	signal		change_mode_button   :  std_logic;
			
	signal		hex7						:  std_logic_vector ( 6 downto 0 );
			
	signal		instr_wr					:  std_logic;
	signal		instr						:  std_logic_vector ( 55 downto 0 );
	signal		instr_full				:  std_logic := '1';
			
	signal x_input					:  std_logic_vector ( 11 downto 0 );
	signal y_input 				:  std_logic_vector ( 11 downto 0 );
	
	
	signal 		din 			:  std_logic;
	signal		dclk 			:  std_logic;
	signal		scen 			:  std_logic;
			
	signal		dout		 	:  std_logic;
	signal		busy		 	:  std_logic;
	signal		penirq_n  	:  std_logic;
			
	signal		x				:  std_logic_vector (11 downto 0);
	signal		y				:  std_logic_vector (11 downto 0);
		

	
	
	component input_manager is

		port(
		
			clk 	: in std_logic;
			res_n : in std_logic;
			
			switches 				: in std_logic_vector  ( 15 downto 0 );
			
			change_color_button  : in  std_logic;
			change_mode_button   : in  std_logic;
			
			hex7						: out std_logic_vector ( 6 downto 0 );
			
			instr_wr					: out std_logic;
			instr						: out std_logic_vector ( 55 downto 0 );
			instr_full				: in  std_logic;
			
			x_input					: in std_logic_vector ( 11 downto 0 );
			y_input 					: in std_logic_vector ( 11 downto 0 )
					
		);

	end component;	
	

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

	
begin 


	touch_controller_ins : touch_controller
		port map(
			din 	=>	din,	
			dclk 	=>	dclk,	
			scen 	=>	scen,	
			
			dout	=>	dout, 	
			busy	=>	 busy,	
			penirq_n  => penirq_n,	
			
			x			=>	x,
			y			=>	y,
		
			clk 		=>	clk,
			res_n 	=>	res_n
	
		);
	
	input_manager_ins : input_manager
		port map(
		
			clk 	  => clk,
			res_n   => res_n,
			
			switches 	=>	switches,		
			
			change_color_button  => change_color_button,
			change_mode_button   => change_mode_button,
			
			hex7				=>		hex7,
			
			instr_wr			=>		instr_wr,
			instr				=>		instr,
			instr_full		=>		instr_full,
			
			x_input			=>		x,
			y_input 			=>		y
		

		);

	-- Generates the clock signal
	clkgen : process
	begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process clkgen;

	
	-- Generates the reset signal
	reset : process
	begin  
		-- process reset
		res_n <= '0';
		
		--waits for 10 cycles
		for i in 1 to 10 loop
			wait until rising_edge(clk);
		end loop;
		
		res_n <= '1';
		wait;

	end process;
	
	
	penirq_n <= transport '1', '0' after 40010 ns, '1' after 41010 ns;
	
	dout <= transport '0', '1' after 220030 ns, '0' after 240030 ns, '1' after 260030 ns, '0' after 280030 ns, '1' after 320030 ns, '0' after 380030 ns, '1' after 400030 ns,  
							'1' after 700030 ns, '0' after 720030 ns, '1' after 760030 ns, '0' after 780030 ns, '1' after 800030 ns, '0' after 860030 ns; 
	
	change_mode_button <= transport '1', '0' after 200 us, '1' after 205 us;

end architecture;
