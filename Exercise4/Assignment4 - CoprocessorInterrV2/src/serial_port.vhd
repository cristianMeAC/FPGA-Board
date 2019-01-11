
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serial_port_tx_fsm_pkg.all;
use work.serial_port_rx_fsm_pkg.all;
use work.sync_pkg.all;
use work.ram_pkg.all;

entity serial_port is

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
end entity;


architecture beh of serial_port is

	constant CLK_DIVISOR : integer := CLK_FREQ / BAUD_RATE;
	constant RESET_VALUE : std_logic := '1';
	constant DATA_WIDTH  : natural := 8;

	signal new_data : std_logic;
	signal data : std_logic_vector(7 downto 0);
	signal sync_out : std_logic;
	signal rd : std_logic;
	signal empty : std_logic;
	signal rd_data : std_logic_vector(7 downto 0);
	signal tx_full : std_logic;
	


begin


	sync: entity work.sync
	generic map(SYNC_STAGES => SYNC_STAGES, RESET_VALUE => RESET_VALUE)
	port map(clk => clk,
      res_n => res_n,  
      data_in => rx,
      data_out => sync_out
    );
    
    
    
    tx_fifo_inst: entity work.fifo_1c1r1w
    generic map(MIN_DEPTH => TX_FIFO_DEPTH, DATA_WIDTH => DATA_WIDTH)
    port map(clk => clk,
    		res_n => res_n,
    		rd => rd,
    		wr => tx_wr,
    		wr_data => tx_data,
    		empty => empty,
    		rd_data => rd_data,
    		full => tx_full,
    		fill_level => open
    );
    
    tx_free <= not tx_full;
    
    rx_fifo_inst: entity work.fifo_1c1r1w
    generic map(MIN_DEPTH => RX_FIFO_DEPTH, DATA_WIDTH => DATA_WIDTH)
    port map(clk => clk,
    		res_n => res_n,
    		rd => rx_rd,
    		wr => new_data,
    		wr_data => data,
    		empty => rx_data_empty,
    		rd_data => rx_data,
    		full => rx_data_full,
    		fill_level => open
    );
    
    
    sp_rx_fsm_inst: entity work.serial_port_rx_fsm
    generic map(CLK_DIVISOR => CLK_DIVISOR)
    port map(clk => clk,
    		res_n => res_n,
    		rx => sync_out,
    		new_data => new_data,
    		data => data
   	);
   	
    
    sp_tx_fsm_inst: entity work.serial_port_tx_fsm
    generic map(CLK_DIVISOR => CLK_DIVISOR)
    port map(clk => clk,
    		res_n => res_n,
    		empty => empty,
    		data => rd_data,
    		tx => tx,
    		rd => rd
    );
    





end architecture;





