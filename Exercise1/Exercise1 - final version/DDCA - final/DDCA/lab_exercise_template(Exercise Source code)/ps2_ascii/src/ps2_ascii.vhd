library ieee;
use ieee.std_logic_1164.all;
use work.rom_pkg.all;


entity ps2_ascii is
	port (
		clk, res_n : in std_logic;
		scancode : in std_logic_vector(7 downto 0);
		new_scancode : in std_logic;

		ascii : out std_logic_vector(7 downto 0);
		new_ascii : out std_logic
	);
end entity;


architecture struct of ps2_ascii is
	signal shift : std_logic;
	signal ascii_int : std_logic_vector(7 downto 0);
	signal rom_addr : std_logic_vector(9 downto 0);
	type STATE_TYPE is (
		STATE_IDLE, STATE_RELEASE, STATE_EXTENDED,
		STATE_EXTENDED_RELEASE, STATE_SHIFT_START1,
		STATE_SHIFT_START2, STATE_SHIFT_END1,
		STATE_SHIFT_END2, STATE_DECODE, STATE_DECODE_EXTENDED,
		STATE_READ);
	signal keyboard_state, keyboard_state_next : STATE_TYPE;
	signal shift1, shift2, shift1_next, shift2_next : std_logic;
	signal scancode_saved, scancode_saved_next : std_logic_vector(7 downto 0);
