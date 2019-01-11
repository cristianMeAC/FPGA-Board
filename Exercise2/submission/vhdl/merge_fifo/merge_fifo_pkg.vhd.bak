library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package merge_fifo_pkg is

	component merge_fifo is
		generic (
			DATA_WIDTH : integer := 8
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
			p0_data : in std_logic_vector (DATA_WIDTH-1 downto 0);
			p0_wr : in std_logic;
			p0_full : out std_logic;
			p1_data : in std_logic_vector (DATA_WIDTH-1 downto 0);
			p1_wr : in std_logic;
			p1_full : out std_logic;
			p2_data : in std_logic_vector (DATA_WIDTH-1 downto 0);
			p2_wr : in std_logic;
			p2_full : out std_logic;
			pout_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
			pout_wr : out std_logic;
			pout_full : in std_logic
		);
	end component;
end package;

