-- ADD YOUR CODE HERE
library ieee;
use ieee.std_logic_1164.all;
use work.graphics_controller_pkg.all;

entity seven_segment_display is
	port(
		
		color : in  std_logic_vector ( 15 downto 0);
		
		hex0	: out std_logic_vector ( 6 downto 0);
		hex1	: out std_logic_vector ( 6 downto 0);
		hex2	: out	std_logic_vector ( 6 downto 0);
		hex3	: out	std_logic_vector ( 6 downto 0);
		
		-- Task5 added signals
		clk 	 : in std_logic;
		res_n  : in std_logic;
		button : in std_logic;
		hex4	: out	std_logic_vector ( 6 downto 0);
		hex5	: out	std_logic_vector ( 6 downto 0);
		hex6	: out	std_logic_vector ( 6 downto 0);
		hex7	: out	std_logic_vector ( 6 downto 0);
		
		--Assignment 2
		debugX : in std_logic_vector(11 downto 0);
		debugY : in std_logic_vector(11 downto 0)
			
	);
end entity;

architecture beh of seven_segment_display is
		
		-- the states for the State Machine
		type machine_state is (STATE_RED, STATE_GREEN, STATE_BLUE);
		
		-- creating the signal that uses diferrent states
		signal current_state 	   : machine_state;
		signal next_state 		   : machine_state;
		
		signal temp_grph_color_red		   : std_logic_vector ( 4 downto 0);
		signal temp_grph_color_green		: std_logic_vector ( 5 downto 0);
		signal temp_grph_color_blue		: std_logic_vector ( 4 downto 0);	
		
