----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.ram_pkg.all;
use work.graphics_controller_pkg.all;
use work.rasterizer_pkg.all;

----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------

entity rasterizer is
	generic (
		INSTR_FIFO_DEPTH : integer := 8;
		COLOR_DEPTH : integer := 16;
		WB_ADDR_WIDTH : integer := 20
		
	);
	port (
		clk     : in  std_logic;
		res_n   : in  std_logic;

		-- wishbone master interface
		wb_cyc_o   : out std_logic;
		wb_stb_o   : out std_logic;
		wb_we_o    : out std_logic;
		wb_ack_i   : in std_logic;
		wb_stall_i : in std_logic;
		wb_addr_o  : out std_logic_vector(WB_ADDR_WIDTH-1 downto 0);
		wb_data_o  : out std_logic_vector(15 downto 0);
		wb_data_i  : in std_logic_vector(15 downto 0); --! not used
		wb_sel_o   : out std_logic_vector(1 downto 0);
		
		current_color : out std_logic_vector(COLOR_DEPTH-1 downto 0);
		
		--instruction interface
		instr       : in std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
		instr_wr    : in std_logic;
		instr_full  : out std_logic
	);
end entity;


architecture struct of rasterizer is

	signal instruction_fifo_read : std_logic;
	signal instruction : std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
	signal instruction_fifo_empty : std_logic;

	signal fb_addr : std_logic_vector(18 downto 0);
	signal fb_data : std_logic_vector(COLOR_DEPTH - 1 downto 0);
	signal fb_stall, fb_wr : std_logic;
begin
	instruction_fifo : fifo_1c1r1w
	generic map (
		MIN_DEPTH => INSTR_FIFO_DEPTH,
		DATA_WIDTH => instr'length
	)
	port map (
		clk       => clk,
		res_n     => res_n,
		wr_data   => instr,
		wr        => instr_wr,
		rd        => instruction_fifo_read,
		rd_data   => instruction,
		empty     => instruction_fifo_empty,
		full      => instr_full
	);

	rasterizer_unit : rasterizer_fsm
	generic map (
		COLOR_DEPTH => COLOR_DEPTH
	)
	port map (
		clk          => clk,
		res_n        => res_n,
		
		fb_addr      => fb_addr,
		fb_data      => fb_data,
		fb_wr        => fb_wr,
		fb_stall     => fb_stall,
	
		instr        => instruction,
		instr_rd     => instruction_fifo_read,
		instr_empty  => instruction_fifo_empty,
		
		current_color => current_color
	);

	wb_mem_cntrl_inst : fb_writer
	generic map (
		FB_ADDR_WIDTH => 19,
		WB_ADDR_WIDTH => WB_ADDR_WIDTH,
		DATA_WIDTH    => 16
	)
	port map (
		clk        => clk,
		res_n      => res_n,
		fb_addr    => fb_addr,
		fb_data    => fb_data,
		fb_stall   => fb_stall,
		fb_wr      => fb_wr,
		wb_cyc_o   => wb_cyc_o,
		wb_stb_o   => wb_stb_o,
		wb_we_o    => wb_we_o,
		wb_ack_i   => wb_ack_i,
		wb_stall_i => wb_stall_i,
		wb_addr_o  => wb_addr_o,
		wb_data_o  => wb_data_o,
		wb_data_i  => wb_data_i,
		wb_sel_o   => wb_sel_o
	);


end architecture struct;




