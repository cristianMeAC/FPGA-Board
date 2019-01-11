
library ieee;
use ieee.std_logic_1164.all;

package ps2_pkg is
	component ps2_keyboard_controller is
		generic (
			CLK_FREQ : integer;
			SYNC_STAGES : integer
		);
		port (
			clk : in std_logic;
			res_n : in std_logic;
			new_scancode : out std_logic;
			scancode : out std_logic_vector(7 downto 0);
			ps2_clk : inout std_logic;
			ps2_data : inout std_logic
		);
	end component;
end package;
