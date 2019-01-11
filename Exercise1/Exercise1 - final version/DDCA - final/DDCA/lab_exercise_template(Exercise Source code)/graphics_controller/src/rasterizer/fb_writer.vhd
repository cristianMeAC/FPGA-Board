--! \file

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.ram_pkg.all;


----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------
--! Wishbone memory controller for the cache cores
----------------------------------------------------------------------------------
entity fb_writer is
	generic (
		FB_ADDR_WIDTH : integer := 18;
		WB_ADDR_WIDTH : integer := 21;
		DATA_WIDTH : integer := 16
	);
	port (
		clk : in std_logic;
		res_n : in std_logic;

		-- write buffer FIFO
		fb_addr   : in  std_logic_vector(FB_ADDR_WIDTH-1 downto 0);
		fb_data   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		fb_stall  : out std_logic;
		fb_wr     : in  std_logic;
		
		-- wishbone master interface
		wb_cyc_o : out std_logic;
		wb_stb_o : out std_logic;
		wb_we_o : out std_logic;
		wb_ack_i : in std_logic;
		wb_stall_i : in std_logic;
		wb_addr_o : out std_logic_vector(WB_ADDR_WIDTH-1 downto 0);
		wb_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0); --! not used
		wb_sel_o : out std_logic_vector(1 downto 0)
	);
end entity;


architecture arch of fb_writer is

	constant MAX_WRITE_OPERATIONS : integer := 4;

	type state_type is (IDLE, WRITE, WAIT_ACK, TIMEOUT);

	signal state : state_type;
	signal state_next : state_type;
	
	signal ack_cnt : std_logic_vector(log2c(MAX_WRITE_OPERATIONS)-1 downto 0);
	signal ack_cnt_next : std_logic_vector(log2c(MAX_WRITE_OPERATIONS)-1 downto 0);
	
	signal req_cnt : std_logic_vector(log2c(MAX_WRITE_OPERATIONS)-1 downto 0);
	signal req_cnt_next : std_logic_vector(log2c(MAX_WRITE_OPERATIONS)-1 downto 0);
		
	signal disable_stb : std_logic;
	signal disable_stb_next : std_logic;
	
	signal fifo_data_in, fifo_data_out : std_logic_vector(DATA_WIDTH+FB_ADDR_WIDTH-1 downto 0);

	signal fifo_out_fb_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal fifo_out_fb_addr : std_logic_vector(FB_ADDR_WIDTH-1 downto 0);
	
	
	signal fifo_rd, fifo_empty : std_logic;
begin
	fifo_data_in <= fb_addr & fb_data;
	fifo_out_fb_data <= fifo_data_out(DATA_WIDTH-1 downto 0);
	fifo_out_fb_addr <= fifo_data_out(FB_ADDR_WIDTH+DATA_WIDTH-1 downto DATA_WIDTH);
	
	framebuffer_fifo : fifo_1c1r1w
		generic map (
			MIN_DEPTH => 64,
			DATA_WIDTH => DATA_WIDTH+FB_ADDR_WIDTH
		)
		port map (
			clk             => clk,
			res_n           => res_n,
			wr_data         => fifo_data_in,
			wr              => fb_wr,
			rd              => fifo_rd,
			rd_data         => fifo_data_out,
			empty           => fifo_empty,
			full            => fb_stall
		);


	sync : process(clk, res_n)
	begin
		if res_n='0' then
			state <= IDLE;
			req_cnt <= (others=>'0');
			ack_cnt <= (others=>'0');
			disable_stb <= '0';
		elsif rising_edge(clk) then
			state <= state_next;
			req_cnt <= req_cnt_next;
			ack_cnt <= ack_cnt_next;
			disable_stb <= disable_stb_next;
		end if;
		
	end process;
	
	
	next_state : process (state, req_cnt, ack_cnt, fifo_empty, wb_ack_i, wb_stall_i, disable_stb, fifo_out_fb_addr, fifo_out_fb_data) 
	begin
		state_next <= state;
		req_cnt_next <= req_cnt;
		ack_cnt_next <= ack_cnt;
		
		wb_cyc_o <= '0'; 
		wb_stb_o <= '0';
		wb_we_o <= '0';
		wb_data_o <= (others=>'0');
		wb_addr_o <= (others=>'0'); 
		wb_sel_o <= (others=>'1');
		
		fifo_rd <= '0';
		disable_stb_next <= disable_stb;
		
		case state is
			when IDLE =>
				
				ack_cnt_next <= (others=>'0');--0;
				disable_stb_next <= '0';
				
				if fifo_empty = '0' then --fifo is not empty --> data has to be written to memory
					state_next <= WRITE;
					req_cnt_next <= (others=>'0');--0;
					ack_cnt_next <= (others=>'0'); -- initialized with 0
					fifo_rd <= '1';
				end if;
			
			when TIMEOUT => 
				state_next <= IDLE;
			
			when WAIT_ACK => 
	
				wb_cyc_o <= '1';
				wb_stb_o <= '0';
				wb_we_o <= '0';
				wb_data_o <= fifo_out_fb_data;
				wb_addr_o <= (others=>'0');
				wb_addr_o(FB_ADDR_WIDTH-1 downto 0) <= fifo_out_fb_addr;
				wb_sel_o <= "11";

				if (wb_ack_i = '1') then
					
					if (ack_cnt = req_cnt) then
						state_next <= TIMEOUT;
						req_cnt_next <= (others=>'0');
						disable_stb_next <= '1';
					else
						ack_cnt_next <= std_logic_vector(unsigned(ack_cnt) + 1);
					end if;
				end if;
		

			when WRITE =>
				wb_cyc_o <= '1';
				wb_stb_o <= '1';
				wb_we_o <= '1';
				wb_data_o <= fifo_out_fb_data;
				wb_addr_o <= (others=>'0');
				wb_addr_o(FB_ADDR_WIDTH-1 downto 0) <= fifo_out_fb_addr;
				wb_sel_o <= "11";
				
				
				if (wb_stall_i = '0') then
					if (unsigned(req_cnt) /=  MAX_WRITE_OPERATIONS-1 and fifo_empty = '0') then --is there data left to write
						fifo_rd <= '1'; -- get new data
						req_cnt_next <= std_logic_vector(unsigned(req_cnt) + 1);
					else
						state_next <= WAIT_ACK;
					end if;
				end if;
				
				
				if (wb_ack_i = '1') then
					ack_cnt_next <= std_logic_vector(unsigned(ack_cnt) + 1);
				end if;
				
			
			when others =>
		
		end case;
	
	end process;
	

end architecture;








