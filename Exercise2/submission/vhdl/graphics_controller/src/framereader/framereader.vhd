--! \file
--! \author Florian Huemer

----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.ram_pkg.all;
use work.framereader_pkg.all;

LIBRARY altera_mf;
USE altera_mf.all;

----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------
--! \brief Reads the framebuffer for the display controller
--! \details
--!This component continually reads the framebuffer, translates the data to a 24 bit RGB format (based on the currently selected color depth) and stores these pixel values in a dual clocked fifo, which can be read by the display controller. At the beginning of each frame the start address of the framebuffer is updated (input framebuffer_addr) because the location of the framebuffer is set by the rasterizer. The DFU in turn signals the rasterizer that it is (re)starting to fetch the framebuffer by the frame_begin signal. This information is used in double buffered applications to synchronize the switch of the framebuffer.
----------------------------------------------------------------------------------
entity framereader is 

	generic (
		ADDR_WIDTH : integer := 20;
		DATA_WIDTH : integer := 16
	);
	port (
		clk : in std_logic;
		res_n : in std_logic;

		display_clk : in std_logic;

		--cfg and control interface
		color_depth : in color_depth_type;
		
		framebuffer_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		frame_begin : out std_logic;
		
		--wb master interface
		wb_cyc_o : out std_logic;
		wb_stb_o : out std_logic;
		wb_we_o : out std_logic;
		wb_ack_i : in std_logic;
		wb_stall_i : in std_logic;
		wb_addr_o : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_sel_o : out std_logic_vector(1 downto 0);
		
		--display controller interface
		display_read : in std_logic;
		display_data_out : out std_logic_vector(23 downto 0)
	);
	
end entity;


----------------------------------------------------------------------------------
--                               ARCHITECTURE                                   --
----------------------------------------------------------------------------------
architecture beh of framereader is 

	
	--signal color_depth : color_depth_type := COLOR_DEPTH_16BIT;
	
	constant FIFO_DEPTH : integer := 1024;
	constant DISPLAY_WIDTH : integer := 800/2; --> 8 bit color depth
	constant DISPLAY_WIDTH_16BIT : integer := 800; --> 8 bit color depth
	constant DISPLAY_HEIGHT : integer := 480;
	

	signal addr_counter : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal addr_counter_next : std_logic_vector(ADDR_WIDTH-1 downto 0);
	
	
	signal addr_counter_max : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal addr_counter_max_next : std_logic_vector(ADDR_WIDTH-1 downto 0);
	

	-- fifo interface signals 
	signal fifo_data_in : std_logic_vector(15 downto 0);
	signal fifo_data_out : std_logic_vector(15 downto 0);
	signal fifo_wr : std_logic;
	signal fifo_rd : std_logic;
	signal fifo_fill_level : std_logic_vector(log2c(FIFO_DEPTH)-1 downto 0);
	signal fifo_empty : std_logic;
	signal fifo_halffull : std_logic;

	-- dc fifo interface signals
	signal dcfifo_data_in : std_logic_vector(23 downto 0);
	signal dcfifo_data_out : std_logic_vector(23 downto 0);
	signal dcfifo_wr : std_logic;
	signal dcfifo_rd : std_logic;
	--signal dcfifo_empty : std_logic; -- dont required, if this FIFO ever runs empty we are in trouble
	signal dcfifo_full : std_logic;
	
	
	type dfu_state_type is (IDLE, STATE_FRAME_BEGIN, READ, WAIT_FOR_ACK, BUS_CYCLE_COMPLETE);
	

	signal dfu_state : dfu_state_type;
	signal dfu_state_next : dfu_state_type;
	
	type fc_fsm_state_type is (IDLE1, READ_8BIT_DEPTH_0, READ_8BIT_DEPTH_1, READ_16BIT_DEPTH);  
	signal fc_fsm_state : fc_fsm_state_type;
	signal fc_fsm_state_next : fc_fsm_state_type;
	
	signal res : std_logic;
	
	COMPONENT dcfifo
		GENERIC (
			intended_device_family		: STRING;
			lpm_numwords		: NATURAL;
			lpm_showahead		: STRING;
			lpm_type		: STRING;
			lpm_width		: NATURAL;
			lpm_widthu		: NATURAL;
			overflow_checking		: STRING;
			rdsync_delaypipe		: NATURAL;
			read_aclr_synch		: STRING;
			underflow_checking		: STRING;
			use_eab		: STRING;
			write_aclr_synch		: STRING;
			wrsync_delaypipe		: NATURAL
		);
		PORT (
			aclr	: IN STD_LOGIC ;
			data	: IN STD_LOGIC_VECTOR (23 DOWNTO 0);
			rdclk	: IN STD_LOGIC ;
			rdreq	: IN STD_LOGIC ;
			wrclk	: IN STD_LOGIC ;
			wrreq	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
			rdempty	: OUT STD_LOGIC ;
			wrfull	: OUT STD_LOGIC 
		);
	END COMPONENT;
