library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.math_pkg.all;

package wb_arbiter_pkg is

	component wb_arbiter is
		generic (
			NODE_COUNT : integer range 2 to 8 := 2;
			ADDR_WIDTH : integer := 20;
			DATA_WIDTH : integer := 16
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
			wb_addr_o : out std_logic_vector(ADDR_WIDTH-1 downto 0);
			wb_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
			wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
			wb_sel_o : out std_logic_vector( log2c(DATA_WIDTH/8) downto 0);
			wb_cyc_o : out std_logic;
			wb_stb_o : out std_logic;
			wb_we_o : out std_logic;
			wb_ack_i : in std_logic;
			wb_stall_i : in std_logic;
			wb_node_addr_i : in std_logic_vector((ADDR_WIDTH*NODE_COUNT)-1 downto 0);
			wb_node_data_i : in std_logic_vector((DATA_WIDTH*NODE_COUNT)-1 downto 0);
			wb_node_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
			wb_node_sel_i : in std_logic_vector( ((log2c(DATA_WIDTH/8)+1)*NODE_COUNT)-1 downto 0);
			wb_node_cyc_i : in std_logic_vector(NODE_COUNT-1 downto 0);
			wb_node_stb_i : in std_logic_vector(NODE_COUNT-1 downto 0);
			wb_node_we_i : in std_logic_vector(NODE_COUNT-1 downto 0);
			wb_node_ack_o : out std_logic_vector(NODE_COUNT-1 downto 0);
			wb_node_stall_o : out std_logic_vector(NODE_COUNT-1 downto 0)
		);
	end component;
end package;

