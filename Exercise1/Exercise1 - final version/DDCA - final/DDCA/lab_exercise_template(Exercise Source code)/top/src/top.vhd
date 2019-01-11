
--------------------------------------------------------------------------------
--                                LIBRARIES                                   --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- import all required packages
use work.sync_pkg.all;
use work.ascii_gcinstr_pkg.all;
use work.graphics_controller_pkg.all;
use work.math_pkg.all;
use work.merge_fifo_pkg.all;
use work.ps2_transceiver_pkg.all;
use work.ps2_pkg.all;
use work.ps2_ascii_pkg.all;
use work.ram_pkg.all;
use work.rom_pkg.all;
use work.seven_segment_display_pkg.all;

-- They are in graphics_controller
use work.framereader_pkg.all;
use work.rasterizer_pkg.all;
use work.sram_pkg.all;
use work.wb_arbiter_pkg.all;
-- use work.pll_pkg.all;

use work.serial_port_pkg.all;


--------------------------------------------------------------------------------
--                                 ENTITY                                     --
--------------------------------------------------------------------------------

entity top is
	port (
		--50 MHz clock input
		clk      : in  std_logic;

		-- push buttons and switches
		keys     : in std_logic_vector(3 downto 0);
		switches : in std_logic_vector(17 downto 0);
	
		--Seven segment digit
		hex0 : out std_logic_vector(6 downto 0);
		hex1 : out std_logic_vector(6 downto 0);
		hex2 : out std_logic_vector(6 downto 0);
		hex3 : out std_logic_vector(6 downto 0);
		hex4 : out std_logic_vector(6 downto 0);
		hex5 : out std_logic_vector(6 downto 0);
		
		hex6 : out std_logic_vector(6 downto 0);
		hex7 : out std_logic_vector(6 downto 0);

		-- the grren LEDs
		ledg : out std_logic_vector(8 downto 0);

		-- external interface to SRAM
		sram_dq : inout std_logic_vector(15 downto 0);
		sram_addr : out std_logic_vector(19 downto 0);
		sram_ub_n : out std_logic;
		sram_lb_n : out std_logic;
		sram_we_n : out std_logic;
		sram_ce_n : out std_logic;
		sram_oe_n : out std_logic;
		
		-- LCD interface
		nclk    : out std_logic;
		hd      : out std_logic;
		vd      : out std_logic;
		den     : out std_logic;
		r       : out std_logic_vector(7 downto 0);
		g       : out std_logic_vector(7 downto 0);
		b       : out std_logic_vector(7 downto 0);
		grest   : out std_logic;
		sda     : out std_logic;
		
		-- PS/2
		ps2_clk   :inout std_logic;
		ps2_data  :inout std_logic;
		
		-- creating new ports and map to corresponding FPGA pins 
		rx : in std_logic;
		tx : out std_logic
		
	);
end entity;

--------------------------------------------------------------------------------
--                             ARCHITECTURE                                   --
--------------------------------------------------------------------------------

-- add your architecture here!

architecture top_arch of top is
	
	constant SYNC_STAGES : integer := 2;
	constant SYS_CLK_FREQ : integer := 50000000;
	constant PS2_BUFFER_DEPTH : integer := 8;
	constant DATA_WIDTH : integer := 56;
	
	-- Task6  
	constant BAUD_RATE 	  : integer := 9600;
	constant	TX_FIFO_DEPTH : integer := 8;
	constant	RX_FIFO_DEPTH : integer := 8;
	
	
	signal sys_clk   		: std_logic;
	signal sys_res_n 		: std_logic;
	signal display_clk   : std_logic;
	
	
	signal data_out      : std_logic;
	signal instr_wr		: std_logic;
	signal instr			: std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
	signal new_ascii     : std_logic;
	signal ascii     		: std_logic_vector(7 downto 0);
	signal temp_rd			: std_logic;
	signal temp_empty		: std_logic;
	signal temp_rd_data  : std_logic_vector(7 downto 0);
	
	
	signal temp_scancode 	 : std_logic_vector (7 downto 0);  -- IP Cores(PS/2 Keyboard)
	signal temp_new_scancode : std_logic;
	signal instr_full 		 : std_logic; -- internal Wire
	
	-- Task2 color Signal
	signal temp_color   :  std_logic_vector ( 15 downto 0);
	
	-- Task5 button Signal
	signal button_out_sync : std_logic;
		
	-- Task6 internal signals Serial Port
	signal rx_rd_serial_port 	 : std_logic;
	signal rx_empty_serial_port :std_logic;
	signal rx_data_serial_port  : std_logic_vector ( 7 downto 0 );
	signal instr_full_serial_port	: std_logic;
	signal instr_serial_port 		: std_logic_vector (GCNTL_INSTR_WIDTH-1 downto 0);
	signal instr_wr_serial_port   : std_logic;
	
	-- Task6 internal wires between merge_fifo and graphics_controller
	signal instr_merge_fifo 		: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal instr_wr_merge_fifo    : std_logic; 
	signal instr_full_merge_fifo	: std_logic;
	
	-- damit ich ein Instanz von PLL benutzen kann
	component pll IS
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0				: OUT STD_LOGIC 
	);
	END component;
	