begin
	
	/*
	hex0 <= "1111111";   null
	hex1 <= "1000000";	0
	hex2 <= "0000000";	8
	hex3 <= "1111000";	7
	*/
	
	/*

	-- implementing Next State Logic
	following_state : process( all )
	begin
		
		case current_state is
		
			when STATE_RED    =>
					next_state <= STATE_BLUE;
					 
			when STATE_BLUE   =>
					next_state <= STATE_GREEN;
							
			when STATE_GREEN  =>
					next_state <= STATE_RED;
					
			when others =>
				next_state <= STATE_RED;
				
		end case;	
		
	end process;			

   -- implementing Output Logic
	output : process( all )
	begin 
		
		temp_grph_color_red   <= get_red (color);    -- 5 width
		temp_grph_color_green <= get_green (color); 	-- 6 width
		temp_grph_color_blue  <= get_blue  (color);  -- 5 width
	
	case current_state is
		
		when STATE_RED =>
			case temp_grph_color_red(3 downto 0) is
			
					when "0000" =>
						hex4 <= "1000000";   --0
					when "0001" =>
						hex4 <= "1111001";   --1
					when "0010" =>
						hex4 <= "0100100";	--2
					when "0011" =>
						hex4 <= "0110000";	--3
					when "0100" =>
						hex4 <= "0011001";	--4
					when "0101" =>
						hex4 <= "0010010";	--5
					when "0110" =>
						hex4 <= "0000010";	--6
					when "0111" =>
						hex4 <= "1111000";	--7
					when "1000" =>
						hex4 <= "0000000";	--8
					when "1001" =>
						hex4 <= "0010000";	--9
					when "1010" =>
						hex4 <= "0001000";	--A
					when "1011" =>
						hex4 <= "0000011";	--B
					when "1100" =>
						hex4 <= "0100111";	--C
					when "1101" =>
						hex4 <= "0100001";	--D
					when "1110" =>
						hex4 <= "0000110";	--E
					when "1111" =>
						hex4 <= "0001110";	--F
					when others =>
						hex4 <= "1000000";	-- the R					
			end case;
			
			case temp_grph_color_red(4) is 
					
					when '0' =>
						hex5 <= "1000000";	--0
					when '1' =>
						hex5 <= "1111001";   --1
					when others =>
						hex5 <= "0001000";	-- the R
						
			end case;
			
	--------------------------------------------------------------------------
	--                             here ends red                            --
	--------------------------------------------------------------------------
		when STATE_BLUE =>
			case temp_grph_color_blue(3 downto 0) is
			
					when "0000" =>
						hex4 <= "1000000";   --0
					when "0001" =>
						hex4 <= "1111001";   --1
					when "0010" =>
						hex4 <= "0100100";	--2
					when "0011" =>
						hex4 <= "0110000";	--3
					when "0100" =>
						hex4 <= "0011001";	--4
					when "0101" =>
						hex4 <= "0010010";	--5
					when "0110" =>
						hex4 <= "0000010";	--6
					when "0111" =>
						hex4 <= "1111000";	--7
					when "1000" =>
						hex4 <= "0000000";	--8
					when "1001" =>
						hex4 <= "0010000";	--9
					when "1010" =>
						hex4 <= "0001000";	--A
					when "1011" =>
						hex4 <= "0000011";	--B
					when "1100" =>
						hex4 <= "0100111";	--C
					when "1101" =>
						hex4 <= "0100001";	--D
					when "1110" =>
						hex4 <= "0000110";	--E
					when "1111" =>
						hex4 <= "0001110";	--F
					when others =>
						hex4 <= "1000000";	-- the R					
			end case;
			
			
			case temp_grph_color_blue(4) is 
					
					when '0' =>
						hex5 <= "1000000";	--0
					when '1' =>
						hex5 <= "1111001";   --1
					when others =>
						hex5 <= "0001000";	-- the R
						
			end case;

	--------------------------------------------------------------------------
	--                             here ends blue                           --
	--------------------------------------------------------------------------		
		when STATE_GREEN =>
			case temp_grph_color_green(3 downto 0) is
			
					when "0000" =>
						hex4 <= "1000000";   --0
					when "0001" =>
						hex4 <= "1111001";   --1
					when "0010" =>
						hex4 <= "0100100";	--2
					when "0011" =>
						hex4 <= "0110000";	--3
					when "0100" =>
						hex4 <= "0011001";	--4
					when "0101" =>
						hex4 <= "0010010";	--5
					when "0110" =>
						hex4 <= "0000010";	--6
					when "0111" =>
						hex4 <= "1111000";	--7
					when "1000" =>
						hex4 <= "0000000";	--8
					when "1001" =>
						hex4 <= "0010000";	--9
					when "1010" =>
						hex4 <= "0001000";	--A
					when "1011" =>
						hex4 <= "0000011";	--B
					when "1100" =>
						hex4 <= "0100111";	--C
					when "1101" =>
						hex4 <= "0100001";	--D
					when "1110" =>
						hex4 <= "0000110";	--E
					when "1111" =>
						hex4 <= "0001110";	--F
					when others =>
						hex4 <= "1000000";	-- the R					
			end case;
			
			case temp_grph_color_green(5 downto 4) is 
					
					when "00" =>
						hex5 <= "1000000";	--0
					when "01" =>
						hex5 <= "1111001";   --1
					when "10" =>
						hex5 <= "0100100";   --2
					when "11" =>
						hex5 <= "0110000";   --3
					when others =>
						hex5 <= "0001000";	-- the R
						
			end case;
			
	end case;
		
	end process;

*/	

   -- implementing Synch Logic
	sync : process( all )
	
	variable lastButtonState : std_logic := '1'; 	
		
	begin
	
		if res_n = '0' then 
			current_state <= STATE_RED;
			--hex4 <= "0001000";     the R
			--hex5 <= "0001000";		 the R
		elsif rising_edge(clk) then
	
				-- rising down and we press the button
				if ( button = '0' and lastButtonState = '1' )then
						current_state <= next_state;
						lastButtonState := '0';
				end if;	
				
				-- rising up and we don't press the button 
				if ( button = '1' and lastButtonState = '0' ) then
						lastButtonState := '1';
				end if;	
			
		end if;			
							
	end process;
	
	
	--in Sensitivity List there is only color because only the inputs can change	
	input_number : process( color, debugX, debugY )
	begin
		
		--HEX0
		--case color( 3 downto 0 ) is
		case debugX(3 downto 0) is
			when "0000" => 
				hex0 <= "1000000";   --0
			when "0001" =>
				hex0 <= "1111001";   --1
			when "0010" =>
				hex0 <= "0100100";	--2
			when "0011" =>
				hex0 <= "0110000";	--3
			when "0100" =>
				hex0 <= "0011001";	--4
			when "0101" =>
				hex0 <= "0010010";	--5
			when "0110" =>
				hex0 <= "0000010";	--6
			when "0111" =>
				hex0 <= "1111000";	--7
			when "1000" =>
				hex0 <= "0000000";	--8
			when "1001" =>
				hex0 <= "0010000";	--9
			when "1010" =>
				hex0 <= "0001000";	--A
			when "1011" =>
				hex0 <= "0000011";	--B
			when "1100" =>
				hex0 <= "0100111";	--C
			when "1101" =>
				hex0 <= "0100001";	--D
			when "1110" =>
				hex0 <= "0000110";	--E
			when "1111" =>
				hex0 <= "0001110";	--F
			when others => 
				hex0 <= "1000000";	-- default case
			
		end case;	
				
		--HEX1			
		--case color( 7 downto 4 ) is
		case debugX(7 downto 4) is
		
			when "0000" => 
				hex1 <= "1000000";   --0
			when "0001" =>
				hex1 <= "1111001";   --1
			when "0010" =>
				hex1 <= "0100100";	--2
			when "0011" =>
				hex1 <= "0110000";	--3
			when "0100" =>
				hex1 <= "0011001";	--4
			when "0101" =>
				hex1 <= "0010010";	--5
			when "0110" =>
				hex1 <= "0000010";	--6
			when "0111" =>
				hex1 <= "1111000";	--7
			when "1000" =>
				hex1 <= "0000000";	--8
			when "1001" =>
				hex1 <= "0010000";	--9
			when "1010" =>
				hex1 <= "0001000";	--A
			when "1011" =>
				hex1 <= "0000011";	--B
			when "1100" =>
				hex1 <= "0100111";	--C
			when "1101" =>
				hex1 <= "0100001";	--D
			when "1110" =>
				hex1 <= "0000110";	--E
			when "1111" =>
				hex1 <= "0001110";	--F
			when others => 
				hex1 <= "1000000";	-- default case
				
		end case;	
				
		--HEX2
		--case color( 11 downto 8 ) is
		case debugX(11 downto 8) is
		
			when "0000" => 
				hex2 <= "1000000";   --0
			when "0001" =>
				hex2 <= "1111001";   --1
			when "0010" =>
				hex2 <= "0100100";	--2
			when "0011" =>
				hex2 <= "0110000";	--3
			when "0100" =>
				hex2 <= "0011001";	--4
			when "0101" =>
				hex2 <= "0010010";	--5
			when "0110" =>
				hex2 <= "0000010";	--6
			when "0111" =>
				hex2 <= "1111000";	--7
			when "1000" =>
				hex2 <= "0000000";	--8
			when "1001" =>
				hex2 <= "0010000";	--9
			when "1010" =>
				hex2 <= "0001000";	--A
			when "1011" =>
				hex2 <= "0000011";	--B
			when "1100" =>
				hex2 <= "0100111";	--C
			when "1101" =>
				hex2 <= "0100001";	--D
			when "1110" =>
				hex2 <= "0000110";	--E
			when "1111" =>
				hex2 <= "0001110";	--F
			when others => 
				hex2 <= "1000000";	-- default case
		end case;	
				
		--HEX3
		--remains free
		hex3 <= "0001000";	
				
		--HEX4			
		--case color( 7 downto 4 ) is
		case debugY(3 downto 0) is
		
			when "0000" => 
				hex4 <= "1000000";   --0
			when "0001" =>
				hex4 <= "1111001";   --1
			when "0010" =>
				hex4 <= "0100100";	--2
			when "0011" =>
				hex4 <= "0110000";	--3
			when "0100" =>
				hex4 <= "0011001";	--4
			when "0101" =>
				hex4 <= "0010010";	--5
			when "0110" =>
				hex4 <= "0000010";	--6
			when "0111" =>
				hex4 <= "1111000";	--7
			when "1000" =>
				hex4 <= "0000000";	--8
			when "1001" =>
				hex4 <= "0010000";	--9
			when "1010" =>
				hex4 <= "0001000";	--A
			when "1011" =>
				hex4 <= "0000011";	--B
			when "1100" =>
				hex4 <= "0100111";	--C
			when "1101" =>
				hex4 <= "0100001";	--D
			when "1110" =>
				hex4 <= "0000110";	--E
			when "1111" =>
				hex4 <= "0001110";	--F
			when others => 
				hex4 <= "1000000";	-- default case
					
		end case;	
		
		
		--HEX5			
		--case color( 7 downto 4 ) is
		case debugY(7 downto 4) is
		
			when "0000" => 
				hex5 <= "1000000";   --0
			when "0001" =>
				hex5 <= "1111001";   --1
			when "0010" =>
				hex5 <= "0100100";	--2
			when "0011" =>
				hex5 <= "0110000";	--3
			when "0100" =>
				hex5 <= "0011001";	--4
			when "0101" =>
				hex5 <= "0010010";	--5
			when "0110" =>
				hex5 <= "0000010";	--6
			when "0111" =>
				hex5 <= "1111000";	--7
			when "1000" =>
				hex5 <= "0000000";	--8
			when "1001" =>
				hex5 <= "0010000";	--9
			when "1010" =>
				hex5 <= "0001000";	--A
			when "1011" =>
				hex5 <= "0000011";	--B
			when "1100" =>
				hex5 <= "0100111";	--C
			when "1101" =>
				hex5 <= "0100001";	--D
			when "1110" =>
				hex5 <= "0000110";	--E
			when "1111" =>
				hex5 <= "0001110";	--F
			when others => 
				hex5 <= "1000000";	-- default case
					
		end case;	
		
		
		--HEX6			
		--case color( 7 downto 4 ) is
		case debugY(11 downto 8) is
		
			when "0000" => 
				hex6 <= "1000000";   --0
			when "0001" =>
				hex6 <= "1111001";   --1
			when "0010" =>
				hex6 <= "0100100";	--2
			when "0011" =>
				hex6 <= "0110000";	--3
			when "0100" =>
				hex6 <= "0011001";	--4
			when "0101" =>
				hex6 <= "0010010";	--5
			when "0110" =>
				hex6 <= "0000010";	--6
			when "0111" =>
				hex6 <= "1111000";	--7
			when "1000" =>
				hex6 <= "0000000";	--8
			when "1001" =>
				hex6 <= "0010000";	--9
			when "1010" =>
				hex6 <= "0001000";	--A
			when "1011" =>
				hex6 <= "0000011";	--B
			when "1100" =>
				hex6 <= "0100111";	--C
			when "1101" =>
				hex6 <= "0100001";	--D
			when "1110" =>
				hex6 <= "0000110";	--E
			when "1111" =>
				hex6 <= "0001110";	--F
			when others => 
				hex6 <= "1000000";	-- default case
					
		end case;	
		
		
		
		
		
		
	end process;
											
end architecture;
	