library ieee;
use ieee.std_logic_1164.all;
use work.top_tb_util_pkg.all;

entity top_tb is
end entity;

architecture beh of top_tb is

	constant switches_off : std_logic_vector(17 downto 0) := "000000000000000000";

	constant CLK_PERIOD : time := 20 ns;

	signal clk, reset_n      : std_logic;
	signal ps2_keyboard_clk  : std_logic;
	signal ps2_keyboard_data : std_logic;
	signal keys : std_logic_vector(3 downto 0);
	
	-----------------------------------------------
	--  			Signals from top 						--
	-----------------------------------------------
	
	--Seven segment digit
	signal hex0 : std_logic_vector(6 downto 0);
	signal hex1 : std_logic_vector(6 downto 0);
	signal hex2 : std_logic_vector(6 downto 0);
	signal hex3 : std_logic_vector(6 downto 0);
	signal hex4 : std_logic_vector(6 downto 0);
	signal hex5 : std_logic_vector(6 downto 0);
	signal hex6 : std_logic_vector(6 downto 0);
	signal hex7 : std_logic_vector(6 downto 0);
		
	-- the grren LEDs
	signal ledg : std_logic_vector(8 downto 0);

	-- external interface to SRAM
	signal sram_dq : std_logic_vector(15 downto 0);
	signal sram_addr : std_logic_vector(19 downto 0);
	signal sram_ub_n : std_logic;
	signal sram_lb_n : std_logic;
	signal sram_we_n : std_logic;
	signal sram_ce_n : std_logic;
	signal sram_oe_n : std_logic;
		
	-- LCD interface
	signal nclk    : std_logic;
	signal hd      : std_logic;
	signal vd      : std_logic;
	signal den     : std_logic;
	signal r       : std_logic_vector(7 downto 0);
	signal g       : std_logic_vector(7 downto 0);
	signal b       : std_logic_vector(7 downto 0);
	signal grest   : std_logic;
	signal sda     : std_logic;
	

   -----------------------------------------------
	--  													   --
	-----------------------------------------------
	
	
	-- so that i can make and instance of top
	component top is
	port(
			--50 MHz clock input    checked
		clk      : in  std_logic;

		-- push buttons and switches   checked
		keys     : in std_logic_vector(3 downto 0);
		switches : in std_logic_vector(17 downto 0);
	
		--Seven segment digit
		hex0 : out std_logic_vector(6 downto 0);
		hex1 : out std_logic_vector(6 downto 0);
		hex2 : out std_logic_vector(6 downto 0);
		hex3 : out std_logic_vector(6 downto 0);
		hex4 : out std_logic_vector(6 downto 0);
		hex5 : out std_logic_vector(6 downto 0);
		hex6 : out std_logic_vector(6 downto 0);
		hex7 : out std_logic_vector(6 downto 0);

		-- the grren LEDs
		ledg : out std_logic_vector(8 downto 0);

		-- external interface to SRAM
		sram_dq : inout std_logic_vector(15 downto 0);
		sram_addr : out std_logic_vector(19 downto 0);
		sram_ub_n : out std_logic;
		sram_lb_n : out std_logic;
		sram_we_n : out std_logic;
		sram_ce_n : out std_logic;
		sram_oe_n : out std_logic;
		
		-- LCD interface
		nclk    : out std_logic;
		hd      : out std_logic;
		vd      : out std_logic;
		den     : out std_logic;
		r       : out std_logic_vector(7 downto 0);
		g       : out std_logic_vector(7 downto 0);
		b       : out std_logic_vector(7 downto 0);
		grest   : out std_logic;
		sda     : out std_logic;
		
		-- PS/2    checked
		ps2_clk   :inout std_logic;
		ps2_data  :inout std_logic
	
	
	);
	end component;

	
begin

	--instance of top
	top_instance : top
	port map(
	
		-- links is von dem Entity(top), und rechts ist von dem top_tb
		clk => clk,
		-- reset_n
		ps2_clk => ps2_keyboard_clk,
		ps2_data => ps2_keyboard_data,
		keys => keys,
		switches => switches_off,
		
		hex0 => hex0,
		hex1 => hex1, 
		hex2 => hex2,
		hex3 => hex3
		
		/*
		hex4 => hex4,
		hex5 => hex5,
		hex6 => hex6,
		hex7 => hex7,
		
		ledg => ledg, 
		
		sram_dq => sram_dq, 
		sram_addr => sram_addr, 
		sram_ub_n => sram_ub_n,
		sram_lb_n => sram_lb_n,
		sram_we_n => sram_we_n,
		sram_ce_n => sram_ce_n,
		sram_oe_n => sram_oe_n,
		
		nclk => nclk,  
		hd => hd,   
		vd => vd,     
		den => den,   
		r => r,     
		g => g,   
		b => b,    
		grest => grest,    
		sda => sda
		
		*/
		
	);
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
		-- 0bit is start bit, 10bit is end bit, 9bit is parity bit, und die andere sind data bits
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
