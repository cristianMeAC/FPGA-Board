library ieee;
use ieee.std_logic_1164.all;
use work.top_tb_util_pkg.all;

entity top_tb is
end entity;

architecture beh of top_tb is

	constant CLK_PERIOD : time := 20 ns;

	signal clk, reset_n      : std_logic;
	signal ps2_keyboard_clk  : std_logic;
	signal ps2_keyboard_data : std_logic;
	signal keys : std_logic_vector(3 downto 0);
begin

	-----------------------------------------------
	--   Instantiate your top level entity here  --
	-----------------------------------------------
	-- The testbench generates the above singals --
	-- use them as inputs to your system         --
	-----------------------------------------------

	-- Generates the clock signal
	clkgen : process
	begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process clkgen;

	-- Generates the reset signal
	reset : process
	begin  -- process reset
		reset_n <= '0';
		wait_cycle(clk, 10);
		reset_n <= '1';
		wait;
	end process;
	keys <= (0=>reset_n, others=>'0');

	-- Generates the communication on the PS2 interface
	input : process
		variable temprx : std_logic_vector(7 downto 0);
	begin  -- process input
		ps2_keyboard_clk  <= 'H';
		ps2_keyboard_data <= 'H';
		wait until rising_edge(reset_n);
		wait for 50 us;

		-- init
		wait until rising_edge(ps2_keyboard_clk);
		wait for 10 us;
		report "[PS2]  Starting..." severity note;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "HHHHHHHHHH0", temprx);
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H0HHHHHHH", temprx);
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H0H0H0HHH", temprx);
		wait until rising_edge(ps2_keyboard_clk);
		wait for 10 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "HHHHHHHHHH0", temprx);
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H0HHHHHHH", temprx);
		wait until rising_edge(ps2_keyboard_clk);
		wait for 10 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "HHHHHHHHHH0", temprx);
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H0HHHHHHH", temprx);
		wait until rising_edge(ps2_keyboard_clk);
		wait for 10 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "HHHHHHHHHH0", temprx);
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H0HHHHHHH", temprx);

		--senc color change command: c1234
		-- send 'c'
		                                                --  1   2
		wait for 100 us;                                -- |--||--|
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "0H0000H00HH", temprx); -- 21
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00000HHHHHH", temprx); -- F0
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "0H0000H00HH", temprx); -- 21

		-- send '1'
		wait for 100 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00HH0H000HH", temprx); -- 16
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00000HHHHHH", temprx); -- F0
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00HH0H000HH", temprx); -- 16

		-- send '2'
		wait for 100 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00HHHH000HH", temprx); -- 1E
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00000HHHHHH", temprx); -- F0
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00HHHH000HH", temprx); -- 1E
		
		-- send '3'
		wait for 100 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00HH00H00HH", temprx); -- 26
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00000HHHHHH", temprx); -- F0
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00HH00H00HH", temprx); -- 26
		
		-- send '4'
		wait for 100 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "0H0H00H00HH", temprx); -- 25
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00000HHHHHH", temprx); -- F0
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "0H0H00H00HH", temprx); -- 25
		
		--send clear display command: x
		-- send 'x'
		wait for 100 us;
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H000H00HH", temprx); 
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00000HHHHHH", temprx); 
		sendreceive(ps2_keyboard_clk, ps2_keyboard_data, "00H000H00HH", temprx); 
		wait;
		
	end process;

end architecture;
