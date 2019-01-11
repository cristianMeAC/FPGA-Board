-- Module:      	Rasterizer and Rasterizer FSM
-- Date:        	April 2011
-- Description: 	Component description of the Rasterizer and Rasterizer 
--					FSM. 
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package rasterizer_pkg is

	component rasterizer_fsm is
		generic (
			COLOR_DEPTH : integer := 3
		);
		port
		(
			clk : in std_logic;
			res_n : in std_logic;
			fb_addr : out std_logic_vector(18 downto 0);
			fb_data : out std_logic_vector(COLOR_DEPTH - 1 downto 0);
			fb_wr : out std_logic;
			fb_stall : in std_logic;
			instr : in std_logic_vector(55 downto 0);
			instr_rd : out std_logic;
			instr_empty : in std_logic;
			current_color : out std_logic_vector(COLOR_DEPTH-1 downto 0)
		);
	end component;

	component rasterizer is
		generic (
			INSTR_FIFO_DEPTH : integer := 8;
			COLOR_DEPTH : integer := 16;
			WB_ADDR_WIDTH : integer := 20
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
			wb_cyc_o : out std_logic;
			wb_stb_o : out std_logic;
			wb_we_o : out std_logic;
			wb_ack_i : in std_logic;
			wb_stall_i : in std_logic;
			wb_addr_o : out std_logic_vector(WB_ADDR_WIDTH-1 downto 0);
			wb_data_o : out std_logic_vector(15 downto 0);
			wb_data_i : in std_logic_vector(15 downto 0);
			wb_sel_o : out std_logic_vector(1 downto 0);
			instr : in std_logic_vector(8+48-1 downto 0);
			instr_wr : in std_logic;
			instr_full : out std_logic;
			current_color : out std_logic_vector(COLOR_DEPTH-1 downto 0)
		);
	end component;
	
	component fb_writer is
		generic (
			FB_ADDR_WIDTH : integer := 18;
			WB_ADDR_WIDTH : integer := 21;
			DATA_WIDTH : integer := 16
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
			fb_addr : in std_logic_vector(FB_ADDR_WIDTH-1 downto 0);
			fb_data : in std_logic_vector(DATA_WIDTH-1 downto 0);
			fb_stall : out std_logic;
			fb_wr : in std_logic;
			wb_cyc_o : out std_logic;
			wb_stb_o : out std_logic;
			wb_we_o : out std_logic;
			wb_ack_i : in std_logic;
			wb_stall_i : in std_logic;
			wb_addr_o : out std_logic_vector(WB_ADDR_WIDTH-1 downto 0);
			wb_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
			wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
			wb_sel_o : out std_logic_vector(1 downto 0)
		);
	end component;

end rasterizer_pkg;


