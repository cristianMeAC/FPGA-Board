library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package graphics_controller_pkg is

	constant DISPLAY_WIDTH : integer := 800;
	constant DISPLAY_HEIGHT : integer := 480;
	constant SRAM_ADDRESS_WIDTH : integer := 20;

	constant GCNTL_INSTR_CLEAR_SCREEN   : std_logic_vector(7 downto 0) := x"55";
	constant GCNTL_INSTR_CHANGE_COLOR   : std_logic_vector(7 downto 0) := x"01";
	constant GCNTL_INSTR_SET_PIXEL      : std_logic_vector(7 downto 0) := x"02";
	constant GCNTL_INSTR_DRAW_LINE      : std_logic_vector(7 downto 0) := x"03";
	constant GCNTL_INSTR_DRAW_RECTANGLE : std_logic_vector(7 downto 0) := x"04";
	constant GCNTL_INSTR_DRAW_CIRCLE    : std_logic_vector(7 downto 0) := x"05";

	constant GCNTL_INSTR_WIDTH : integer := 56;
	constant GCNTL_COLOR_DEPTH : integer := 16;

	-- The Width for RGB
	constant GCNTL_COLOR_RED_WIDTH : integer := 5;
	constant GCNTL_COLOR_GREEN_WIDTH : integer := 6;
	constant GCNTL_COLOR_BLUE_WIDTH : integer := 5;

	function get_blue(color : std_logic_vector) return std_logic_vector;
	function get_green(color : std_logic_vector) return std_logic_vector;
	function get_red(color : std_logic_vector) return std_logic_vector;

	component graphics_controller is
		port (
			clk : in std_logic;
			res_n : in std_logic;
			display_clk : in std_logic;
			display_res_n : in std_logic;
			instr : in std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
			instr_wr : in std_logic;
			instr_full : out std_logic;
			current_color : out std_logic_vector(GCNTL_COLOR_DEPTH-1 downto 0);
			sram_dq : inout std_logic_vector(15 downto 0);
			sram_addr : out std_logic_vector(19 downto 0);
			sram_ub_n : out std_logic;
			sram_lb_n : out std_logic;
			sram_we_n : out std_logic;
			sram_ce_n : out std_logic;
			sram_oe_n : out std_logic;
			nclk : out std_logic;
			hd : out std_logic;
			vd : out std_logic;
			den : out std_logic;
			r : out std_logic_vector(7 downto 0);
			g : out std_logic_vector(7 downto 0);
			b : out std_logic_vector(7 downto 0);
			grest : out std_logic;
			sda : out std_logic
		);
	end component;
end package;

package body graphics_controller_pkg is

	function get_blue(color : std_logic_vector) return std_logic_vector is
		variable blue : std_logic_vector(GCNTL_COLOR_BLUE_WIDTH-1 downto 0);
	begin
		blue := color(GCNTL_COLOR_BLUE_WIDTH-1 downto 0);
		return blue;
	end function;
	
	function get_green(color : std_logic_vector) return std_logic_vector is
		variable green : std_logic_vector(GCNTL_COLOR_GREEN_WIDTH-1 downto 0);
	begin
		green := color(GCNTL_COLOR_GREEN_WIDTH+GCNTL_COLOR_BLUE_WIDTH-1 downto GCNTL_COLOR_BLUE_WIDTH);
		return green;
	end function;

	function get_red(color : std_logic_vector) return std_logic_vector is
		variable red : std_logic_vector(GCNTL_COLOR_RED_WIDTH-1 downto 0);
	begin
		red := color(GCNTL_COLOR_RED_WIDTH+GCNTL_COLOR_GREEN_WIDTH+GCNTL_COLOR_BLUE_WIDTH-1 downto GCNTL_COLOR_BLUE_WIDTH+GCNTL_COLOR_GREEN_WIDTH);
		return red;
	end function;

end package body;

