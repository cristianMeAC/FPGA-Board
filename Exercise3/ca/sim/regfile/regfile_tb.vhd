library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;


use work.regfile;


entity regfile_tb is
end entity;


architecture beh of regfile_tb is

	
	constant CLK_PER : time := 20 ns;
	
	signal clk, reset        : std_logic;
	signal stall             : std_logic;
	signal rdaddr1, rdaddr2  : std_logic_vector(REG_BITS-1 downto 0);
	signal rddata1, rddata2  : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal wraddr            : std_logic_vector(REG_BITS-1 downto 0);
	signal wrdata            : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal regwrite          : std_logic;


begin


	inst : entity work.regfile
	port map (clk => clk, reset => reset, stall => stall, rdaddr1 => rdaddr1,
		rdaddr2 => rdaddr2, rddata1 => rddata1, rddata2 => rddata2, 
		wraddr => wraddr, wrdata => wrdata, regwrite => regwrite);



	clock_p : process
	begin
		clk <= '0';
		wait for CLK_PER/2;
		clk <= '1';
		wait for CLK_PER/2;
	end process;


	test_p : process
	begin
		
		reset <= '0';
		
		stall <= '0';
		rdaddr1 <= (others => '0');
		rdaddr2 <= (others => '0');
		wraddr  <= (others => '0');
		wrdata  <= (others => '0');
		regwrite <= '0';
		
		wait for CLK_PER/2;
		wait for CLK_PER*10;
		
		-------------------
		-- test reset
		-------------------
		reset <= '1';
		rdaddr1 <= (others => '1');
		rdaddr2 <= (others => '1');
		wraddr  <= (others => '1');
		wait for CLK_PER;
		reset <= '0';
		-- internal saved address values should be on 0
		wait for CLK_PER*10;
		
		reset <= '1';
		-------------------
		-- normal test
		-- NOTE: reordering tests or adding new things between them
		-- might break the tests
		-------------------
		regwrite <= '1';
		
		rdaddr1 <= (others => '0'); -- should read 0
		rdaddr2 <= (0 => '1', others => '0'); -- should read 0
		wraddr  <= (1 => '1', others => '0'); 
		wrdata  <= (3 => '1', others => '0'); -- writing 00..08 to addres 2
		wait for CLK_PER;
		rdaddr1 <= (1 => '1', others => '0'); -- should read 00..08
		rdaddr2 <= (others => '0'); --should read 0
		wraddr  <= (others => '1');
		wrdata  <= (0 to 7 => '1', others => '0'); -- write 00..0FF to last address
		wait for CLK_PER;
		-- read and write at the same time
		rdaddr1 <= (0 => '0', others => '1'); -- should read 1011.. (written this clock) 
		rdaddr2 <= (others => '1'); -- should read 00..0FF
		wraddr  <= (0 => '0', others => '1');
		wrdata  <= (DATA_WIDTH-2 => '0', others => '1'); -- write 1011.. to pre-last address
		wait for CLK_PER;
		-- try reset for a clock, shouldn't impact anything
		reset <= '0';
		wait for CLK_PER;
		reset <= '1';
		-- read and write to 0 at the same time
		rdaddr1 <= (others => '0'); -- should read 0
		rdaddr2 <= (1 => '1', others => '0'); -- should read 8 as before, even after reset
		wraddr  <= (others => '0');
		wrdata  <= (4 to 7 => '0', others => '1'); -- try to write FF...F0F to 0, should fail
		wait for CLK_PER;
		-- two reads from write at the same time
		rdaddr1 <= (4 => '0', others => '1');
		rdaddr2 <= (4 => '0', others => '1');
		wraddr  <= (4 => '0', others => '1');
		wrdata  <= (DATA_WIDTH-8 to DATA_WIDTH-1 => '0', 0 to 7 => '0', others => '1'); -- write 0FF..FF0 to 10111
		wait for CLK_PER;
		
		-- test writing without regwrite (shouldn't be possible)
		regwrite <= '0'; -- TODO see in simulation if wraddr_saved is correct; is it relevant at all?
		
		rdaddr1 <= (1 => '1', others => '0'); -- should read 0..08 as before
		rdaddr2 <= (4 => '0', others => '1'); -- should read 0FF..FF0
		wraddr  <= (0 => '1', others => '0');
		wrdata  <= (others => '1'); -- shouldn't succeed
		wait for CLK_PER;
		-- at the same time
		rdaddr1 <= (0 => '1', others => '0'); -- should read all 0s
		rdaddr2 <= (1 => '0', others => '1'); -- should read all 0s
		wraddr  <= (1 => '0', others => '1');
		wrdata  <= (others => '1'); -- shouldn't succed
		wait for CLK_PER;
		
		wait for CLK_PER*10;
		-------------------
		-- test stall
		-------------------
		regwrite <= '1';
		
		rdaddr1 <= (1 => '1', others => '0'); -- should read 8
		rdaddr2 <= (4 => '0', others => '1'); -- should read 0FF..FF0
		wraddr  <= (others => '1');
		wrdata  <= (3 => '1', others => '0'); -- overwrite last addr with 00..01000
		wait for CLK_PER;
		-- stall
		stall <= '1';
		rdaddr1 <= (others => '0'); -- should have no effect and still read 8
		rdaddr2 <= (others => '1'); -- should have no effect and still read 0FF..FF0
		wraddr  <= (3 => '0', others => '1');
		wrdata  <= (others => '1'); -- should have no effect
		wait for CLK_PER;
		rdaddr1 <= (3 => '0', others => '1'); -- should have no effect and still read 8
		rdaddr2 <= (others => '1'); -- should have no effect and still read 0FF..FF0
		wraddr <= (3 => '0', others => '1');
		wrdata <= (1 => '0', others => '1'); -- should have no effect
		wait for CLK_PER;
		-- unstall
		stall <= '0';
		rdaddr1 <= (3 => '0', others => '1'); -- should read all 0s
		rdaddr2 <= (others => '1'); -- should read 00..01000
		wraddr  <= (others => '0');
		wrdata  <= (others => '1');
		wait for CLK_PER;
		rdaddr1 <= (3 => '0', others => '1'); -- should read what is written now
		rdaddr2 <= (4 => '0', others => '1'); -- should read 0FF..FF0
		wraddr  <= (3 => '0', others => '1');
		wrdata  <= (2 => '0', others => '1');
		wait for CLK_PER;
		-- stall
		stall <= '1';
		rdaddr1 <= (others => '0'); -- should still read 2=>'0', others => '1'
		rdaddr2 <= (others => '1'); -- should still read 0FF..FF0
		wraddr  <= (3 => '0', others => '1');
		wrdata  <= (0 => '1', others => '0');
		wait for CLK_PER;
		-- unstall
		stall <= '0';
		rdaddr1 <= (2 => '1', others => '0'); -- should read FF..FF (written now)
		rdaddr2 <= (3 => '0', others => '1'); -- should read 2=>'0', others =>'1'
		wraddr  <= (2 => '1', others => '0'); 
		wrdata  <= (others => '1'); -- write FF..FF to 10000
		wait for CLK_PER*10;
		
		
		
		
		
		
		wait;
		
	
	end process;

	


end architecture;
