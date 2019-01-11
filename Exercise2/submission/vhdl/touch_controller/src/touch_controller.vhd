-- touch contoller code

library ieee;
use ieee.std_logic_1164.all;

entity touch_controller is

	port(
		din 			: out std_logic;
		dclk 			: out std_logic;
		scen 			: out std_logic;
		
		dout		 	: in std_logic;
		busy		 	: in std_logic;
		penirq_n  	: in std_logic;
		
		x				: out std_logic_vector (11 downto 0);
		y				: out std_logic_vector (11 downto 0);
	
		clk 			: in std_logic;
		res_n 		: in std_logic
		
	);
	
end entity;	

--		This is for the ADConvertor
--		ADC_DIN 		: in std_logic_vector (7 down to 0);
--		ADC_DOUT		: out std_logic_vector(7 downto 0);
--					
--		ADC_DLCK 	: in std_logic;
--		ADC_CS 		: in std_logic;  -- Chip Select Input(Chip enable signal); low activ 
--		
--		
--		ADC_BUSY		 : out std_logic;
--		ADC_PENIRQ_n : out std_logic
	
architecture beh of touch_controller is

	
	constant CLK_DIVISOR : integer := 1000;

	type LCD_EXTERNAL_STATE is (IDLE, START, A2, A1, A0, MODE, SER, PD1, PD0, BUSY_STATE, RECEIVE);
	signal state, state_next : LCD_EXTERNAL_STATE;
	
	signal scen_next : std_logic;
	
	--clock cycle counter for board
	signal clk_cnt 	  	  	  : integer := 0;  
	
	--clock cycle counter Touch Controller
	signal dclk_cnt, dclk_cnt_next 	  	  : integer := 0;  
	
	--Touch Controller
	signal din_next 	: std_logic;
	
	signal x_next  : std_logic_vector (11 downto 0);
	signal y_next  : std_logic_vector (11 downto 0);
	
	--so that i don't need to read from an Output
	signal dclk_temp : std_logic;
	--when to tact our dclk
	signal dclk_en, dclk_en_next  : std_logic := '0';
	
	--like a boolean to detect if i'm rising down, or rising up
	signal dclk_old  : std_logic; 
	
	--to choose between X or Y Coordinate
	signal round, round_next	  : std_logic := '0'; 
	signal stop_decrement, stop_decrement_next : std_logic := '0';
	signal id, id_next : integer range 11 downto 0;
	
	
	--signal debug : std_logic;
	
	/*
	constant READ_X : std_logic_vector(7 downto 0) := "10000000";
	constant READ_Y : std_logic_vector(7 downto 0) := "11000000";
	
	signal read_x_or_y : type (RX, RY);
	signal din_reg : std_logic_vector(7 downto 0) := READ_X;
   */
	
