--! \file 
--! \author Florian Huemer

----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;

----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------
--! \brief Wishbone (pipelined mode) compatible SRAM controller
--! \details
--! fmax ~ 70MHz on Terasic DE2-115 \n
--! read access: 1 cycle \n
--! wrtie access: 3 cycles \n
----------------------------------------------------------------------------------
entity sram_controller_wb  is
	generic
	(
		ADDR_WIDTH : integer; --! address width of the SRAM
		DATA_WIDTH : integer --! data width of the SRAM
	);
	port
	(
		clk : in  std_logic;
		res_n : in std_logic;

		-- wb slave interface
		wb_cyc_i : in std_logic; --! wishbone slave: cycle 
		wb_stb_i : in std_logic; --! wishbone slave: strobe
		wb_we_i : in std_logic; --! wishbone write enable
		wb_addr_i : in std_logic_vector(ADDR_WIDTH-1 downto 0); --! wishbone slave: address
		wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0); --! wishbone slave: data in
		wb_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0); --! wishbone slave: data out
		wb_sel_i : in std_logic_vector(log2c(DATA_WIDTH/8) downto 0); --! wishbone slave: byteenable
		wb_ack_o : out std_logic; --! wishbone slave: acknowledge 
		wb_stall_o : out std_logic; --! wishbone slave: stall

		-- external interface
		sram_dq : inout std_logic_vector(DATA_WIDTH-1 downto 0);
		sram_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		sram_ub_n : out std_logic;
		sram_lb_n : out std_logic;
		sram_we_n : out std_logic;
		sram_ce_n : out std_logic;
		sram_oe_n : out std_logic
	);
end entity;


----------------------------------------------------------------------------------
--                               ARCHITECTURE                                   --
----------------------------------------------------------------------------------
architecture beh of sram_controller_wb is


	type sram_cntrl_state_type is (IDLE, WRITE0, WRITE1, READ);

	signal sram_cntrl_state : sram_cntrl_state_type;
	signal sram_cntrl_state_next : sram_cntrl_state_type;


	signal data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal data_out_next : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	
	--pipeline resgisters
	signal pipe_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal pipe_sel_n : std_logic_vector(log2c(DATA_WIDTH/8) downto 0);
	signal pipe_oe_n : std_logic;
	signal pipe_we_n : std_logic;
	signal pipe_ack : std_logic;
	signal pipe_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal pipe_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal pipe_addr_next : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal pipe_sel_n_next : std_logic_vector(log2c(DATA_WIDTH/8) downto 0);
	signal pipe_oe_n_next : std_logic;
	signal pipe_we_n_next : std_logic;
	signal pipe_ack_next : std_logic;
	signal pipe_data_next : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal pipe_data_out_next : std_logic_vector(DATA_WIDTH-1 downto 0);

	signal drive_output : std_logic;
	signal drive_output_next : std_logic;

