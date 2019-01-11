

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.graphics_controller_pkg.all;

entity ascii_gcinstr is 
	port (
		clk : in std_logic;
		res_n : in std_logic;
		
		ascii_rd    : out std_logic;                    --read signal for the ascii fifo
		ascii_data  : in std_logic_vector(7 downto 0);  --parallel byte output of ascii fifo
		ascii_empty : in std_logic;                     --empty signal of the ascii rx fifo
		
		instr       : out std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
		instr_wr    : out std_logic;
		instr_full  : in std_logic
	);
end entity;


architecture arch of ascii_gcinstr is
	
	type state_t is (IDLE, READ_COMMAND, READ_HEX_STRING, SEND_INSTRUCTION);
	
	
	signal state, state_nxt : state_t;
	signal opcode, opcode_nxt : std_logic_vector(7 downto 0);
	
	constant HEX_DIGITS_PER_NUMBER : integer := 3;
	constant HEX_DIGITS_PER_COLOR : integer := 4;
	
	signal hex_string, hex_string_nxt : std_logic_vector(4*HEX_DIGITS_PER_NUMBER*4-1 downto 0);
	
	alias p0_y : std_logic_vector(HEX_DIGITS_PER_NUMBER*4-1 downto 0) is hex_string(1*HEX_DIGITS_PER_NUMBER*4-1 downto 0*HEX_DIGITS_PER_NUMBER*4);
	alias p0_x : std_logic_vector(HEX_DIGITS_PER_NUMBER*4-1 downto 0) is hex_string(2*HEX_DIGITS_PER_NUMBER*4-1 downto 1*HEX_DIGITS_PER_NUMBER*4);
	alias p1_y : std_logic_vector(HEX_DIGITS_PER_NUMBER*4-1 downto 0) is hex_string(3*HEX_DIGITS_PER_NUMBER*4-1 downto 2*HEX_DIGITS_PER_NUMBER*4);
	alias p1_x : std_logic_vector(HEX_DIGITS_PER_NUMBER*4-1 downto 0) is hex_string(4*HEX_DIGITS_PER_NUMBER*4-1 downto 3*HEX_DIGITS_PER_NUMBER*4);
	
	alias color : std_logic_vector(HEX_DIGITS_PER_COLOR*4-1 downto 0) is hex_string(HEX_DIGITS_PER_COLOR*4-1 downto 0);
	
	signal digit_cnt, digit_cnt_nxt : std_logic_vector(HEX_DIGITS_PER_NUMBER*4-1 downto 0);
	
	
	
	signal hex_value : std_logic_vector(3 downto 0);
	signal ascii_rd_int : std_logic;
	signal ascii_rd_last : std_logic; --signal indicating whether a read operation was performed in the last cycle
