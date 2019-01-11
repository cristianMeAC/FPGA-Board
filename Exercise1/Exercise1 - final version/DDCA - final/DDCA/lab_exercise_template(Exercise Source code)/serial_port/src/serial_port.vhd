library ieee;
use ieee.std_logic_1164.all;

use work.sync_pkg.all;

-- fifo_1c1r1w it's in RAM
use work.ram_pkg.all;

entity serial_port is
	
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
	
end entity;


	
architecture beh of serial_port is

	-- For Transmitter -- 
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
	
	component serial_port_rx_fsm is 

		generic (
			CLK_DIVISOR : integer
		);
		port (
			clk   : in std_logic;                     --clock
			res_n : in std_logic;                     --low-active reset
			
			rx 	: in std_logic;                     --serial input of the parallel input
			
			new_data 		   : out	std_logic;    
			data 					: out std_logic_vector(7 downto 0)
			                  
		);
		
	end component;
	
	signal data_out_temp : std_logic;
	
	signal new_data_temp		   	: std_logic;    
	signal data_temp 					: std_logic_vector(7 downto 0);
	signal rd_temp						: std_logic;
	signal rd_data_temp 				: std_logic_vector(7 downto 0);
	signal empty_temp					: std_logic;


begin 

	-- an Instance of sync
	sync_instance : sync
	generic map(
		SYNC_STAGES => SYNC_STAGES,
		RESET_VALUE => '1'
	)
	port map(
		clk => clk,
		res_n => res_n,
		data_in => rx,
		data_out => data_out_temp
	);
	
	-- an Instance of serial_port_rx_fsm
	-- ist in ram package
	rx_fsm_inst : serial_port_rx_fsm
	generic map(
		CLK_DIVISOR => CLK_FREQ / BAUD_RATE
	)
	port map(
		clk => clk,
		res_n => res_n,
		rx => data_out_temp,
		new_data => new_data_temp,
		data =>	data_temp
	);
	
	-- an Instance of fifo_1c1r1wTop
	rx_fifo_inst : fifo_1c1r1w
	generic map(
		MIN_DEPTH => RX_FIFO_DEPTH,
		DATA_WIDTH => 8
	)
	port map(
		clk => clk,
		res_n => res_n,
		rd => rx_rd,
		wr => new_data_temp,
		wr_data => data_temp,
		empty => rx_empty,
		rd_data => rx_data,
		full => rx_full,
		fill_level => open
	);
	
	-- an Instance of fifo_1c1r1wBottom
	tx_fifo_inst : fifo_1c1r1w
	generic map(
		MIN_DEPTH => TX_FIFO_DEPTH,
		DATA_WIDTH => 8
	)
	port map(
		clk => clk,
		res_n => res_n,
		wr => tx_wr ,
		wr_data => tx_data,
		rd => rd_temp,
		empty => empty_temp,
		rd_data => rd_data_temp,
		full => tx_full,
		fill_level => open
	);
	
	
	-- an Instance of serial_port_tx_fsm
	tx_fsm_inst : serial_port_tx_fsm
	generic map(
		CLK_DIVISOR => CLK_FREQ / BAUD_RATE
	)
	port map(
		clk => clk,
		res_n => res_n,
		empty => empty_temp,
		data => rd_data_temp,
		tx => tx,
		rd => rd_temp
	);
	

end architecture;	