begin

	sys_clk <= clk;  -- nicht ein Teil von Component, deshalb ist es draussen
	ledg(7 downto 0) <= temp_scancode;  -- ledg <= ('Z' & temp_scancode)
	
	-- an Instance of pll
	pll_inst : pll
	port map (
		inclk0 => clk,      --instead of clk_in => clk
		c0 => display_clk   --instead of clk_out => display_clk
	);

	-- an Instance of syncLeft
	sys_reset_sync : sync 
	generic map (
			SYNC_STAGES => SYNC_STAGES,
			RESET_VALUE => '1'
	)
	port map (
		clk => sys_clk,
		res_n => '1',
		data_in => keys(0),
		data_out => sys_res_n 
	);
	
	-- an Instance of syncRight
	display_reset_sync : sync 
	generic map (
			SYNC_STAGES => SYNC_STAGES,
			RESET_VALUE => '1'
	)
	port map (
		clk => display_clk,
		res_n => '1',
		data_in => keys(0),
		data_out => data_out 
	);
	
	-- an Instance of graphics_controller
	gcntrl_inst : graphics_controller
	port map(
		clk => sys_clk,
		res_n => sys_res_n,
		
		instr_wr => instr_wr_merge_fifo,
		instr => instr_merge_fifo,
		
		display_clk => display_clk,
		display_res_n => data_out,
		sram_dq => sram_dq,
		
		-- we change it because of task2. Instead of open, we put temp_color 
		current_color => temp_color,
		instr_full => instr_full_merge_fifo,
		
		nclk => nclk,
		grest => grest,
		vd => vd,
		hd => hd,
		den => den,
		r => r,
		g => g,
		b => b,
		sda => sda,
		sram_addr => sram_addr,
		sram_ub_n => sram_ub_n,
		sram_lb_n => sram_lb_n,
		sram_we_n => sram_we_n,
		sram_ce_n => sram_ce_n,
		sram_oe_n => sram_oe_n	
	);
	
--------------------------------------------------------------------------------
--                             Figure 1 Ends here                             --
--------------------------------------------------------------------------------
	
	
	-- an Instant of ps2_keyboard_controller
	ps2_kbd_cntrl_inst : ps2_keyboard_controller
	generic map(
		 CLK_FREQ => SYS_CLK_FREQ,
		 SYNC_STAGES => SYNC_STAGES
	)
	port map(
			clk => sys_clk,
			res_n => sys_res_n,
			ps2_clk => ps2_clk,
			ps2_data => ps2_data,
			
			new_scancode => temp_new_scancode,
			scancode => temp_scancode
			
	);
	
	
	-- an Instant of ps2_ascii
	ps2_ascii_inst : ps2_ascii
	port map(
			clk => sys_clk,
			res_n => sys_res_n,
			new_scancode => temp_new_scancode,
		   scancode => temp_scancode,
			
			new_ascii => new_ascii,
			ascii => ascii
	);
	
	-- an Instant of fifo_lclrlw
	ascii_buffer : fifo_1c1r1w
	generic map(
			-- MIN_DEPTH defined in IP Cores
			MIN_DEPTH => PS2_BUFFER_DEPTH,			
			DATA_WIDTH => 8
	)
	port map(
			clk => sys_clk,
			res_n => sys_res_n,
			rd => temp_rd,   
			
			wr => new_ascii,
			wr_data => ascii,  
		
			empty => temp_empty,
			rd_data => temp_rd_data,   
			
			full => open,
			fill_level => open
				
	);
	
	-- an Instant of ascii_gcinstr
	ascii_gcinstr_instr : ascii_gcinstr
	port map(
			clk   => sys_clk,
			res_n => sys_res_n,
			
			ascii_empty => temp_empty,
			ascii_data  => temp_rd_data ,
			
			instr_full  => instr_full,
			instr_wr 	=> instr_wr,
			instr       => instr,
			ascii_rd    => temp_rd
	);
	
