library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package serial_port_rx_fsm_pkg is
	component serial_port_rx_fsm is

		generic (
			CLK_DIVISOR : integer
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
		
			rx : in std_logic;
			new_data : out std_logic;
			data : out std_logic_vector(7 downto 0)
		);
	end component;
end package;
