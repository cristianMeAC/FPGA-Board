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
--! \brief A priority arbiter for the Wishbone bus
--! \details
--!This arbiter grants a Wishbone Master Interface access to one Wishbone Slave Interface, based on static priorities. Every master that wants to access the slave interface asserts the cyc_o signal. Until the arbiter eventually grants access to the bus the stall_i signal of the master interface will be asserted. 
--!Note that once a master is granted bus access the arbiter will not interrupt the transfer. This may lead to bus monopolization if the Wishbone masters don't end their bus cycle by themselves to let the arbiter select another master.
---------------------------------------------------------------------------------- 
entity wb_arbiter is 
	generic (
		NODE_COUNT : integer range 2 to 8 := 2;
		ADDR_WIDTH : integer := 20; 
		DATA_WIDTH : integer := 16
	);
	port (
		clk : in std_logic;
		res_n : in std_logic;

		wb_addr_o : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		wb_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_sel_o : out std_logic_vector( log2c(DATA_WIDTH/8) downto 0);
		wb_cyc_o : out std_logic;
		wb_stb_o : out std_logic;
		wb_we_o : out std_logic;
		wb_ack_i : in std_logic; 
		wb_stall_i : in std_logic;
	
		wb_node_addr_i : in std_logic_vector((ADDR_WIDTH*NODE_COUNT)-1 downto 0);
		wb_node_data_i : in std_logic_vector((DATA_WIDTH*NODE_COUNT)-1 downto 0);
		wb_node_data_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_node_sel_i : in std_logic_vector( ((log2c(DATA_WIDTH/8)+1)*NODE_COUNT)-1 downto 0);
		wb_node_cyc_i : in std_logic_vector(NODE_COUNT-1 downto 0);
		wb_node_stb_i : in std_logic_vector(NODE_COUNT-1 downto 0); 
		wb_node_we_i : in std_logic_vector(NODE_COUNT-1 downto 0);
		wb_node_ack_o : out std_logic_vector(NODE_COUNT-1 downto 0);
		wb_node_stall_o : out std_logic_vector(NODE_COUNT-1 downto 0)
	);
end entity;


----------------------------------------------------------------------------------
--                               ARCHITECTURE                                   --
----------------------------------------------------------------------------------
architecture arch of wb_arbiter is 
	
	constant BYTE_ENABLE_LINE_WIDTH : integer := log2c(DATA_WIDTH/8)+1;
	
	type data_lines_type is array(NODE_COUNT-1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal data_lines : data_lines_type := (others => (others => '0') );
	
	type address_lines_type is array(NODE_COUNT-1 downto 0) of std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal address_lines : address_lines_type := (others => (others => '0') );

	type sel_lines_type is array(NODE_COUNT-1 downto 0) of std_logic_vector(log2c(DATA_WIDTH/8) downto 0);
	signal sel_lines : sel_lines_type := (others => (others => '0') );
	
	signal selected_node : integer range 0 to NODE_COUNT-1;
	signal selected_node_next : integer range 0 to NODE_COUNT-1;
	
begin


	data_expander : process(wb_node_data_i, wb_node_addr_i, wb_node_sel_i)
	begin
		
		for i in 0 to NODE_COUNT-1 loop
			data_lines(i) <= wb_node_data_i( ((i+1)*DATA_WIDTH)-1 downto (i*DATA_WIDTH));
		end loop;
		
		for i in 0 to NODE_COUNT-1 loop
			address_lines(i) <= wb_node_addr_i( ((i+1)*ADDR_WIDTH)-1 downto (i*ADDR_WIDTH));
		end loop;
		
		for i in 0 to NODE_COUNT-1 loop
			sel_lines(i) <= wb_node_sel_i( ((i+1)*BYTE_ENABLE_LINE_WIDTH)-1 downto (i*BYTE_ENABLE_LINE_WIDTH));
		end loop;
	
	end process;

	arbiter : process (wb_node_cyc_i, selected_node) 
		variable selected_node_temp : integer range 0 to NODE_COUNT-1;
	begin
		selected_node_temp := selected_node;
		--priority scheduler
	
		if wb_node_cyc_i(selected_node) = '0' then --select new node 
			for i in 0 to NODE_COUNT-1 loop 
				if wb_node_cyc_i(i) = '1' then
					selected_node_temp := i;
				end if;
			end loop;
			
		end if;
		
		selected_node_next <= selected_node_temp;
		
	end process;


	output : process(wb_node_cyc_i, address_lines, data_lines, sel_lines, wb_node_stb_i, wb_node_we_i, wb_ack_i, wb_stall_i, wb_data_i, selected_node_next)
	begin

		wb_addr_o <= address_lines(selected_node_next);
		wb_data_o <= data_lines(selected_node_next);
		wb_sel_o <= sel_lines(selected_node_next);
		wb_cyc_o <= wb_node_cyc_i(selected_node_next);
		wb_stb_o <= wb_node_stb_i(selected_node_next);
		wb_we_o <= wb_node_we_i(selected_node_next);
		
		wb_node_ack_o <= (others=>'0');
		wb_node_ack_o(selected_node_next) <= wb_ack_i;
		
		wb_node_stall_o <= (others=>'1');
		wb_node_stall_o(selected_node_next) <= wb_stall_i;
		
		wb_node_data_o <= wb_data_i;

	end process;


	sync : process(clk, res_n)
	begin
		if res_n='0' then
			selected_node <= 0;
		elsif rising_edge(clk) then
			selected_node <= selected_node_next;
		end if;
	end process;

end architecture;


