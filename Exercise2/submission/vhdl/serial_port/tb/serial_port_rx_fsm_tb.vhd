library ieee;
use ieee.std_logic_1164.all;
use work.serial_port_pkg.all;
use work.top_tb_util_pkg.all;

entity serial_port_rx_fsm_tb is
end entity;

architecture beh of serial_port_rx_fsm_tb is
	
	constant CLK_PERIOD : time := 20 ns;
	constant BAUD_RATE : integer := 9600; 
	
	component serial_port_rx_fsm is 

		generic (
			CLK_DIVISOR : integer
		);
		port (
			clk   : in std_logic;                     --clock
			res_n : in std_logic;                     --low-active reset
			
			rx 	: in std_logic;                     --serial input of the parallel input
			
			-- if they are really std_logic or not
			new_data 		   : out	std_logic;    
			data 					: out std_logic_vector(7 downto 0)
			                  
		);
		
	end component;
	
	constant CLK_DIVISOR : integer := 50000000 / BAUD_RATE;
	
	signal clk   : std_logic; 
	signal res_n : std_logic;

	signal rx    : std_logic;
				
	signal new_data : std_logic;		     
	signal data 	 : std_logic_vector ( 7 downto 0);
	
begin

		-- Generates the clock signal
		clkgen : process
		begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
		end process clkgen;
		
		-- TB
		testbench : process
		begin
		
		  wait until rising_edge(res_n);
		  
		  rx <= '1';
		  wait for 104 us;
		  
		  --start bit
		  rx <= '0';
		  
		  --data bit
		  wait for 104 us;
		  rx <= '1';
		  wait for 104 us;
		  rx <= '0';
		  wait for 104 us;
		  
		  rx <= '1';
		  wait for 104 us;
		  rx <= '0';
		  wait for 104 us;
		  rx <= '1';
		  wait for 104 us;
		  rx <= '0';
		  
		  -- waits for 3 cycles
		  wait for 312 us;
		  
		  -- stop bit
		  rx <= '1';
		  
		  
		  
		  wait;
		
		
		end process;
		
		-- Generates the reset signal
		reset : process
		begin  -- process reset
			res_n <= '0';
			wait_cycle(clk, 10);
			res_n <= '1';
		wait;
		end process;

		
		serial_port_rx_fsm_inst : serial_port_rx_fsm
		generic map (
			CLK_DIVISOR => CLK_DIVISOR
		)
		port map(
			clk   => clk,
			res_n => res_n,

			rx 		=> rx,	
			
			new_data => new_data,		     
			data 		=>	data
		
		);	
		
end architecture;