begin 

	--so that i don't need to read from an Output
	dclk <= dclk_temp;

  --------------------------------------------------------------------
  --                    Clock Generation                            --
  --------------------------------------------------------------------
  
   -- dclk generation process
   clock_generator : process(clk, res_n)
	begin 
		
		if res_n = '0' then
			dclk_temp <= '0';
		elsif rising_edge(clk) then 
		
			if dclk_en = '1' then
		
				-- first dclk <= '0' because of the Figure from the Document
				if( clk_cnt < CLK_DIVISOR / 2 ) then
					dclk_temp <= '0';
					clk_cnt <= clk_cnt + 1; 
				elsif (clk_cnt < CLK_DIVISOR - 1 ) then
					dclk_temp <= '1';
					clk_cnt <= clk_cnt + 1;
				end if;	
					 
				if ( clk_cnt = CLK_DIVISOR - 1 ) then
					clk_cnt <= 0;
				end if;
			
			else
				dclk_temp <= '0';		
			end if;	
			
		end if;		
	
	end process;
  
  
  --------------------------------------------------------------------
  --                    PROCESS : SYNC                              --
  -------------------------------------------------------------------

	sync : process(all)
	begin
		
		if res_n = '0' then
			state <= IDLE;

		elsif rising_edge(clk) then
		
			state <= state_next;
			scen <= scen_next;
			din <= din_next;
			x <= x_next;
			y <= y_next;
			dclk_cnt <= dclk_cnt_next;
			round <= round_next;
			dclk_en <= dclk_en_next;
			dclk_old <= dclk_temp;
			id <= id_next;
			stop_decrement <= stop_decrement_next;
							
		end if;	
	
	end process;
	
  --------------------------------------------------------------------
  --                    PROCESS : NEXT_STATE                        --
  --------------------------------------------------------------------

	-- nur state veraendern
	next_state : process(all)
	begin
	
		-- default
		state_next <= state; 
		
		case state is 
		
			when IDLE =>	
				-- if I touch the screen 		
				if( penirq_n = '0' ) then
					state_next <= START;
				end if;
			
				
			-- Here Starts the Control Word 
			
			when START =>
				-- so that the clock synchronizes with din
				if clk_cnt = 999	then
				--if dclk_cnt = 2 then
					state_next <= A2;
				end if;
		
			when A2 =>
				--if dclk_cnt = 3 then
				if clk_cnt = 999 then
						state_next <= A1;
					end if;
				
			when A1 =>
				--if dclk_cnt = 4 then
				if clk_cnt = 999 then
					state_next <= A0;
				end if;
				
			when A0 =>
				--if dclk_cnt = 5 then
				if clk_cnt = 999 then
					state_next <= MODE;
				end if;
				
			when MODE =>
				--if dclk_cnt = 6 then
				if clk_cnt = 999 then
					state_next <= SER;
				end if;	
				
			when SER =>
				--if dclk_cnt = 7 then
				if clk_cnt = 999 then
					state_next <= PD1;
				end if;
				
			when PD1 =>
				--if dclk_cnt = 8 then
				if clk_cnt = 999 then
					state_next <= PD0;
				end if;
				
			when PD0 =>
				--if dclk_cnt = 9 then
				if clk_cnt = 999 then
					state_next <= BUSY_STATE;
				end if;
			
			-- Here Ends the Control Word 
			
			when BUSY_STATE =>
				--if dclk_cnt = 10 then
				if clk_cnt = 999 then
					state_next <= RECEIVE;
				end if;
				
			when RECEIVE =>
				if dclk_cnt = 25 then
					state_next <= START;
				elsif dclk_cnt = 49 then  
					state_next <= IDLE;
				end if;	
					
		end case;	
				
	end process;
	
  --------------------------------------------------------------------
  --                    PROCESS : OUTPUT                            --
  --------------------------------------------------------------------
  
	output : process(all)
	
	begin
		
		--default 
		scen_next <= scen;
		din_next <= din;
		dclk_cnt_next <= dclk_cnt;
		dclk_en_next <= dclk_en;
		id_next <= id;
		stop_decrement_next <= stop_decrement;
		
		--weil ich x_next gesetzt habe
		x_next <= x;
		y_next <= y;
	   round_next <= round;	
		
		--         S A2 A1 A0 Mode   PD1 PD0
		-- for X: '1 0  0  1  0    0 1   0
		-- for Y: '1 1  0  1  0    0 1   0
		
		-- falling Edge to detect	
		-- dclk_old = '1' and dclk_temp = '0'
				
		--debug <= '0';
		
		case state is 
			
			when IDLE =>
				-- do nothing
				scen_next <= '0';
				if penirq_n = '0' then
					dclk_en_next <= '1';
					dclk_cnt_next <= dclk_cnt + 1;
				end if;			
	
			
			when START =>
				-- '1' because is inverted from the Diagramm 
				scen_next <= '1';
				--debug <= '1';
				din_next <= '1';
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;		
				end if;	
				
				
			when A2 =>
				-- for the X Coordinate
				if ( round = '0' ) then
					--for the X Coordinate
					din_next <= '0';
				else
					--for the Y Coordinate
					din_next <= '1';
				end if;
				
				if dclk_old = '1' and dclk_temp = '0' then	
					dclk_cnt_next <= dclk_cnt + 1;
				
				end if;	

				
				/*
				-- for the Y Coordinate
				if ( falling_edge( dclk_temp )  )  then
					dclk_cnt_next <= dclk_cnt + 1;
					din_next <= '1';id
				end if;	
				*/

			when A1 =>
				din_next <= '0';
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;
					
				end if;	
				
										 
			when A0 =>
				din_next <= '1';
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;
					
				end if;	
			
			
			when MODE =>	
				din_next <= '0';
					
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;
					
				end if;	
			
				
			when SER =>
				din_next <= '0';
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;
					
				end if;	
			
				
			when PD1 =>	
				din_next <= '1';
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;
				end if;	
					
				
			when PD0 =>	
				din_next <= '0';
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;	
				end if;	
			
					
			when BUSY_STATE =>
				
				if dclk_old = '1' and dclk_temp = '0' then
					dclk_cnt_next <= dclk_cnt + 1;
				end if;

				stop_decrement_next <= '0';
						
			
			
			when RECEIVE =>
				
				if ( dclk_old = '1' and dclk_temp = '0' and dclk_cnt < 49 ) then
						
						-- to stop after 12 bits
						if stop_decrement = '0' then
							if id = 0 then
								id_next <= 11;
								stop_decrement_next <= '1';
							else
								id_next <= id - 1;
							end if;
						end if;
						if ( round = '0') then
							if dclk_cnt < 24 then
								x_next(id) <= dout;
								if id = 0 then
									round_next <= '1';		
								end if;
							end if;
						else 
							if dclk_cnt > 24 then
								y_next(id) <= dout; 
								if id = 0 then
									round_next <= '0';
								end if;
							end if;
						
						end if;
						
						dclk_cnt_next <= dclk_cnt + 1;  
						
						
					
				elsif ( dclk_cnt = 49 ) then
					dclk_cnt_next <= 0 ;
					dclk_en_next <= '0';
				end if;	
				
		end case;
	
	end process;
		
end architecture;

