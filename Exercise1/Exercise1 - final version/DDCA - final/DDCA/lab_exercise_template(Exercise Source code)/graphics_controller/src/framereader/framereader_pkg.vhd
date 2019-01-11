--! \file

----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


package framereader_pkg is

	constant DISPLAY_WIDTH : integer := 800;
	constant DISPLAY_HEIGHT : integer := 480;
	type color_depth_type is (COLOR_DEPTH_8BIT, COLOR_DEPTH_16BIT, COLOR_DEPTH_24BIT);
	
	component framereader is
		generic (
			ADDR_WIDTH : integer := 20;
			DATA_WIDTH : integer := 16
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
			display_clk : in std_logic;
			color_depth : in color_depth_type;
			framebuffer_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
			frame_begin : out std_logic;
			wb_cyc_o : out std_logic;
			wb_stb_o : out std_logic;
			wb_we_o : out std_logic;
			wb_ack_i : in std_logic;
			wb_stall_i : in std_logic;
			wb_addr_o : out std_logic_vector(ADDR_WIDTH-1 downto 0);
			wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
			wb_sel_o : out std_logic_vector(1 downto 0);
			display_read : in std_logic;
			display_data_out : out std_logic_vector(23 downto 0)
		);
	end component;
	
	component ltm_cntrl is
		port (
			clk : in std_logic;
			res_n : in std_logic;
			data : in std_logic_vector(23 downto 0);
			rd_data : out std_logic;
			hd : out std_logic;
			vd : out std_logic;
			den : out std_logic;
			r : out std_logic_vector(7 downto 0);
			g : out std_logic_vector(7 downto 0);
			b : out std_logic_vector(7 downto 0);
			grest : out std_logic
		);
	end component;
end package;



