library ieee;
use ieee.std_logic_1164.all;


use work.graphics_controller_pkg.all;
use work.framereader_pkg.all;
use work.rasterizer_pkg.all;
use work.wb_arbiter_pkg.all;
use work.sram_pkg.all;


----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------

entity graphics_controller is
	port (
		clk   : in std_logic;
		res_n : in std_logic;
		
		display_clk   : in std_logic;
		display_res_n : in std_logic;
	
		--instruction interface
		instr      : in std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
		instr_wr   : in std_logic;
		instr_full : out std_logic;
		
		--status information
		current_color : out std_logic_vector(GCNTL_COLOR_DEPTH-1 downto 0);
		
		--external interface to sram
		sram_dq : inout std_logic_vector(15 downto 0);
		sram_addr : out std_logic_vector(SRAM_ADDRESS_WIDTH-1 downto 0);
		sram_ub_n : out std_logic;
		sram_lb_n : out std_logic;
		sram_we_n : out std_logic;
		sram_ce_n : out std_logic;
		sram_oe_n : out std_logic;
		
		--external interface to LCD 
		nclk    : out std_logic;
		hd      : out std_logic;
		vd      : out std_logic;
		den     : out std_logic;
		r       : out std_logic_vector(7 downto 0);
		g       : out std_logic_vector(7 downto 0);
		b       : out std_logic_vector(7 downto 0);
		grest   : out std_logic;
		sda     : out std_logic
	);
end entity;


architecture arch of graphics_controller is
	constant WB_DATA_BUS_WIDTH : integer := 16;
	constant WB_ADDR_BUS_WIDTH : integer := SRAM_ADDRESS_WIDTH;

	-- data fetching unit
	signal framereader_wb_cyc_o : std_logic;
	signal framereader_wb_stb_o : std_logic;
	signal framereader_wb_we_o : std_logic;
	signal framereader_wb_addr_o : std_logic_vector(WB_ADDR_BUS_WIDTH-1 downto 0);
	signal framereader_wb_data_i : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal framereader_wb_sel_o : std_logic_vector(1 downto 0);
	signal framereader_wb_ack_i : std_logic;
	signal framereader_wb_stall_i : std_logic;
	
	-- rasterizer
	signal rasterizer_wb_cyc_o : std_logic;
	signal rasterizer_wb_stb_o : std_logic;
	signal rasterizer_wb_we_o : std_logic;
	signal rasterizer_wb_addr_o : std_logic_vector(WB_ADDR_BUS_WIDTH-1 downto 0);
	signal rasterizer_wb_data_o : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal rasterizer_wb_data_i : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal rasterizer_wb_sel_o : std_logic_vector(1 downto 0);
	signal rasterizer_wb_ack_i : std_logic;
	signal rasterizer_wb_stall_i : std_logic;
	
	
	-- bus arbiter
	signal arbiter_nodes_wb_addr_i : std_logic_vector((WB_ADDR_BUS_WIDTH*2)-1 downto 0);
	signal arbiter_nodes_wb_data_i : std_logic_vector((WB_DATA_BUS_WIDTH*2)-1 downto 0);
	signal arbiter_nodes_wb_data_o : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal arbiter_nodes_wb_sel_i : std_logic_vector( 3 downto 0);
	signal arbiter_nodes_wb_cyc_i : std_logic_vector(1 downto 0);
	signal arbiter_nodes_wb_stb_i : std_logic_vector(1 downto 0); 
	signal arbiter_nodes_wb_we_i : std_logic_vector(1 downto 0);
	signal arbiter_nodes_wb_ack_o : std_logic_vector(1 downto 0);
	signal arbiter_nodes_wb_stall_o : std_logic_vector(1 downto 0);
	
	signal arbiter_wb_cyc_o : std_logic;
	signal arbiter_wb_stb_o : std_logic;
	signal arbiter_wb_we_o : std_logic;
	signal arbiter_wb_addr_o : std_logic_vector(WB_ADDR_BUS_WIDTH-1 downto 0);
	signal arbiter_wb_data_o : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal arbiter_wb_data_i : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal arbiter_wb_sel_o : std_logic_vector(1 downto 0);
	signal arbiter_wb_ack_i : std_logic;
	signal arbiter_wb_stall_i : std_logic;

	-- sram wishbone signals
	signal sram_cntrl_wb_cyc_i : std_logic;
	signal sram_cntrl_wb_stb_i : std_logic;
	signal sram_cntrl_wb_we_i : std_logic;
	signal sram_cntrl_wb_addr_i : std_logic_vector(WB_ADDR_BUS_WIDTH-1 downto 0);
	signal sram_cntrl_wb_data_i : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal sram_cntrl_wb_data_o : std_logic_vector(WB_DATA_BUS_WIDTH-1 downto 0);
	signal sram_cntrl_wb_sel_i : std_logic_vector(1 downto 0);
	signal sram_cntrl_wb_ack_o : std_logic;
	signal sram_cntrl_wb_stall_o : std_logic;


	-- signals between rasterizer and frame buffer
	signal frame_buffer_wr_data : std_logic_vector(GCNTL_COLOR_DEPTH-1 downto 0);
	signal frame_buffer_wr_addr : std_logic_vector(18 downto 0);
	signal frame_buffer_wr :  std_logic;
	
	-- signals between frame buffer and display controller
	signal frame_buffer_rd_data : std_logic_vector(GCNTL_COLOR_DEPTH-1 downto 0);
	signal frame_buffer_rd_addr : std_logic_vector(18 downto 0);
	signal frame_buffer_rd :  std_logic;
	
	--signal between framereader and ltm
	signal ltm_rd : std_logic;
	signal ltm_data : std_logic_vector(23 downto 0);
	
