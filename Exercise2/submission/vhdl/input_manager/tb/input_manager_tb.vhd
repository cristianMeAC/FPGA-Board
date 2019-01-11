library ieee;
use ieee.std_logic_1164.all;

--use work.input_manager_pkg.all;

entity input_manager_tb is
end entity;

architecture beh of input_manager_tb is

		-- we need to write this
	constant CLK_PERIOD : time := 20 ns;
	
	signal res_n :  std_logic;
	signal clk 	 :  std_logic;
	
	signal switches 				 : std_logic_vector ( 15 downto 0 );
	signal change_color_button  : std_logic;
	signal change_mode_button   : std_logic;
			
	signal hex7						 : std_logic_vector ( 6 downto 0 );
			
	signal instr_wr					: std_logic;
	signal instr						: std_logic_vector ( 55 downto 0 );   
	signal instr_full				   : std_logic;
			
	signal x_input					   : std_logic_vector ( 11 downto 0 );
	signal y_input 					: std_logic_vector ( 11 downto 0 );


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
	
	
begin

	-----------------------------------------------
	--    input_manager instance                 --
	-----------------------------------------------
	input_manager_instance : input_manager
		port map(
		
			clk 		=>  clk,
			res_n 	=>  res_n,
			
			switches  =>	switches,			
			
			change_color_button  => change_color_button,
			change_mode_button   => change_mode_button,
			
			hex7						=> hex7,
			
			instr_wr					=> instr_wr,
			instr						=> instr,
			instr_full				=> instr_full,
			
			x_input					=> x_input,
			y_input 					=> y_input
		
		);

		--change_mode_button <= '1';
	testbench : process	
	begin
			
		  change_mode_button <= '0';
		  wait for 2 us;
		  change_mode_button <= '1';
		  
		  
		  change_mode_button <= '0';
		  wait for 2 us;
		  change_mode_button <= '1';
		  
		  -- if not, they happen simultaneously
		  wait for 2 us;
	
		  change_mode_button <= '0';
		  wait for 2 us;
		  change_mode_button <= '1';
		  
		  wait for 2 us;

		  change_mode_button <= '0';
		  wait for 2 us;
		  change_mode_button <= '1';
		  
		  wait;
		  
	end process;
		
	-- for instr TB
	testbench_instr : process	
	begin
			
		instr(7 downto 0)   <= x"02";
		wait for 2 us;
									
		-- axes inter-changed because of the TouchScreen
		instr(19 downto 8)  <= "000011110000";--y_input (11 downto 0);	
		wait for 2 us;	
		
		instr(31 downto 20) <= "000011110000";--x_input (11 downto 0);
		wait for 2 us;
		
		instr(55 downto 32) <= (others => '0');
		wait for 2 us;
							
	
		wait;
		  
	end process;
		
		

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


end architecture;