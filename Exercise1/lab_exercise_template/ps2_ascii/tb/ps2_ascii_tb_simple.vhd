library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_util_pkg.all;

entity ps2_ascii_tb_simple is
end entity;

architecture bench of ps2_ascii_tb_simple is

	component ps2_ascii is
		port
		(
			clk : in std_logic;
			res_n : in std_logic;
			scancode : in std_logic_vector(7 downto 0);
			new_scancode : in std_logic;
			ascii : out std_logic_vector(7 downto 0);
			new_ascii : out std_logic
		);
	end component;

	signal clk : std_logic;
	signal res_n : std_logic;
	signal scancode : std_logic_vector(7 downto 0);
	signal new_scancode : std_logic;
	signal ascii : std_logic_vector(7 downto 0);
	signal new_ascii : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;

	function ascii_char_to_slv(c : character) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(natural(character'pos(c)), 8));
	end function;
begin

	uut : ps2_ascii
		port map
		(
			clk          => clk,
			res_n        => res_n,
			scancode     => scancode,
			new_scancode => new_scancode,
			ascii        => ascii,
			new_ascii    => new_ascii
		);

	stimulus : process
		procedure send_scancode(code : std_logic_vector(7 downto 0)) is
		begin
			scancode <= code;
			new_scancode <= '1';
			wait until rising_edge(clk);
			new_scancode <= '0';
		end procedure;
		
		procedure check_result(c : character) is 
		begin
			loop
				wait until rising_edge(clk);
				if(new_ascii='1') then
					exit;
				end if;
			end loop;
			assert (ascii = ascii_char_to_slv(c)) report "expected=0x" & slv_to_hex(ascii_char_to_slv(c)) & " actual=0x" & slv_to_hex(ascii) severity error;
		end procedure;
		
		procedure timeout(num_cycles : integer) is
		begin
			wait for CLK_PERIOD*num_cycles;
		end procedure;
	begin
		scancode <= (others=>'0');
		new_scancode <= '0';
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';
		
		--press A-key
		send_scancode(x"1C");
		check_result('a');
		
		--release A-key
		send_scancode(x"F0");
		send_scancode(x"1C");
		timeout(2);
		
		--press shift 
		send_scancode(x"12");
		timeout(2);
		
		--press A-key
		send_scancode(x"1C");
		check_result('A');
		
		--press B-key
		send_scancode(x"32");
		check_result('B');
		
		--press C-key
		send_scancode(x"21");
		check_result('C');
		
		--release shift key
		send_scancode(x"F0");
		send_scancode(x"12");
		timeout(2);
		
		--press 0-key
		send_scancode(x"45");
		check_result('0');
		
		wait;
	end process;

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