begin

	----------------------------------------------------------
	--                     PIPELINE                         --
	----------------------------------------------------------
	
	process (wb_stb_i, wb_we_i, wb_addr_i, wb_sel_i, sram_dq, sram_cntrl_state, pipe_addr, pipe_data_out, pipe_sel_n, pipe_oe_n, wb_data_i, drive_output)
	begin
	
		drive_output_next <= drive_output;
	
		pipe_addr_next <= (others=>'0');
		pipe_sel_n_next <=(others=>'1');
		pipe_oe_n_next <= '1';
		pipe_ack_next <= '0';
		pipe_data_next <= (others=>'0');
		pipe_data_out_next <= (others=>'0');
		wb_stall_o <= '0';
		
		pipe_we_n_next <= '1';
	
		
		case sram_cntrl_state is
			when IDLE =>
				drive_output_next <= '0';
				
				if wb_stb_i = '1' then
					pipe_addr_next <= wb_addr_i;
					pipe_sel_n_next <= not wb_sel_i;
				
					if wb_we_i = '0' then --read access
						pipe_oe_n_next <= '0'; --low active
					else --write access
						pipe_we_n_next<= '1';
						pipe_data_out_next <= wb_data_i;
						drive_output_next <= '1';
						--wb_stall_o <= '1';
					end if;
				end if;
				
			when READ =>
				if wb_stb_i = '1' then
					if wb_we_i = '0' then --next pipelined read access
						pipe_addr_next <= wb_addr_i;
						pipe_sel_n_next <= not wb_sel_i;
						pipe_oe_n_next <= '0';
					else --write access 
						wb_stall_o <= '1'; -- a write access has to be stalled until all peding read request are handled
					end if;
				end if;	
				
				pipe_data_next <= sram_dq;
				pipe_ack_next <= not pipe_oe_n;
				
			
			when WRITE0 =>
				pipe_we_n_next<= '0';
				pipe_addr_next <= pipe_addr;
				pipe_data_out_next <= pipe_data_out;
				pipe_sel_n_next <= pipe_sel_n;
				pipe_ack_next <= '0';
				drive_output_next <= '1';
				
				wb_stall_o <= '1';	

		
			when WRITE1 =>
				pipe_addr_next <= pipe_addr;
				pipe_data_out_next <= pipe_data_out;
				pipe_sel_n_next <= pipe_sel_n;
				pipe_we_n_next<= '1';
				pipe_ack_next <= '1';
				drive_output_next <= '1';
				

				wb_stall_o <= '1';	

			
			
			when others =>
				null;
		end case;		
		
	end process;

	
	
	process (clk, res_n)
	begin
		if res_n='0' then
			drive_output <= '0';
			pipe_addr <= (others=>'0');
			pipe_sel_n <= (others=>'1');
			pipe_oe_n <= '1';
			pipe_data <= (others=>'0');
			pipe_ack <= '0';
			pipe_data_out <= (others=>'0');
			pipe_we_n <= '1';
		elsif rising_edge(clk) then
			drive_output <= drive_output_next;
			pipe_addr <= pipe_addr_next;
			pipe_sel_n <= pipe_sel_n_next;
			pipe_oe_n <= pipe_oe_n_next;
			pipe_data <= pipe_data_next;
			pipe_ack <= pipe_ack_next;
			pipe_data_out <= pipe_data_out_next;
			pipe_we_n <= pipe_we_n_next;
		end if;
	end process;
	
	
	sram_addr <= pipe_addr;
	sram_oe_n <= pipe_oe_n;
	sram_we_n <= pipe_we_n;
	sram_ub_n <= pipe_sel_n(1);
	sram_lb_n <= pipe_sel_n(0);
	sram_dq <= pipe_data_out when drive_output = '1' else (others=>'Z');
	wb_ack_o <= pipe_ack;
	wb_data_o <= pipe_data;
	
	----------------------------------------------------------

	
	sync : process(clk, res_n)
	begin
		if res_n = '0' then
			sram_cntrl_state <= IDLE;
			sram_ce_n <= '1';
		elsif rising_edge(clk) then
			sram_cntrl_state <= sram_cntrl_state_next;
			sram_ce_n <= '0';
		end if;
	end process; 

	
	next_state : process (sram_cntrl_state, wb_stb_i, wb_we_i, pipe_oe_n)
	begin
		sram_cntrl_state_next <= sram_cntrl_state;
		
		case sram_cntrl_state is
			when IDLE =>
				if wb_stb_i = '1' then
					if  wb_we_i = '1' then --write access
						sram_cntrl_state_next <= WRITE0;
					else --read access
						sram_cntrl_state_next <= READ;
					end if;	
				end if;
			
			when WRITE0 =>
				sram_cntrl_state_next <= WRITE1;
			
			when WRITE1 =>
				sram_cntrl_state_next <= IDLE;
		
			when READ =>
				sram_cntrl_state_next <= IDLE;
			
				if wb_stb_i = '1' and wb_we_i = '0' then
					sram_cntrl_state_next <= READ;
				end if;
				
				if wb_stb_i = '0' and pipe_oe_n = '0' then --pipe not empty
					sram_cntrl_state_next <= READ;
				end if;
				
			when others =>
				null;
		end case;
	
	end process;
	
	

end architecture beh;

--- EOF ---
