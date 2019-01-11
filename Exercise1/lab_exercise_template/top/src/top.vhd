
--------------------------------------------------------------------------------
--                                LIBRARIES                                   --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- import all required packages
use work.sync_pkg.all;


--------------------------------------------------------------------------------
--                                 ENTITY                                     --
--------------------------------------------------------------------------------

entity top is
	port (
		--50 MHz clock input
		clk      : in  std_logic;

		-- push buttons and switches
		keys     : in std_logic_vector(3 downto 0);
		switches : in std_logic_vector(17 downto 0);
	
		--Seven segment digit
		hex0 : out std_logic_vector(6 downto 0);
		hex1 : out std_logic_vector(6 downto 0);
		hex2 : out std_logic_vector(6 downto 0);
		hex3 : out std_logic_vector(6 downto 0);
		hex4 : out std_logic_vector(6 downto 0);
		hex5 : out std_logic_vector(6 downto 0);
		hex6 : out std_logic_vector(6 downto 0);
		hex7 : out std_logic_vector(6 downto 0);

		-- the grren LEDs
		ledg : out std_logic_vector(8 downto 0);

		-- external interface to SRAM
		sram_dq : inout std_logic_vector(15 downto 0);
		sram_addr : out std_logic_vector(19 downto 0);
		sram_ub_n : out std_logic;
		sram_lb_n : out std_logic;
		sram_we_n : out std_logic;
		sram_ce_n : out std_logic;
		sram_oe_n : out std_logic;
		
		-- LCD interface
		nclk    : out std_logic;
		hd      : out std_logic;
		vd      : out std_logic;
		den     : out std_logic;
		r       : out std_logic_vector(7 downto 0);
		g       : out std_logic_vector(7 downto 0);
		b       : out std_logic_vector(7 downto 0);
		grest   : out std_logic;
		sda     : out std_logic;
		
		-- PS/2
		ps2_clk   : inout std_logic;
		ps2_data  :inout std_logic
	);
end entity;


--------------------------------------------------------------------------------
--                             ARCHITECTURE                                   --
--------------------------------------------------------------------------------

-- add your architecture here!
