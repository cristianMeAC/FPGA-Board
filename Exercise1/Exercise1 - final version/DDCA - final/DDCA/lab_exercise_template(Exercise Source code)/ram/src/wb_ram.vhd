--! \file


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------
--! A generic Wishbone(pipelined mode) compatible on-chip RAM 
----------------------------------------------------------------------------------
entity wb_ram is
	generic
	(
		ADDR_WIDTH : integer;
		BYTE_WIDTH : integer := 8;
		BYTES : integer
	);
	port 
	(
		clk : in std_logic;
		wb_cyc_i : in std_logic;
		wb_stb_i : in std_logic;
		wb_we_i : in std_logic;
		wb_ack_o : out std_logic;
		wb_stall_o : out std_logic;
		wb_addr_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		wb_data_i : in std_logic_vector(BYTES*BYTE_WIDTH-1 downto 0);
		wb_data_o : out std_logic_vector(BYTES*BYTE_WIDTH-1 downto 0);
		wb_sel_i : in std_logic_vector(BYTES-1 downto 0)
	);
end entity;	
	


architecture syn of wb_ram is

	type word_t is array (0 to BYTES-1) of std_logic_vector(BYTE_WIDTH-1 downto 0);
	type ram_t is array (0 to (2**ADDR_WIDTH)-1) of word_t;
	signal ram : ram_t := (others => (others => (others=>'0') ) );
	signal q_local : word_t;
	
begin

	
	--Re-organize the read data from the RAM to match the output
	unpack: for i in 0 to BYTES-1 generate
		wb_data_o(BYTE_WIDTH*(i+1) - 1 downto 8*i) <= q_local(i);
	end generate unpack;
	
	wb_stall_o <= '0';
	
	read : process(clk)
	begin
		if(rising_edge(clk)) then
			if (wb_cyc_i and wb_stb_i and not wb_we_i) = '1' then
				q_local <= ram(to_integer(unsigned(wb_addr_i)));
			end if;
		end if;
	end process;
	
	ack : process (clk)
	begin
		if rising_edge(clk) then
			if (wb_cyc_i and wb_stb_i) = '1' then
				wb_ack_o <= '1';
			else
				wb_ack_o <= '0';
			end if; 
		end if;
	end process;
	
	
	-- some extra code to be pseudo generic :)
	BYTES_1 : if BYTES = 1 generate 
		process(clk)
		begin
			if(rising_edge(clk)) then
				if((wb_cyc_i and wb_stb_i and wb_we_i) = '1') then
					if(wb_sel_i(0) = '1') then
						ram(to_integer(unsigned(wb_addr_i)))(0) <= wb_data_i(BYTE_WIDTH-1 downto 0);
					end if;
				end if;
			end if;
		end process;
	end generate;
	
	BYTES_2 : if BYTES = 2 generate 
		process(clk)
		begin
			if(rising_edge(clk)) then
				if((wb_cyc_i and wb_stb_i and wb_we_i) = '1') then
					if(wb_sel_i(0) = '1') then
						ram(to_integer(unsigned(wb_addr_i)))(0) <= wb_data_i(7 downto 0);
					end if;
					if wb_sel_i(1) = '1' then
						ram(to_integer(unsigned(wb_addr_i)))(1) <= wb_data_i(15 downto 8);
					end if;
				end if;
			end if;
		end process;
	end generate;
	
	BYTES_3 : if BYTES = 3 generate 
		process(clk)
		begin
			if(rising_edge(clk)) then
				if((wb_cyc_i and wb_stb_i and wb_we_i) = '1') then
					if(wb_sel_i(0) = '1') then
						ram(to_integer(unsigned(wb_addr_i)))(0) <= wb_data_i(7 downto 0);
					end if;
					if wb_sel_i(1) = '1' then
						ram(to_integer(unsigned(wb_addr_i)))(1) <= wb_data_i(15 downto 8);
					end if;
					if wb_sel_i(2) = '1' then
						ram(to_integer(unsigned(wb_addr_i)))(2) <= wb_data_i(23 downto 16);
					end if;
				end if;
			end if;
		end process;
	end generate;
	
	
	BYTES_4 : if BYTES = 4 generate 
		process(clk)
		begin
			if(rising_edge(clk)) then
				if((wb_cyc_i and wb_stb_i and wb_we_i) = '1') then
					if(wb_sel_i(0) = '1') then
						ram(to_integer(unsigned(wb_addr_i)))(0) <= wb_data_i(7 downto 0);
					end if;
					if wb_sel_i(1) = '1' then
						ram(to_integer(unsigned(wb_addr_i)))(1) <= wb_data_i(15 downto 8);
					end if;
					if wb_sel_i(2) = '1' then
						ram(to_integer(unsigned(wb_addr_i)))(2) <= wb_data_i(23 downto 16);
					end if;
					if wb_sel_i(3) = '1' then
						ram(to_integer(unsigned(wb_addr_i)))(3) <= wb_data_i(31 downto 24);
					end if;
				end if;
			end if;
		end process;
	end generate;

end architecture;


	
