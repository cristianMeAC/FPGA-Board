
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



package serial_port_pkg is
	component serial_port is

	generic (
		CLK_FREQ : natural;
		BAUD_RATE : integer;
		SYNC_STAGES : natural;
		TX_FIFO_DEPTH : integer;
		RX_FIFO_DEPTH : integer
	);
	port (
		clk : in std_logic;
		res_n : in std_logic;
		
		tx_data : in std_logic_vector(7 downto 0);
		tx_wr   : in std_logic;
		rx_rd   : in std_logic;
		rx      : in std_logic;
		tx_free : out std_logic;
		rx_data : out std_logic_vector(7 downto 0);
		rx_data_full : out std_logic;
		rx_data_empty: out std_logic;
		tx      : out std_logic
		
	);
	end component;
end package;
