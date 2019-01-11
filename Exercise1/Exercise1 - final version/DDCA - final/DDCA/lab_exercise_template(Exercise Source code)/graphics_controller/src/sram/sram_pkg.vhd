--! \file

----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.math_pkg.all;

package sram_pkg is


component sram_controller_wb  is
	generic
	(
		-- address width
		ADDR_WIDTH : integer;
		-- data width
		DATA_WIDTH : integer
	);
	port
	(
		clk : in  std_logic;
		res_n : in std_logic;

		-- wb slave interface
		wb_cyc_i : in std_logic;
		wb_stb_i : in std_logic;
		wb_we_i : in std_logic;
		wb_addr_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_sel_i : in std_logic_vector(log2c(DATA_WIDTH/8) downto 0); --byteenable
		wb_ack_o : out std_logic;
		wb_stall_o : out std_logic;

		-- external interface
		sram_dq : inout std_logic_vector(DATA_WIDTH-1 downto 0);
		sram_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		sram_ub_n : out std_logic;
		sram_lb_n : out std_logic;
		sram_we_n : out std_logic;
		sram_ce_n : out std_logic;
		sram_oe_n : out std_logic
	);
end component;


end sram_pkg;



