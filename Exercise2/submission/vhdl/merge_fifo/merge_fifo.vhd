
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity merge_fifo is
	generic (
		DATA_WIDTH : integer := 8
	);
	port (
		clk  : in std_logic;
		res_n : in std_logic;
		--input ports
		p0_data : in std_logic_vector (DATA_WIDTH-1 downto 0);
		p0_wr   : in std_logic;
		p0_full : out std_logic;
		p1_data : in std_logic_vector (DATA_WIDTH-1 downto 0);
		p1_wr   : in std_logic;
		p1_full : out std_logic;
		p2_data : in std_logic_vector (DATA_WIDTH-1 downto 0);
		p2_wr   : in std_logic;
		p2_full : out std_logic;
		--output ports
		pout_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
		pout_wr   : out std_logic;
		pout_full : in std_logic
	);
end entity;

--old data read during write behavior
architecture ARCH of merge_fifo is

	component alt_fwft_fifo is
		generic (
			DATA_WIDTH : integer := 32;
			NUM_ELEMENTS : integer
		);
		port (
			clock : in STD_LOGIC;
			aclr : in STD_LOGIC;
			data : in STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
			wrreq : in STD_LOGIC;
			full : out STD_LOGIC;
			new_data : out STD_LOGIC;
			rdack : in STD_LOGIC;
			q : out STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
	signal res : std_logic;
	signal p0_fifo_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal p1_fifo_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal p2_fifo_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal p0_rdack, p1_rdack, p2_rdack : std_logic;
	signal p0_new_data, p1_new_data, p2_new_data : std_logic;
begin
	res <= not res_n;

	p0_fifo : alt_fwft_fifo
	generic map (
		DATA_WIDTH   => DATA_WIDTH,
		NUM_ELEMENTS => 8
	)
	port map (
		aclr  => res,
		clock => clk,
		data  => p0_data,
		full  => p0_full,
		wrreq => p0_wr,
		rdack => p0_rdack,
		new_data => p0_new_data,
		q     => p0_fifo_data_out
	);

	p1_fifo : alt_fwft_fifo
	generic map (
		DATA_WIDTH   => DATA_WIDTH,
		NUM_ELEMENTS => 8
	)
	port map (
		aclr  => res,
		clock => clk,
		data  => p1_data,
		full  => p1_full,
		wrreq => p1_wr,
		rdack => p1_rdack,
		new_data => p1_new_data,
		q     => p1_fifo_data_out
	);

	p2_fifo : alt_fwft_fifo
	generic map (
		DATA_WIDTH   => DATA_WIDTH,
		NUM_ELEMENTS => 8
	)
	port map (
		aclr  => res,
		clock => clk,
		data  => p2_data,
		full  => p2_full,
		wrreq => p2_wr,
		rdack => p2_rdack,
		new_data => p2_new_data,
		q     => p2_fifo_data_out
	);


	process (
		pout_full,
		p0_new_data, p1_new_data, p2_new_data,
		p0_fifo_data_out, p1_fifo_data_out, p2_fifo_data_out)
	begin
		p0_rdack <= '0';
		p1_rdack <= '0';
		p2_rdack <= '0';
	
		pout_wr <= '0';
		pout_data <= p0_fifo_data_out;
		
		if (pout_full = '0') then
			if (p0_new_data = '1') then
				pout_wr <= '1';
				p0_rdack <= '1';
				pout_data <= p0_fifo_data_out;
			elsif (p1_new_data  = '1') then
				pout_wr <= '1';
				p1_rdack <= '1';
				pout_data <= p1_fifo_data_out;
			elsif (p2_new_data  = '1') then
				pout_wr <= '1';
				p2_rdack <= '1';
				pout_data <= p2_fifo_data_out;
			end if;
		end if;
	end process;

end architecture;