--------------------------------------------------------------------------------
--                             Figure 2 Ends here                             --
--------------------------------------------------------------------------------

	-- an Instant of seven_segment_display
	seven_segment_display_instance : seven_segment_display
	port map(
	
		color => temp_color,
		
		--2nd hex0 is the one from top.vhdl, 1st one is the one from seven_segment_display
		--we need to connect it to the Top Layer Entity, so it needs to be defined here as well
		hex0(6 downto 0) => hex0(6 downto 0),
		hex1(6 downto 0) => hex1(6 downto 0), 
		hex2(6 downto 0) => hex2(6 downto 0),
		hex3(6 downto 0) => hex3(6 downto 0),
		
		--Task5
		hex4(6 downto 0) => hex4(6 downto 0),	
		hex5(6 downto 0) => hex5(6 downto 0),
		clk => clk, 
		res_n => sys_res_n,
		button => button_out_sync    -- we have the problem with Modelsim because what comes out from
		
	);
	
	-- add this for seven segment display, for synchronizing
	sync_seven_segment : sync 
	generic map (
			SYNC_STAGES => SYNC_STAGES,
			RESET_VALUE => '1'
	)
	port map (
		clk => sys_clk,
		res_n => '1',
		data_in => keys(2),
		data_out => button_out_sync
	);
	
	
	-- an Instant of serial_port
	serial_port_intz : serial_port
	generic map(
		
		CLK_FREQ => SYS_CLK_FREQ,
		BAUD_RATE =>  BAUD_RATE,
		SYNC_STAGES => SYNC_STAGES ,
		TX_FIFO_DEPTH => TX_FIFO_DEPTH,
		RX_FIFO_DEPTH => RX_FIFO_DEPTH
	
	)
	port map(
	
		clk   => clk,	
		res_n => sys_res_n,
		
		--these 2 connected to the ps2_ascii(laut Angabe)
		tx_wr   => new_ascii,	
		tx_data => ascii,
		

		rx_rd	=> rx_rd_serial_port,
		
		-- map it to the corresponding pins(laut Angabe)
		rx	=>	rx,
		tx  => tx,	
		
		--laut Angabe
		tx_full => open,
		
		rx_data => rx_data_serial_port, 
		--rx_full 
		rx_empty => rx_empty_serial_port 
		
	);
	
	
	-- 2nd ascii_gcinstr_instrKeyb for the PC's keyboard
	ascii_gcinstr_instrKeyb : ascii_gcinstr
	port map(
			clk   => sys_clk,
			res_n => sys_res_n,
			
			ascii_empty => rx_empty_serial_port,
			ascii_data  => rx_data_serial_port,
			
			instr_full => instr_full_serial_port,
			instr_wr   => instr_wr_serial_port,
			instr      => instr_serial_port,
			ascii_rd   => rx_rd_serial_port 
	);
	
	
	-- an Instant of MergeFifo 
	merge_fifo_instance : merge_fifo
	generic map (
	
			DATA_WIDTH => 56   
	
	)
	port map (
	
			clk => clk,
			res_n => sys_res_n,  
			
			-- this is for the FPGA keyboard - richtig
			p0_data  =>  instr,   
			p0_wr 	=>  instr_wr,     
			p0_full  =>  instr_full,  
			
			
			-- this is for PC's keyboard
			p1_data  => instr_serial_port,    
			p1_wr 	=> instr_wr_serial_port,   	 
			p1_full  => instr_full_serial_port,     
				
			p2_data  => (others => '0'),       
			p2_wr 	=> '0',         
			p2_full  => open,    

			
			pout_data => instr_merge_fifo,
			pout_wr   => instr_wr_merge_fifo,   
			pout_full => instr_full_merge_fifo
	
	);

end architecture;