begin
	
	rasterizer_inst : rasterizer
	generic map (
		INSTR_FIFO_DEPTH       => 64,
		COLOR_DEPTH            => 16,
		WB_ADDR_WIDTH          => WB_ADDR_BUS_WIDTH
	)
	port map (
		clk             => clk,
		res_n           => res_n,
		wb_cyc_o        => rasterizer_wb_cyc_o,
		wb_stb_o        => rasterizer_wb_stb_o,
		wb_we_o         => rasterizer_wb_we_o,
		wb_ack_i        => rasterizer_wb_ack_i,
		wb_stall_i      => rasterizer_wb_stall_i,
		wb_addr_o       => rasterizer_wb_addr_o,
		wb_data_o       => rasterizer_wb_data_o,
		wb_data_i       => rasterizer_wb_data_i,
		wb_sel_o        => rasterizer_wb_sel_o,
		instr           => instr,
		instr_wr        => instr_wr,
		instr_full      => instr_full,
		current_color   => current_color
	);

	the_arbiter : wb_arbiter
	generic map (
		NODE_COUNT => 2,
		ADDR_WIDTH => 20, 
		DATA_WIDTH => 16
	)
	port map (
		clk => clk,
		res_n => res_n,

		wb_cyc_o   => sram_cntrl_wb_cyc_i,
		wb_stb_o   => sram_cntrl_wb_stb_i,
		wb_we_o    => sram_cntrl_wb_we_i,
		wb_addr_o  => sram_cntrl_wb_addr_i,
		wb_data_o  => sram_cntrl_wb_data_i,
		wb_data_i  => sram_cntrl_wb_data_o,
		wb_sel_o   => sram_cntrl_wb_sel_i,
		wb_ack_i   => sram_cntrl_wb_ack_o,
		wb_stall_i => sram_cntrl_wb_stall_o,
	
	
		wb_node_addr_i  => arbiter_nodes_wb_addr_i,
		wb_node_data_i  => arbiter_nodes_wb_data_i,
		wb_node_data_o  => arbiter_nodes_wb_data_o,
		wb_node_sel_i   => arbiter_nodes_wb_sel_i,
		wb_node_cyc_i   => arbiter_nodes_wb_cyc_i,
		wb_node_stb_i   => arbiter_nodes_wb_stb_i,
		wb_node_we_i    => arbiter_nodes_wb_we_i,
		wb_node_ack_o   => arbiter_nodes_wb_ack_o,
		wb_node_stall_o => arbiter_nodes_wb_stall_o
	);

	arbiter_nodes_wb_cyc_i  <= framereader_wb_cyc_o        & rasterizer_wb_cyc_o  ;
	arbiter_nodes_wb_stb_i  <= framereader_wb_stb_o        & rasterizer_wb_stb_o  ;
	arbiter_nodes_wb_we_i   <= framereader_wb_we_o         & rasterizer_wb_we_o   ;
	arbiter_nodes_wb_addr_i <= framereader_wb_addr_o       & rasterizer_wb_addr_o ;
	arbiter_nodes_wb_data_i <= x"0000"                     & rasterizer_wb_data_o ;
	arbiter_nodes_wb_sel_i  <= framereader_wb_sel_o        & rasterizer_wb_sel_o  ;
	
	framereader_wb_ack_i    <= arbiter_nodes_wb_ack_o(1);
	rasterizer_wb_ack_i     <= arbiter_nodes_wb_ack_o(0);
	
	framereader_wb_stall_i  <= arbiter_nodes_wb_stall_o(1);
	rasterizer_wb_stall_i   <= arbiter_nodes_wb_stall_o(0);
	
	framereader_wb_data_i   <= arbiter_nodes_wb_data_o;
	rasterizer_wb_data_i    <= arbiter_nodes_wb_data_o;

	sram_cntrl : sram_controller_wb
	generic map (
		ADDR_WIDTH => SRAM_ADDRESS_WIDTH,
		DATA_WIDTH => 16
	)
	port map (
		clk => clk,
		res_n => res_n,

		-- wb slave interface
		wb_cyc_i   => sram_cntrl_wb_cyc_i,
		wb_stb_i   => sram_cntrl_wb_stb_i,
		wb_we_i    => sram_cntrl_wb_we_i,
		wb_addr_i  => sram_cntrl_wb_addr_i,
		wb_data_i  => sram_cntrl_wb_data_i,
		wb_data_o  => sram_cntrl_wb_data_o,
		wb_sel_i   => sram_cntrl_wb_sel_i,
		wb_ack_o   => sram_cntrl_wb_ack_o,
		wb_stall_o => sram_cntrl_wb_stall_o,

		-- external interface
		sram_dq => sram_dq,
		sram_addr => sram_addr,
		sram_ub_n => sram_ub_n,
		sram_lb_n => sram_lb_n,
		sram_we_n => sram_we_n,
		sram_ce_n => sram_ce_n,
		sram_oe_n => sram_oe_n
	);

	--data fetching unit
	framereader_inst : framereader
	generic map (
		ADDR_WIDTH => 20,
		DATA_WIDTH => 16
	)
	port map (
		clk => clk,
		res_n => res_n,

		display_clk => display_clk,

		color_depth => COLOR_DEPTH_16BIT,
		framebuffer_addr => (others=>'0'),
		frame_begin => open,

		--wb master interface
		wb_cyc_o => framereader_wb_cyc_o,
		wb_stb_o => framereader_wb_stb_o,
		wb_we_o => framereader_wb_we_o,
		wb_ack_i => framereader_wb_ack_i,
		wb_stall_i => framereader_wb_stall_i, 
		wb_addr_o => framereader_wb_addr_o,
		wb_data_i => framereader_wb_data_i, 
		wb_sel_o => framereader_wb_sel_o,
		
		display_read => ltm_rd,
		display_data_out => ltm_data
	);
	
	-- display controller
	ltm : ltm_cntrl
	port map (
		clk     => display_clk,
		res_n   => display_res_n,

		data    => ltm_data, --x"aa00cc",
		rd_data => ltm_rd,

		hd      => hd,
		vd      => vd,
		den     => den,
		r       => r,
		g       => g,
		b       => b,
		grest   => grest
	);
	
	nclk <= display_clk;
	sda <= '0';
end architecture;




