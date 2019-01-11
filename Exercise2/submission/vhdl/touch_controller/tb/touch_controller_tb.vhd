library ieee;
use ieee.std_logic_1164.all;

entity touch_controller_tb is
end entity;


architecture beh of touch_controller_tb is

	-- we need to write this
	constant CLK_PERIOD : time := 20 ns;

	signal	din 	: std_logic;
	signal	dclk 	: std_logic;
	signal	scen 	: std_logic;
			
	signal	dout 			:  std_logic;
	signal	busy			:  std_logic;
	signal	penirq_n  	:  std_logic;
			
	signal	x		:  std_logic_vector (11 downto 0);
	signal	y		:  std_logic_vector (11 downto 0);
		
	signal	res_n :  std_logic;
	signal	clk 	:  std_logic;

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
	
		res_n 		: in std_logic;
		clk 			: in std_logic
	);
	
end component;	

begin

	-----------------------------------------------
	--    touch_controller instance              --
	-----------------------------------------------
	touch_instance : touch_controller
	port map(
		din => din, 			
		dclk => dclk,			
		scen => scen,			
		
		dout =>	dout,	 	
		busy => busy,		 	
		penirq_n => penirq_n, 	
		
		x => x,				
		y => y,				
	
		res_n => res_n, 		
		clk => clk			
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
	
	
	-- for X: '1001 0 010
	-- for Y: '1101 0 010

	penirq_n <= transport '1', '0' after 40010 ns, '1' after 41010 ns;
	
	dout <= transport '0', '1' after 220030 ns, '0' after 240030 ns, '1' after 260030 ns, '0' after 280030 ns, '1' after 320030 ns, '0' after 380030 ns, '1' after 400030 ns,  
							'1' after 700030 ns, '0' after 720030 ns, '1' after 760030 ns, '0' after 780030 ns, '1' after 800030 ns, '0' after 860030 ns; 
	
	
	/*
	penirq_n <= '1';
	wait for 40 us;
	
	penirq_n <= '0';
	wait for 60 us;
	
	penirq_n <= '1';
	wait for 80 us;
	*/

	
	
	
end architecture;