library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package serial_port_tx_fsm_pkg is 
	component serial_port_tx_fsm is 

		generic (
			CLK_DIVISOR : integer
		);
		port (
			clk : in std_logic;                       --clock
			res_n : in std_logic;                     --low-active reset
		
			tx : out std_logic;                       --serial output of the parallel input
		
			data : in std_logic_vector(7 downto 0);   --parallel input byte
			empty : in std_logic;                     --empty signal from the fifo is connected here
			rd : out std_logic                        --connected to the rd input of the fifo
		);
	end component;
end package;