begin
	
	res <= not res_n;
	
	sync : process(clk, res_n)
	begin
		if res_n = '0' then
			addr_counter <= (others=>'0');
			addr_counter_max <= (others=>'0');
			dfu_state <= IDLE;
		elsif rising_edge(clk) then
			addr_counter <= addr_counter_next;
			addr_counter_max <= addr_counter_max_next;
			dfu_state <= dfu_state_next;
		end if;
	end process;
	
	
	fsm : process(dfu_state, fifo_halffull, addr_counter, addr_counter_max, framebuffer_addr, wb_ack_i, wb_stall_i, color_depth)
	begin
		dfu_state_next <= dfu_state; 
		frame_begin <= '0';
		
		addr_counter_next <= addr_counter;
		addr_counter_max_next <= addr_counter_max;
		
		-- wishbone signals
		wb_cyc_o <= '0';
		wb_stb_o <= '0';
		wb_we_o <= '0';
		wb_sel_o <= "11";
		
		case dfu_state is 
			when IDLE =>
				if fifo_halffull = '0' then
					dfu_state_next <= STATE_FRAME_BEGIN;
				end if;
				
				
			when STATE_FRAME_BEGIN =>
				frame_begin <= '1';
				addr_counter_next <= framebuffer_addr;
				
				if color_depth = COLOR_DEPTH_8BIT then
					addr_counter_max_next <= std_logic_vector(unsigned(framebuffer_addr)+((800*480)/2));
				elsif color_depth = COLOR_DEPTH_16BIT then
					addr_counter_max_next <= std_logic_vector(unsigned(framebuffer_addr)+(800*480));
				end if;
				
				dfu_state_next <= READ;
				
			when READ =>
				
				wb_cyc_o <= '1';
				wb_stb_o <= '1';
				wb_we_o <= '0';
				
				if wb_stall_i = '0' then	-- keep address stable if stalled
					addr_counter_next <= std_logic_vector(unsigned(addr_counter) + 1);
				end if;
				
				
				if addr_counter(3 downto 0) = "1111" then
					dfu_state_next <= WAIT_FOR_ACK;
				end if;
	
			when WAIT_FOR_ACK =>
				wb_cyc_o <= '1';
				dfu_state_next <= dfu_state;
				if wb_ack_i = '0' then
					dfu_state_next <= BUS_CYCLE_COMPLETE;
				end if;
				
				
			when BUS_CYCLE_COMPLETE => 
				if addr_counter = addr_counter_max then
					dfu_state_next <= IDLE;
				else
					if fifo_halffull = '0' then
						dfu_state_next <= READ;
					end if;
				end if; 
				
			when others =>
				null;
		end case;
		
	end process;
	

	wb_addr_o <= addr_counter;
	
	
	fifo_wr <= wb_ack_i;
	fifo_data_in <= wb_data_i;
	fifo_halffull <= fifo_fill_level(fifo_fill_level'length-1);

	-- fifo
	fifo : fifo_1c1r1w 
		generic map
		(
			DATA_WIDTH => 16,
			MIN_DEPTH => FIFO_DEPTH,
			FILL_LEVEL_COUNTER => "ON"
		)
		port map 
		(
			clk => clk,
			res_n => res_n,
			
			wr => fifo_wr,
			wr_data => fifo_data_in,
			
			rd => fifo_rd,
			rd_data => fifo_data_out,
			
			fill_level => fifo_fill_level,
			empty => fifo_empty
		);
		
		
	---------------------------------------------------------------------
	--            STATE MACHINE FOR DCFIFO CONNECTION                  --
	---------------------------------------------------------------------
	
	fc_fsm_sync : process (clk, res_n)
	begin
		if res_n = '0' then
			fc_fsm_state <= IDLE1;
		elsif rising_edge(clk) then
			fc_fsm_state <= fc_fsm_state_next;
		end if;
	end process;
	
	fc_fsm_next_state : process(fc_fsm_state, fifo_empty, dcfifo_full, color_depth)
	begin
	
		fc_fsm_state_next <= fc_fsm_state;
		
		
		case fc_fsm_state is
			when IDLE1 =>
				if fifo_empty = '0' then
					if color_depth = COLOR_DEPTH_8BIT then
						fc_fsm_state_next <= READ_8BIT_DEPTH_0; 		
					end if;
					if color_depth = COLOR_DEPTH_16BIT then
						fc_fsm_state_next <= READ_16BIT_DEPTH; 	
					end if;
				end if;
			
			when READ_8BIT_DEPTH_0 =>
				if dcfifo_full='0' then
					fc_fsm_state_next <= READ_8BIT_DEPTH_1;
				end if;
				
			when READ_8BIT_DEPTH_1 =>
				if fifo_empty = '0' then
					if dcfifo_full='0' then
						fc_fsm_state_next <= READ_8BIT_DEPTH_0;
					end if;
				else
					fc_fsm_state_next <= IDLE1;
				end if;
				
			when READ_16BIT_DEPTH =>
				if fifo_empty = '0' then
					if dcfifo_full='0' then
						fc_fsm_state_next <= READ_16BIT_DEPTH;
					end if;
				else
					fc_fsm_state_next <= IDLE1;
				end if;
			
			when others =>
				null;
		end case;
	end process;
	
	
	fc_fsm_output : process(fc_fsm_state, fifo_empty, fifo_data_out, dcfifo_full)
		variable buffer_8bit : std_logic_vector(7 downto 0);
	begin
		
		fifo_rd <= '0';
		dcfifo_wr <= '0';
		buffer_8bit := fifo_data_out(7 downto 0);
		dcfifo_data_in <= (others=>'0');
		
		case fc_fsm_state is
			when IDLE1 =>
				if fifo_empty = '0' then
					fifo_rd <= '1';
				end if;
			
			when READ_8BIT_DEPTH_0 =>
				--rgb 3-3-2
				if dcfifo_full='0' then
					dcfifo_wr <= '1';
				end if;
				buffer_8bit := fifo_data_out(7 downto 0);

			when READ_8BIT_DEPTH_1 =>
				buffer_8bit := fifo_data_out(15 downto 8);
				if dcfifo_full='0' then
					dcfifo_wr <= '1';
					if fifo_empty = '0' then
						fifo_rd <= '1';
					end if;
				end if;
			
			when READ_16BIT_DEPTH =>
				
				-- rgb 5-6-5	
				dcfifo_data_in(23 downto 16) <= fifo_data_out(15 downto 11) & fifo_data_out(15 downto 13);  --red
				dcfifo_data_in(15 downto 8) <= fifo_data_out(10 downto 5) & fifo_data_out(10 downto 9);     --green
				dcfifo_data_in(7 downto 0) <= fifo_data_out(4 downto 0)  & fifo_data_out(4 downto 2);       --blue
				
				--dcfifo_data_in(23 downto 16) <= fifo_data_out(15 downto 12) & (3 downto 0 => fifo_data_out(11));  --red
				--dcfifo_data_in(15 downto 8) <= fifo_data_out(10 downto 6) & (2 downto 0 => fifo_data_out(5));     --green
				--dcfifo_data_in(7 downto 0) <= fifo_data_out(4 downto 1)  & (3 downto 0 => fifo_data_out(1));      --blue
				
				if dcfifo_full='0' then
					dcfifo_wr <= '1';
					if fifo_empty = '0' then
						fifo_rd <= '1';
					end if;
				end if;
		end case;
		
		
		if fc_fsm_state = READ_8BIT_DEPTH_0 or fc_fsm_state = READ_8BIT_DEPTH_1 then
			dcfifo_data_in(23 downto 16) <=  buffer_8bit(7 downto 5) & buffer_8bit(7 downto 5) & buffer_8bit(7 downto 6); --red
			dcfifo_data_in(15 downto 8) <=  buffer_8bit(4 downto 2) & buffer_8bit(4 downto 2) & buffer_8bit(4 downto 3); -- green
			--dcfifo_data_in(7 downto 4) <= (others=>buffer_8bit(1)); -- blue
			--dcfifo_data_in(3 downto 0) <= (others=>buffer_8bit(0));
			
			
			if buffer_8bit(7 downto 5) = "111" then
				dcfifo_data_in(23 downto 16) <= (others=>'1');
			elsif buffer_8bit(7 downto 5) = "110" then
				dcfifo_data_in(23 downto 16) <= (23=>'1', 22=>'1', 21=>'1', others=>'0');
			elsif buffer_8bit(7 downto 5) = "101" then
				dcfifo_data_in(23 downto 16) <= (23=>'1', 22=>'1', others=>'0');
			elsif buffer_8bit(7 downto 5) = "100" then
				dcfifo_data_in(23 downto 16) <= (23=>'1', 21=>'1', 19=>'1', 18=>'1', others=>'0');
			elsif buffer_8bit(7 downto 5) = "011" then
				dcfifo_data_in(23 downto 16) <= (23=>'1', 21=>'1', others=>'0');
			elsif buffer_8bit(7 downto 5) = "010" then
				dcfifo_data_in(23 downto 16) <= (23=>'1', others=>'0');
			elsif buffer_8bit(7 downto 5) = "001" then
				dcfifo_data_in(23 downto 16) <= (22=>'1', 21=>'1', 20=>'1', 19=>'1', others=>'0');
			elsif buffer_8bit(7 downto 5) = "000" then
				dcfifo_data_in(23 downto 16) <= (others=>'0');
			end if;
	
	
			-- green
			if buffer_8bit(4 downto 2) = "111" then
				dcfifo_data_in(15 downto 8) <= (others=>'1');
			elsif buffer_8bit(4 downto 2) = "110" then
				dcfifo_data_in(15 downto 8) <= (15=>'1', 14=>'1', 13=>'1', others=>'0');
			elsif buffer_8bit(4 downto 2) = "101" then
				dcfifo_data_in(15 downto 8) <= (15=>'1', 14=>'1', others=>'0');
			elsif buffer_8bit(4 downto 2) = "100" then
				dcfifo_data_in(15 downto 8) <= (15=>'1', 13=>'1', 11=>'1', 10=>'1', others=>'0');
			elsif buffer_8bit(4 downto 2) = "011" then
				dcfifo_data_in(15 downto 8) <= (15=>'1', 13=>'1', others=>'0');
			elsif buffer_8bit(4 downto 2) = "010" then
				dcfifo_data_in(15 downto 8) <= (15=>'1', others=>'0');
			elsif buffer_8bit(4 downto 2) = "001" then
				dcfifo_data_in(15 downto 8) <= (14=>'1', 13=>'1', 12=>'1', 11=>'1', others=>'0');
			elsif buffer_8bit(4 downto 2) = "000" then
				dcfifo_data_in(15 downto 8) <= (others=>'0');
			end if;
			
	
			dcfifo_data_in(7) <= (buffer_8bit(1) or buffer_8bit(0));
			dcfifo_data_in(6) <= buffer_8bit(1);
			dcfifo_data_in(5) <= buffer_8bit(1) and buffer_8bit(0);
			dcfifo_data_in(4 downto 0) <= (others=>buffer_8bit(0));
			
			
		end if;
		
		
		
	end process;
	

	dcfifo_component : dcfifo
	generic map (
		intended_device_family => "Cyclone IV E",
		lpm_numwords => 1024,
		lpm_showahead => "OFF",
		lpm_type => "dcfifo",
		lpm_width => 24,
		lpm_widthu => 10,
		overflow_checking => "ON",
		rdsync_delaypipe => 4,
		read_aclr_synch => "OFF",
		underflow_checking => "ON",
		use_eab => "ON",
		write_aclr_synch => "ON",
		wrsync_delaypipe => 4
	)
	port map (
		aclr => res,
		data => dcfifo_data_in,
		rdclk => display_clk,
		rdreq => dcfifo_rd,
		wrclk => clk,
		wrreq => dcfifo_wr,
		q => dcfifo_data_out,
		rdempty => open,
		wrfull => dcfifo_full
	);

--	dcfifo : fifo_1c1r1w 
--		generic map (
--			DATA_WIDTH => 24,
--			MIN_DEPTH => 16
--		)
--		port map (
--			clk => clk,
--			res_n => res_n,

--			data_out1 => dcfifo_data_out,
--			rd1 => dcfifo_rd,

--			data_in2 => dcfifo_data_in,
--			wr2 => dcfifo_wr,

--			empty => dcfifo_empty,
--			full => dcfifo_full
--		);
--		
--		
		dcfifo_rd <= display_read;
		display_data_out <= dcfifo_data_out;
	
	
end architecture;



