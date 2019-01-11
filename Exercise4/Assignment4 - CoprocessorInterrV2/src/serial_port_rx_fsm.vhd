
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serial_port_rx_fsm is

	generic (
		CLK_DIVISOR : integer
	);
	port (
		clk : in std_logic;
		res_n : in std_logic;
		
		rx : in std_logic;
		new_data : out std_logic;
		data : out std_logic_vector(7 downto 0)
	);
end entity;


architecture beh of serial_port_rx_fsm is

	type RECEIVER_STATE_TYPE is (IDLE, WAIT_START_BIT, GOTO_MIDDLE_OF_START_BIT, MIDDLE_OF_START_BIT,
								WAIT_DATA_BIT, MIDDLE_OF_DATA_BIT, WAIT_STOP_BIT, MIDDLE_OF_STOP_BIT);
								
	signal cur_state : RECEIVER_STATE_TYPE := IDLE;
	signal next_state : RECEIVER_STATE_TYPE := IDLE;

	signal clk_cnt : integer range 0 to CLK_DIVISOR;
	signal clk_cnt_next : integer range 0 to CLK_DIVISOR;
	
	signal bit_cnt : integer range 0 to 7;
	signal bit_cnt_next : integer range 0 to 7;
	
	signal data_int : std_logic_vector(7 downto 0);
	signal data_int_next : std_logic_vector(7 downto 0);

	signal data_out : std_logic_vector(7 downto 0);
	signal data_out_next : std_logic_vector(7 downto 0);
	
	signal data_new : std_logic;
	signal data_new_delay : std_logic := '0';

begin


	state_change : process(all)
	begin
		
		next_state <= cur_state;
		
		case cur_state is
		
			when IDLE =>
				if rx = '1' then
					next_state <= WAIT_START_BIT;
				end if;
			when WAIT_START_BIT =>
				if rx = '0' then
					next_state <= GOTO_MIDDLE_OF_START_BIT;
				end if;			
			when GOTO_MIDDLE_OF_START_BIT =>
				if clk_cnt = CLK_DIVISOR/2 - 2 then
					next_state <= MIDDLE_OF_START_BIT;
				end if;
			when MIDDLE_OF_START_BIT =>
				next_state <= WAIT_DATA_BIT;
			when WAIT_DATA_BIT =>
				if clk_cnt = CLK_DIVISOR - 2 then
					next_state <= MIDDLE_OF_DATA_BIT;
				end if;
			when MIDDLE_OF_DATA_BIT =>
				if bit_cnt = 7 then
					next_state <= WAIT_STOP_BIT;
				elsif bit_cnt < 7 then
					next_state <= WAIT_DATA_BIT;
				end if;
			when WAIT_STOP_BIT =>
				if clk_cnt = CLK_DIVISOR - 2 then
					next_state <= MIDDLE_OF_STOP_BIT;
				end if;
			when MIDDLE_OF_STOP_BIT =>
				if rx = '0' then
					next_state <= IDLE;
				elsif rx = '1' then
					next_state <= WAIT_START_BIT;
				end if;
		end case;
	
	end process;
	
	
	
	output_change : process(all)
	begin
		
		clk_cnt_next <= clk_cnt;
		bit_cnt_next <= bit_cnt;
		data_int_next <= data_int;
		data_new <= '0';
		data_out_next <= data_out;
		
		case cur_state is
			
			when IDLE =>
				--nothing
			when WAIT_START_BIT =>
				bit_cnt_next <= 0;
				clk_cnt_next <= 0;
			when GOTO_MIDDLE_OF_START_BIT =>
				clk_cnt_next <= clk_cnt + 1;
			when MIDDLE_OF_START_BIT =>
				clk_cnt_next <= 0;
			when WAIT_DATA_BIT =>
				clk_cnt_next <= clk_cnt + 1;
			when MIDDLE_OF_DATA_BIT =>
				clk_cnt_next <= 0;
				if(bit_cnt /= 7) then
					bit_cnt_next <= bit_cnt + 1;
				end if;
				data_int_next <= rx & data_int(7 downto 1);
			when WAIT_STOP_BIT =>
				clk_cnt_next <= clk_cnt + 1;
			when MIDDLE_OF_STOP_BIT =>
				data_new <= '1';
				data_out_next <= data_int;		
		end case;
		
	end process;
	

	sync : process(all)
	begin
		if res_n = '0' then
			cur_state <= IDLE;
			clk_cnt <= 0;
		elsif rising_edge(clk) then
			cur_state <= next_state;
			clk_cnt <= clk_cnt_next;
			bit_cnt <= bit_cnt_next;
			data_int <= data_int_next;
			data_out <= data_out_next;
			
			data_new_delay <= data_new;
			new_data <= data_new_delay;
			--data <= data_out;
		end if;
	end process;

	data <= data_out;



end architecture;









