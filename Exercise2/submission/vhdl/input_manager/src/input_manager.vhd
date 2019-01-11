--introduce code here

library ieee;
use ieee.std_logic_1164.all;
use work.graphics_controller_pkg.all;
use ieee.numeric_std.all; 

	entity input_manager is

		port(
			clk 	: in std_logic;
			res_n : in std_logic;
			
			switches 				: in std_logic_vector  ( 15 downto 0 );
			
			change_color_button  : in  std_logic;
			change_mode_button   : in  std_logic;
			
			hex7						: out std_logic_vector ( 6 downto 0 );
			
			instr_wr					: out std_logic;
			instr						: out std_logic_vector ( 55 downto 0 );
			instr_full				: in  std_logic;
			
			x_input					: in std_logic_vector ( 11 downto 0 );
			y_input 					: in std_logic_vector ( 11 downto 0 )
			
			
		);

	end entity;	
	
architecture beh of input_manager is

	-- FSM Assignment
	type INPUT_MANAGER_STATE is (IDLE, BUTTON_MODE, BUTTON_COLOR, GENERATE_PIXELS, RESET );
   signal state, state_next : INPUT_MANAGER_STATE;
	
	-- FSM Drawing possibilities in Button_Mode state
	type DRAWING_MODE        is (IDLE_MODE, HAND_MODE  , LINE_MODE   , RECTANGLE_MODE , CIRCLE_MODE, FILL_MODE);
	signal mode , mode_next	 : DRAWING_MODE;
     
   signal hex7_next : std_logic_vector (6 downto 0);


	
	
	signal change_mode_button_last  : std_logic := '0';
	signal change_color_button_last : std_logic;
	
	signal instr_wr_next : std_logic;
	signal instr_next    : std_logic_vector ( 55  downto 0);
	
	signal x_old  			: std_logic_vector ( 11 downto 0 );
	signal y_old  			: std_logic_vector ( 11 downto 0 );
	