begin
	shift <= shift1 or shift2;

	process(keyboard_state, new_scancode, scancode)
	begin
		keyboard_state_next <= keyboard_state;
		case keyboard_state is
			when STATE_IDLE =>
				if new_scancode = '1' then
					if scancode = x"F0" then
						keyboard_state_next <= STATE_RELEASE;
					elsif scancode = x"E0" then
						keyboard_state_next <= STATE_EXTENDED;
					elsif scancode = x"12" then
						keyboard_state_next <= STATE_SHIFT_START1;
					elsif scancode = x"59" then
						keyboard_state_next <= STATE_SHIFT_START2;
					else
						keyboard_state_next <= STATE_DECODE;
					end if;
				end if;
			when STATE_RELEASE =>
				if new_scancode = '1' then
					if scancode = x"12" then
						keyboard_state_next <= STATE_SHIFT_END1;
					elsif scancode = x"59" then
						keyboard_state_next <= STATE_SHIFT_END2;
					elsif scancode /= x"F0" then
						keyboard_state_next <= STATE_IDLE;
					end if;
				end if;
			when STATE_EXTENDED =>
				if new_scancode = '1' then
					if scancode = x"F0" then
						keyboard_state_next <= STATE_EXTENDED_RELEASE;
					elsif scancode /= x"E0" then
						keyboard_state_next <= STATE_DECODE_EXTENDED;
					end if;
				end if;
			when STATE_EXTENDED_RELEASE =>
				if new_scancode = '1' then
					if scancode /= x"E0" and scancode /= x"F0" then
						keyboard_state_next <= STATE_IDLE;
					end if;
				end if;
			when STATE_SHIFT_START1 =>
				keyboard_state_next <= STATE_IDLE;
			when STATE_SHIFT_START2 =>
				keyboard_state_next <= STATE_IDLE;
			when STATE_SHIFT_END1 =>
				keyboard_state_next <= STATE_IDLE;
			when STATE_SHIFT_END2 =>
				keyboard_state_next <= STATE_IDLE;
			when STATE_DECODE =>
				keyboard_state_next <= STATE_READ;
			when STATE_DECODE_EXTENDED =>
				keyboard_state_next <= STATE_READ;
			when STATE_READ =>
				keyboard_state_next <= STATE_IDLE;
		end case;
	end process;

	process(keyboard_state, shift1, shift2, scancode, shift, scancode_saved)
	begin
		shift1_next <= shift1;
		shift2_next <= shift2;
		scancode_saved_next <= scancode_saved;
		rom_addr <= (others => '0');

		case keyboard_state is
			when STATE_IDLE =>
				scancode_saved_next <= scancode;
			when STATE_RELEASE =>
				null;
			when STATE_EXTENDED =>
				scancode_saved_next <= scancode;
			when STATE_EXTENDED_RELEASE =>
				null;
			when STATE_SHIFT_START1 =>
				shift1_next <= '1';
			when STATE_SHIFT_START2 =>
				shift2_next <= '1';
			when STATE_SHIFT_END1 =>
				shift1_next <= '0';
			when STATE_SHIFT_END2 =>
				shift2_next <= '0';
			when STATE_DECODE =>
				rom_addr <= '0' & shift & scancode_saved;
			when STATE_DECODE_EXTENDED =>
				rom_addr <= '1' & shift & scancode_saved;
			when STATE_READ =>
				null;
		end case;
	end process;

	process(clk, res_n)
	begin
		if res_n = '0' then
			keyboard_state <= STATE_IDLE;
			shift1 <= '0';
			shift2 <= '0';
			scancode_saved <= (others => '0');
		elsif rising_edge(clk) then
			keyboard_state <= keyboard_state_next;
			shift1 <= shift1_next;
			shift2 <= shift2_next;
			scancode_saved <= scancode_saved_next;
		end if;
	end process;

	ascii_rom_inst : rom_sync_1r
	generic map (
		ADDR_WIDTH => 10,
		DATA_WIDTH => 8,
		INIT_PATTERN =>
		(
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 000
		  x"00", x"00", x"00", x"00", x"00", x"00", x"5E", x"00", -- 008
		  x"00", x"00", x"00", x"00", x"00", x"71", x"31", x"00", -- 010
		  x"00", x"00", x"7A", x"73", x"61", x"77", x"32", x"00", -- 018
		  x"00", x"63", x"78", x"64", x"65", x"34", x"33", x"00", -- 020
		  x"00", x"20", x"76", x"66", x"74", x"72", x"35", x"00", -- 028
		  x"00", x"6E", x"62", x"68", x"67", x"7A", x"36", x"00", -- 030
		  x"00", x"00", x"6D", x"6A", x"75", x"37", x"38", x"00", -- 038
		  x"00", x"2C", x"6B", x"69", x"6F", x"30", x"39", x"00", -- 040
		  x"00", x"2E", x"2D", x"6C", x"94", x"70", x"E1", x"00", -- 048
		  x"00", x"00", x"84", x"00", x"81", x"EF", x"00", x"00", -- 050
		  x"00", x"00", x"0A", x"2B", x"00", x"23", x"00", x"00", -- 058
		  x"00", x"00", x"00", x"00", x"00", x"00", x"08", x"00", -- 060
		  x"00", x"31", x"00", x"34", x"37", x"00", x"00", x"00", -- 068
		  x"30", x"2C", x"32", x"35", x"36", x"38", x"00", x"00", -- 070
		  x"00", x"2B", x"33", x"2D", x"2A", x"39", x"00", x"00", -- 078
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 080
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 088
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 090
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 098
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0A0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0A8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0B0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0B8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0C0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0C8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0D0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0D8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0E0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0E8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0F0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0F8
		  
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 100
		  x"00", x"00", x"00", x"00", x"00", x"00", x"F8", x"00", -- 108
		  x"00", x"00", x"00", x"00", x"00", x"51", x"21", x"00", -- 110
		  x"00", x"00", x"5A", x"53", x"41", x"57", x"22", x"00", -- 118
		  x"00", x"43", x"58", x"44", x"45", x"24", x"F5", x"00", -- 120
		  x"00", x"20", x"56", x"46", x"54", x"52", x"25", x"00", -- 128
		  x"00", x"4E", x"42", x"48", x"47", x"5A", x"26", x"00", -- 130
		  x"00", x"00", x"4D", x"4A", x"55", x"2F", x"28", x"00", -- 138
		  x"00", x"3B", x"4B", x"49", x"4F", x"3D", x"29", x"00", -- 140
		  x"00", x"3A", x"5F", x"4C", x"99", x"50", x"3F", x"00", -- 148
		  x"00", x"00", x"8E", x"00", x"9A", x"60", x"00", x"00", -- 150
		  x"00", x"00", x"0A", x"2A", x"00", x"27", x"00", x"00", -- 158
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 160
		  x"00", x"31", x"00", x"34", x"37", x"00", x"00", x"00", -- 168
		  x"30", x"2C", x"32", x"35", x"36", x"38", x"00", x"00", -- 170
		  x"00", x"2B", x"33", x"2D", x"2A", x"39", x"00", x"00", -- 178
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 180
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 188
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 190
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 198
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1A0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1A8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1B0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1B8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1C0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1C8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1D0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1D8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1E0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1E8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1F0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1F8
		  
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 000
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 008
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 010
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 018
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 020
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 028
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 030
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 038
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 040
		  x"00", x"00", x"2F", x"00", x"00", x"00", x"00", x"00", -- 048
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 050
		  x"00", x"00", x"0A", x"00", x"00", x"00", x"00", x"00", -- 058
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 060
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 068
		  x"00", x"08", x"00", x"00", x"00", x"00", x"00", x"00", -- 070
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 078
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 080
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 088
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 090
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 098
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0A0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0A8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0B0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0B8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0C0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0C8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0D0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0D8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0E0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0E8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0F0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 0F8
		  
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 100
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 108
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 110
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 118
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 120
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 128
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 130
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 138
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 140
		  x"00", x"00", x"2F", x"00", x"00", x"00", x"00", x"00", -- 148
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 150
		  x"00", x"00", x"0A", x"00", x"00", x"00", x"00", x"00", -- 158
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 160
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 168
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 170
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 178
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 180
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 188
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 190
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 198
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1A0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1A8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1B0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1B8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1C0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1C8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1D0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1D8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1E0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1E8
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- 1F0
		  x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"  -- 1F8
		)
	)
	port map (
		clk => clk,
		addr => rom_addr,
		data => ascii_int,
		rd => '1'
	);

	ascii <= ascii_int;
	new_ascii <= '1' when ascii_int /= x"00" else '0';
	
	
	
end architecture;