begin
	
	sync : process(clk, res_n)
	begin
		if (res_n = '0') then
			state <= IDLE;
			digit_cnt <= (others=>'0');
			hex_string <= (others=>'0');
			ascii_rd_last <= '0';
		elsif (rising_edge(clk)) then
			state <= state_nxt;
			digit_cnt <= digit_cnt_nxt;
			opcode <= opcode_nxt;
			hex_string <= hex_string_nxt;
			ascii_rd_last <= ascii_rd_int;
		end if;
	end process;
	
	
	ascii_rd <= ascii_rd_int;
	
	next_state : process(state, opcode, ascii_data, ascii_empty, digit_cnt, hex_string, hex_value, instr_full, ascii_rd_last)
		variable read_next_value : std_logic := '0';
	begin
		instr <= (others=>'0');
		instr_wr <= '0';
		
		ascii_rd_int <= '0';
		state_nxt <= state;
		opcode_nxt <= opcode;
		digit_cnt_nxt <= digit_cnt;
		hex_string_nxt <= hex_string;

		read_next_value := '0';
	
		case state is
			when IDLE =>
				if (ascii_empty = '0') then
					ascii_rd_int <= '1';
					state_nxt <= READ_COMMAND;
				end if;
			
			when READ_COMMAND =>
				digit_cnt_nxt <= (0=>'1', others=>'0');
				
				read_next_value := '1';
				case ascii_data is
					when x"70" => -- p, set pixel
						opcode_nxt <= GCNTL_INSTR_SET_PIXEL;
					when x"6C" => -- l, draw line
						opcode_nxt <= GCNTL_INSTR_DRAW_LINE;
					when x"72" => -- r, draw rect
						opcode_nxt <= GCNTL_INSTR_DRAW_RECTANGLE;
					when x"6f" => -- o, draw circle
						opcode_nxt <= GCNTL_INSTR_DRAW_CIRCLE;
					when x"63" => -- c, set drawing color
						opcode_nxt <= GCNTL_INSTR_CHANGE_COLOR;
					when x"78" => -- x, clear screen
						opcode_nxt <= GCNTL_INSTR_CLEAR_SCREEN;
						read_next_value := '0';
						state_nxt <= SEND_INSTRUCTION;
					when others => 
						read_next_value := '0';
						state_nxt <= IDLE;
				end case;
				
				if(read_next_value = '1') then
					if (ascii_empty = '0') then
						ascii_rd_int <= '1';
						state_nxt <= READ_HEX_STRING;
					else 
						state_nxt <= state;
					end if;
				end if;
				
			when READ_HEX_STRING =>
				if (ascii_rd_last = '1') then
					hex_string_nxt(hex_string'length-1 downto 4) <= hex_string(hex_string'length-5 downto 0);
					hex_string_nxt(3 downto 0) <= hex_value;
				end if;
			
				read_next_value := '1';
				case opcode is 
					when GCNTL_INSTR_SET_PIXEL =>
						if (digit_cnt(HEX_DIGITS_PER_NUMBER*2-1) = '1') then
							state_nxt <= SEND_INSTRUCTION;
							read_next_value := '0';
						end if;
					when GCNTL_INSTR_DRAW_LINE | GCNTL_INSTR_DRAW_RECTANGLE =>
						if (digit_cnt(HEX_DIGITS_PER_NUMBER*4-1) = '1') then
							state_nxt <= SEND_INSTRUCTION;
							read_next_value := '0';
						end if;
					when GCNTL_INSTR_DRAW_CIRCLE => 
						if (digit_cnt(HEX_DIGITS_PER_NUMBER*3-1) = '1') then
							state_nxt <= SEND_INSTRUCTION;
							read_next_value := '0';
						end if;
					when GCNTL_INSTR_CHANGE_COLOR =>
						if (digit_cnt(HEX_DIGITS_PER_COLOR-1) = '1') then
							state_nxt <= SEND_INSTRUCTION;
							read_next_value := '0';
						end if;
					when others => 
						null;
				end case;
			
				if(read_next_value = '1') then 
					if (ascii_empty = '0') then
						ascii_rd_int <= '1';
						digit_cnt_nxt <= digit_cnt(digit_cnt'length-2 downto 0) & '0';
					end if;
				end if;
				
			when SEND_INSTRUCTION =>
				
				instr(7 downto 0) <= opcode;
				
				case opcode is 
					when GCNTL_INSTR_SET_PIXEL =>
						instr(1*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8) <= p0_x;
						instr(2*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+HEX_DIGITS_PER_NUMBER*4) <= p0_y; 
					when GCNTL_INSTR_DRAW_RECTANGLE | GCNTL_INSTR_DRAW_LINE => 
						instr(1*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+0*HEX_DIGITS_PER_NUMBER*4) <= p0_x;
						instr(2*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+1*HEX_DIGITS_PER_NUMBER*4) <= p0_y; 
						instr(3*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+2*HEX_DIGITS_PER_NUMBER*4) <= p1_x;
						instr(4*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+3*HEX_DIGITS_PER_NUMBER*4) <= p1_y; 
					when GCNTL_INSTR_DRAW_CIRCLE => 
						instr(1*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+0*HEX_DIGITS_PER_NUMBER*4) <= p1_y;
						instr(2*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+1*HEX_DIGITS_PER_NUMBER*4) <= p0_x; 
						instr(3*HEX_DIGITS_PER_NUMBER*4+8-1 downto 8+2*HEX_DIGITS_PER_NUMBER*4) <= p0_y;
					when GCNTL_INSTR_CHANGE_COLOR =>
						instr(16+8-1 downto 8) <= color;
					when others =>
						null;
				end case;
				
				if (instr_full='0') then
					instr_wr <= '1';
					state_nxt <= IDLE;
				end if;
		end case;
	
	
	end process;
	
	
	generate_hex_value : process(ascii_data)
	begin
		hex_value <= (others=>'0');
		if (unsigned(ascii_data) < 58) then
			hex_value <= ascii_data(3 downto 0);
		else
			hex_value <= std_logic_vector(9+unsigned(ascii_data(3 downto 0)));
		end if;
	end process;
--			elsif (unsigned(ascii_data) < 71) then --upper case letters
--			hex_value <= std_logic_vector(9+unsigned(ascii_data(3 downto 0)));
--		elsif (unsigned(ascii_data) < 71) then --lower case letters
end architecture;






