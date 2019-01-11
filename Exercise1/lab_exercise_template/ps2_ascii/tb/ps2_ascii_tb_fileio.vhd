library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_util_pkg.all;

library std; -- for Printing
use std.textio.all;
use ieee.std_logic_textio.all;

entity ps2_ascii_tb_fileio is
end entity;

architecture bench of ps2_ascii_tb_fileio is

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
	
	file input_file : text;
	file output_ref_file : text;
	
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
		
		procedure timeout(num_cycles : integer) is
		begin
			wait for CLK_PERIOD*num_cycles;
		end procedure;
		
		-- file io related variables
		variable fstatus: file_open_status;
		variable l : line;
		
		variable scancode_temp : std_logic_vector(7 downto 0);
	begin
		-- open input file
		file_open(fstatus, input_file,"testdata/input.txt", READ_MODE);
		
		scancode <= (others=>'0');
		new_scancode <= '0';
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';
		
		
		while not endfile(input_file) loop
			readline(input_file, l); 
			
			--report "stimulus READ: " & l(l'low to l'high) severity note; --print line
			
			if( l(1) = '#' ) then --ignore comment lines 
				next;
			end if;
			
			scancode_temp := hex_to_slv(l(1 to 2), 8); --convert first 2 characters of the line l to a 8 bit std_logic_vector 
			send_scancode(scancode_temp);
			timeout(2); --the converter need more than 1 cycle to process some scancodes
		end loop;
		
		wait;
	end process;


	check_output : process
		-- file io related variables
		variable fstatus: file_open_status;
		variable l : line;
		
		variable character_temp : character;
	begin 
		file_open(fstatus, output_ref_file,"testdata/output_ref.txt", READ_MODE);
		
		wait until res_n = '1'; -- await reset
		
		loop
			--report "WAITING" severity note;
			-- wait for new data at the output (indicated by logical 1 at new_ascii)
			loop
				wait until rising_edge(clk);
				if(new_ascii='1') then
					exit;
				end if;
			end loop;
			
			--read next reference character from file
			while not endfile(output_ref_file) loop
				readline(output_ref_file, l);
				if( l(1) = '#' ) then --ignore comment lines 
					next;
				end if;
				character_temp := l(1);
				exit;
			end loop;
			
			if (endfile(output_ref_file)) then --nothing left to read 
				exit;
			end if;
			
			--report "READ: " & character_temp severity note;
			
			assert (ascii = ascii_char_to_slv(character_temp)) report "[" & character_temp & "]   expected=0x" & slv_to_hex(ascii_char_to_slv(character_temp)) & " actual=0x" & slv_to_hex(ascii) severity error;
		

		end loop;
		
		--report "END" severity note;
		
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

