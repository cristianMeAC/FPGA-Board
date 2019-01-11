library ieee;
use ieee.std_logic_1164.all;
use work.serial_port_pkg.all;
use work.top_tb_util_pkg.all;

entity serial_port_tb is
end entity;

architecture beh of serial_port_tb is

	constant CLK_PERIOD : time := 20 ns;

	component serial_port is
	
		generic(
		
			CLK_FREQ : integer;
			BAUD_RATE : integer;
			SYNC_STAGES : integer;
			TX_FIFO_DEPTH : integer;
			RX_FIFO_DEPTH : integer
			
		);
		port(
			clk 	   : in std_logic;
			res_n 	: in std_logic;
			tx_data  : in std_logic_vector ( 7 downto 0 );
			tx_wr 	: in std_logic;
			rx_rd		: in std_logic;
			rx			: in std_logic;
			
			
			tx_full  : out std_logic;
			rx_data  : out std_logic_vector ( 7 downto 0 );
			rx_full  : out std_logic;
			rx_empty : out std_logic;
			tx 		: out std_logic
			
		);
	
	end component;
	
	signal clk 	   : std_logic;
	signal res_n 	: std_logic;
	signal tx_data : std_logic_vector ( 7 downto 0 );
	signal tx_wr 	: std_logic;
	signal rx_rd	: std_logic;
	signal rx		: std_logic;
					
	signal tx_full   : std_logic;
	signal rx_data   : std_logic_vector ( 7 downto 0 );
	signal rx_full   : std_logic;
	signal rx_empty  : std_logic;
	signal tx 		  : std_logic;
	
	


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
		
		  wait until rising_edge(res_n);
		  
		  rx <= '1';
		  wait for 104 us;
		  
		  -- 1/BAUD_RATE 
		  
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
		
		
		serial_port_instance : serial_port
			generic map(
			
				CLK_FREQ 		=> 50000000,
				BAUD_RATE 		=> 9600,
				SYNC_STAGES    => 2,
				TX_FIFO_DEPTH  => 8,
				RX_FIFO_DEPTH  => 8
			
			)
			port map(
				clk 	   => clk,   
				res_n    => res_n,	
				tx_data  => tx_data,
				tx_wr 	=>	tx_wr,
				rx_rd		=>	rx_rd,
				rx			=>	rx,	
			
				tx_full  => tx_full,
				rx_data  => rx_data,
				rx_full  => rx_full,
				rx_empty => rx_empty,
				tx 		=>	tx	
	
			);	

end architecture;