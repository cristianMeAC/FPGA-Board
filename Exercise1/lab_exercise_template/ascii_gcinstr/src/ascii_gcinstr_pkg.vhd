library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.graphics_controller_pkg.all;

package ascii_gcinstr_pkg is

	component ascii_gcinstr is
		port (
			clk : in std_logic;
			res_n : in std_logic;
			ascii_rd : out std_logic;
			ascii_data : in std_logic_vector(7 downto 0);
			ascii_empty : in std_logic;
			instr : out std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
			instr_wr : out std_logic;
			instr_full : in std_logic
		);
	end component;
end package;

