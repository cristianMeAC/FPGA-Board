--------------------------------------------------------------------------------
--                                LIBRARIES                                   --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rom_pkg.all;

--------------------------------------------------------------------------------
--                                 ENTITY                                     --
--------------------------------------------------------------------------------

-- Read only memory
entity rom_sync_1r is
	generic (
		ADDR_WIDTH   : integer;
		DATA_WIDTH   : integer;
		INIT_PATTERN : rom_array
	);
	port (
		clk  : in  std_logic;
		addr : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
		rd   : in  std_logic;
		data : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end entity ;

--------------------------------------------------------------------------------
--                               ARCHITECTURE                                 --
--------------------------------------------------------------------------------

architecture beh of rom_sync_1r is
	constant rom : rom_array(0 to 2 ** ADDR_WIDTH - 1, DATA_WIDTH - 1 downto 0) := INIT_PATTERN;
begin
	sync : process(clk)
	begin
		if rising_edge(clk) then
			if rd = '1' then
				data <= to_stdlogicvector(rom, to_integer(unsigned(addr)));
			end if;
		end if;
	end process;
end architecture;