begin
	
	--	if ( switches(0) = '1' ) then
	--		ledr <= '1';
	--	end if;	
	
   --------------------------------------------------------------------
   --                    PROCESS : SYNC                              --
   --------------------------------------------------------------------
	sync : process (all)
	begin
		if ( res_n = '0' ) then
		
			state <= IDLE;
         mode <= IDLE_MODE;
		
		
		elsif rising_edge(clk)  then
			
				state <= state_next;
            hex7  <= hex7_next;
            mode  <=  mode_next;
				change_mode_button_last <= change_mode_button;
				change_color_button_last <= change_color_button;
			
				
				x_old <= x_input;
				y_old <= y_input;
		
		end if;
	
	end process;
	
	
   --------------------------------------------------------------------
   --                    PROCESS : Next State                        --
   --------------------------------------------------------------------
	next_state : process(all)
	begin
	
		state_next <= state;
	
		case state is 
			
			when IDLE =>
				
				-- rising down and we press the button(we can not program it, it will return to 1)
				if ( change_mode_button = '0' and change_mode_button_last = '1' ) then
					state_next <= BUTTON_MODE;
				end if;
				
				if ( change_color_button = '0' and change_color_button_last = '1' ) then
					state_next <= BUTTON_COLOR;
				end if;
				
				-- when the coordinates are different, then i want to generate the pixels
				if  (x_old /= x_input) or (y_old /= y_input)	then
					state_next <= GENERATE_PIXELS;
				end if;
				
			when BUTTON_MODE =>
					state_next <= IDLE;
		
			when BUTTON_COLOR =>
					state_next <= IDLE;
		
			when GENERATE_PIXELS => 
					-- the Coordinates are the same 
					if  (x_old = x_input) and (y_old = y_input)	then
						state_next <= IDLE;
					end if;
			when RESET =>
					state_next <= IDLE;
		
		
		
		end case;


	end process;
	
	
	
	--------------------------------------------------------------------
   --                    PROCESS : Output                            --
   --------------------------------------------------------------------
	output : process(all)
	
	--variable x_input_unsigned : std_logic_vector (15 downto 0);
	--variable y_input_unsigned : std_logic_vector (15 downto 0);
	
	--variable x_input_stdVect  : std_logic_vector (15 downto 0);
	--variable y_input_stdVect  : std_logic_vector (15 downto 0);
	
	begin
		
		  -- default	
        hex7_next <= hex7;
        mode_next <= mode;
		  instr_wr <= '0';
		  instr <= (others => '0');
		  
    
 
        case state is 
			
				when IDLE =>
            
                case mode is
                    
                    when IDLE_MODE =>              --  -
                        hex7_next <= "0110110";    --  -
                                                   --  -
                        
                    when HAND_MODE => 
                        hex7_next <= "0001001";     -- H
                        
                    when LINE_MODE =>
                        hex7_next <= "1000111";     -- L
                        
                    when RECTANGLE_MODE =>
                        hex7_next <= "0011100";     -- D
                        
                    when CIRCLE_MODE =>
                        hex7_next <= "0011110";     -- C
                        
                    when FILL_MODE =>
                        hex7_next <= "0001110";     -- F
                  
                end case;
			
				when BUTTON_MODE =>
            
                case mode is
                    
                    when IDLE_MODE =>
                        mode_next <= HAND_MODE;
                        
                    when HAND_MODE =>
                        mode_next <= LINE_MODE;
                        
                    when LINE_MODE =>
                        mode_next <= RECTANGLE_MODE;
                        
                    when RECTANGLE_MODE =>
                        mode_next <= CIRCLE_MODE;
                        
                    when CIRCLE_MODE =>
                        mode_next <= FILL_MODE;
                                         
                    when FILL_MODE =>
                        mode_next <= IDLE_MODE ;    
                        
                end case; 
					 
		
		
				when BUTTON_COLOR =>
            
		
		
				when GENERATE_PIXELS => 
				
					
						case mode is
						
							when IDLE_MODE =>
								--do nothing
								
							when HAND_MODE =>	
									--instr_wr <= '1';
									--x_input_stdVect := x_input & "0000";
									--y_input_stdVect := y_input & "0000";
								
									--Conversion from Std_logic_vector to unsigned
--									x_input_stdVect := std_logic_vector(to_unsigned(to_integer(unsigned((x_input_stdVect srl 3))) + to_integer(unsigned((x_input_stdVect srl 4))) + to_integer(unsigned((x_input_stdVect srl 8))) + to_integer(unsigned((x_input_stdVect srl 9))) 
--									+ to_integer(unsigned((x_input_stdVect srl 10))) + to_integer(unsigned((x_input_stdVect srl 11))) + to_integer(unsigned((x_input_stdVect srl 12))),16)) ;
--									
--									y_input_stdVect := std_logic_vector(unsigned((y_input_stdVect srl 4)) + unsigned((y_input_stdVect srl 5)) +unsigned((y_input_stdVect srl 6))
--									+	unsigned((y_input_stdVect srl 8)) + unsigned((y_input_stdVect srl 9)) + unsigned((y_input_stdVect srl 10)) + unsigned((y_input_stdVect srl 11)) +
--									unsigned((y_input_stdVect srl 12)) );
									
									instr(7 downto 0)   <= GCNTL_INSTR_SET_PIXEL;
									
									-- axes inter-changed because of the TouchScreen
									instr(19 downto 8)  <= y_input;	 
									instr(31 downto 20) <= x_input;   
									instr(55 downto 32) <= (others => '0');
							
							
							when LINE_MODE =>	 
							
							
							when RECTANGLE_MODE =>
							
							
							when CIRCLE_MODE =>
							
							
							when FILL_MODE =>
						
						
						end case;
						
						if ( instr_full = '0' ) then
								instr_wr <= '1';
			
						end if;
            
            
				when RESET =>
		
		
		
		end case;

		

	end process;

	
	
end architecture;	


