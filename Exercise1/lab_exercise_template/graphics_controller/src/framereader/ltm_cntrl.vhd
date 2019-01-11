--! \file
--! \author Florian Huemer 

----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------
--! \brief Implements the interface of the LTM display
----------------------------------------------------------------------------------
entity ltm_cntrl is
	port (
		clk     : in  std_logic;
		res_n   : in  std_logic;

		data    : in std_logic_vector(23 downto 0); --! pixel data
		rd_data : out std_logic; --! read next pixel value from FIFO 
		
		-- connection to display
		hd      : out std_logic;	        --! horizontal sync signal
		vd      : out std_logic;            --! vertical sync signal
		den     : out std_logic;            --! data enable 
		r       : out std_logic_vector(7 downto 0);		--! pixel color value (red)
		g       : out std_logic_vector(7 downto 0);		--! pixel color value (green)
		b       : out std_logic_vector(7 downto 0);		--! pixel color value (blue)

		grest   : out std_logic		--! display reset
	);
end entity;


----------------------------------------------------------------------------------
--                               ARCHITECTURE                                   --
----------------------------------------------------------------------------------
architecture beh of ltm_cntrl is

constant CLK_PER_HORIZONTAL_LINE : integer := 1056;
constant H_LINE_PER_FRAME : integer := 525;

constant H_SYNC_BACK_PORCH : integer := 216;	-- in CLK-periods
constant H_SYNC_FRONT_PORCH : integer := 40;	-- in CLK-periods

constant VERTICAL_BACK_PORCH : integer := 35;	-- in Horizontal lines
constant VERTICAL_FRONT_PORCH : integer := 10;	-- in Horizontal lines

signal clk_cnt : integer range 0 to CLK_PER_HORIZONTAL_LINE ;
signal hline_cnt : integer range 0 to H_LINE_PER_FRAME ;

signal vertical_display_area : std_logic;


begin
    
	snyc : process(clk, res_n)
	begin

	if res_n = '0' then -- reset
		--reset counter signals
		clk_cnt <= 0;
		hline_cnt <= 0;

		hd <= '1';
		vd <= '1';
		rd_data <= '0';
		r <= (others => '0');
		g <= (others => '0');
		b <= (others => '0');
		den <= '0';
		grest <= '0'; 

	elsif rising_edge(clk) then

		hd <= '1'; -- idle state 1
		vd <= '1';
		r <= (others => '0');
		g <= (others => '0');
		b <= (others => '0');
		den <= '0';
		grest <= '1'; 
		rd_data <= '0';

		clk_cnt <= clk_cnt + 1; -- inc clk counter 

		if clk_cnt = 0 then 
			hd <= '0';
		end if;

		if vertical_display_area = '1' then 

			if clk_cnt >= (H_SYNC_BACK_PORCH - 2) and 
				clk_cnt < (CLK_PER_HORIZONTAL_LINE - H_SYNC_FRONT_PORCH-2) then 
				rd_data <= '1';
			end if;


			if clk_cnt > H_SYNC_BACK_PORCH-1  and 
				clk_cnt < (CLK_PER_HORIZONTAL_LINE - H_SYNC_FRONT_PORCH) then
				r <= data(23 downto 16);
				g <= data(15 downto 8);
				b <= data(7 downto 0);
				den <= '1'; 
			end if;

		end if;

		if clk_cnt = CLK_PER_HORIZONTAL_LINE - 1  then -- line complete
			clk_cnt <= 0;
			hline_cnt <= hline_cnt + 1; --inc line counter


			-- check for line counter overflow --> frame complete
			if hline_cnt = H_LINE_PER_FRAME - 1 then  
				hline_cnt <= 0;
			end if;

		end if;

		-- vertical sync
		if hline_cnt = 0 then 
		vd <= '0';
		end if;

	end if;

	end process;
  
	
	display_area : process(hline_cnt) 
	begin
		vertical_display_area <= '0';

		if hline_cnt >= VERTICAL_BACK_PORCH and --vertical back porch
		hline_cnt < (H_LINE_PER_FRAME - VERTICAL_FRONT_PORCH) then --vertical front porch
			vertical_display_area <= '1';
		end if;

	end process;
	
end architecture beh;



