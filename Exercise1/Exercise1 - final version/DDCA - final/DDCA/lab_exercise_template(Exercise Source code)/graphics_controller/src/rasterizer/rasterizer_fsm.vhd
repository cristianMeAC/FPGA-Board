
----------------------------------------------------------------------------------
--                                LIBRARIES                                     --
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.graphics_controller_pkg.all;
use work.rasterizer_pkg.all;
----------------------------------------------------------------------------------
--                                 ENTITY                                       --
----------------------------------------------------------------------------------

entity rasterizer_fsm is
	generic (
		COLOR_DEPTH : integer := 3
	);
	port (
		clk	: in  std_logic;
		res_n	: in  std_logic;

		--connection to frame buffer fifo
		fb_addr : out std_logic_vector(18 downto 0); --! The address bus to the framebuffer.
		fb_data : out std_logic_vector(COLOR_DEPTH - 1 downto 0); --! The data bus to the framebuffer.
		fb_wr   : out std_logic; -- Write signal for the framebuffer FIFO
		fb_stall : in std_logic; --framebuffer FIFO is full
		
		instr      : in std_logic_vector(GCNTL_INSTR_WIDTH-1 downto 0);
		instr_rd   : out std_logic;
		instr_empty: in std_logic;
		
		current_color : out std_logic_vector(COLOR_DEPTH-1 downto 0)
	);
end entity;

----------------------------------------------------------------------------------
--                               ARCHITECTURE                                   --
----------------------------------------------------------------------------------

architecture beh of rasterizer_fsm is

	-- Rasterizer states
	type RASTERIZER_STATE_TYPE is (
		IDLE, 
		DECODE_INSTRUCTION, 
		SET_PIXEL,
		SET_COLOR,
		CLEAR_SCREEN,
		DRAW_LINE_INIT,
		DRAW_LINE_SET_PIXEL,
		DRAW_RECT_INIT,
		DRAW_RECT_SET_PIXEL, 
		DRAW_CIRCLE_INIT,
		DRAW_CIRCLE_SET_PIXEL
	);

	signal rasterizer_state : RASTERIZER_STATE_TYPE;
	signal rasterizer_state_next : RASTERIZER_STATE_TYPE;

	signal color : std_logic_vector(COLOR_DEPTH - 1 downto 0);
	signal color_next : std_logic_vector(COLOR_DEPTH - 1 downto 0);


	-- General purpose registers. These registers are used under 
	-- different names using the alias keyword (see below).
	-- Nomenclature:

	signal gp10u_2 : integer range 0 to 2**10-1;
	signal gp10u_2_next : integer range 0 to 2**10-1;
	signal gp9u_2 : integer range 0 to 2**9-1;
	signal gp9u_2_next : integer range 0 to 2**9-1;

	signal gp12s : integer range -2**11 to 2**11-1;
	signal gp12s_next : integer range -2**11 to 2**11-1;

	-- Signals for the Bresenham line algorithm.
	signal bresenham_x0      : integer range -2**10 to 2**10-1;
	signal bresenham_x0_next : integer range -2**10 to 2**10-1;
	signal bresenham_y0      : integer range -2**10 to 2**10-1;
	signal bresenham_y0_next : integer range -2**10 to 2**10-1;

	alias  dx       is gp10u_2;
	alias  dx_next  is gp10u_2_next;
	signal dy       : integer range -2**9 to 2**9-1;
	signal dy_next  : integer range -2**9 to 2**9-1;
	signal sx       : integer range -1 to 1;
	signal sx_next  : integer range -1 to 1;
	signal sy       : integer range -1 to 1;
	signal sy_next  : integer range -1 to 1;
	alias  err      is gp12s;
	alias  err_next is gp12s_next;

	-- Signals for drawing rectangles.
	alias origin_x             is gp10u_2;
	alias origin_x_next        is gp10u_2_next;
	alias origin_y             is gp9u_2;
	alias origin_y_next        is gp9u_2_next;
	signal walk_x               : integer range -1 to 1;
	signal walk_x_next          : integer range -1 to 1;
	signal walk_y               : integer range -1 to 1;
	signal walk_y_next          : integer range -1 to 1;
	signal march_to_origin      : boolean;
	signal march_to_origin_next : boolean;

	-- Signals for drawing circles.

	alias circle_balance is gp12s;
	alias circle_balance_next is gp12s_next;
	alias circle_xoff is gp10u_2;
	alias circle_xoff_next is gp10u_2_next;
	signal circle_yoff                   : integer range -2**10 to 2**10-1;
	signal circle_yoff_next              : integer range -2**10 to 2**10-1;
	signal circle_set_pixel_counter      : integer range 0 to 7;
	signal circle_set_pixel_counter_next : integer range 0 to 7;


	signal pixel_color : std_logic_vector(COLOR_DEPTH-1 downto 0);
	signal pixel_x     : std_logic_vector(9 downto 0);
	signal pixel_y     : std_logic_vector(9 downto 0);
	signal pixel_wr    : std_logic;
	
	alias opcode  : std_logic_vector(7 downto 0) is instr(7 downto 0);
	alias arg12_0 : std_logic_vector(11 downto 0) is instr(8+12*1-1 downto 8+12*0);
	alias arg12_1 : std_logic_vector(11 downto 0) is instr(8+12*2-1 downto 8+12*1);
	alias arg12_2 : std_logic_vector(11 downto 0) is instr(8+12*3-1 downto 8+12*2);
	alias arg12_3 : std_logic_vector(11 downto 0) is instr(8+12*4-1 downto 8+12*3);
	
	alias arg12_x0 : std_logic_vector(11 downto 0) is instr(8+12*1-1 downto 8+12*0);
	alias arg12_y0 : std_logic_vector(11 downto 0) is instr(8+12*2-1 downto 8+12*1);
	alias arg12_x1 : std_logic_vector(11 downto 0) is instr(8+12*3-1 downto 8+12*2);
	alias arg12_y1 : std_logic_vector(11 downto 0) is instr(8+12*4-1 downto 8+12*3);
begin

	current_color <= color;


	--------------------------------------------------------------------
	--                    PROCESS : SYNC                              --
	--------------------------------------------------------------------
	sync : process(res_n, clk)
	begin
		if res_n = '0' then
			rasterizer_state <= IDLE;
			color <= x"aaaa";
			--bresenham_x0 <= 0;
			--bresenham_y0 <= 0;
			march_to_origin <= false;
			circle_set_pixel_counter <= 0;
		elsif rising_edge(clk) then
			rasterizer_state <= rasterizer_state_next;
			color <= color_next;

			bresenham_x0 <= bresenham_x0_next;
			bresenham_y0 <= bresenham_y0_next;

			dx <= dx_next;
			dy <= dy_next;
			sx <= sx_next;
			sy <= sy_next; 
			err <= err_next;

			origin_x <= origin_x_next;
			origin_y <= origin_y_next;
			walk_x <= walk_x_next;
			walk_y <= walk_y_next;
			march_to_origin <= march_to_origin_next;

			circle_balance <= circle_balance_next;
			circle_xoff <= circle_xoff_next;
			circle_yoff <= circle_yoff_next;
			circle_set_pixel_counter <= circle_set_pixel_counter_next;
		end if;
	end process;

	--------------------------------------------------------------------
	--                    PROCESS : NEXT_STATE                        --
	--------------------------------------------------------------------
	next_state : process (
		rasterizer_state,
		instr_empty,
		instr, 
		bresenham_x0, bresenham_y0,
		origin_y, 
		fb_stall, circle_yoff)
	begin
		rasterizer_state_next <= rasterizer_state; --default
			
		case rasterizer_state is
			when IDLE => 
				if instr_empty = '0' then
					rasterizer_state_next <= DECODE_INSTRUCTION;
				end if;
			when DECODE_INSTRUCTION =>
				case opcode is 
					when GCNTL_INSTR_CLEAR_SCREEN =>
						rasterizer_state_next <= CLEAR_SCREEN;
					when GCNTL_INSTR_CHANGE_COLOR =>
						rasterizer_state_next <= SET_COLOR;
					when GCNTL_INSTR_SET_PIXEL =>
						rasterizer_state_next <= SET_PIXEL;
					when GCNTL_INSTR_DRAW_LINE =>
						rasterizer_state_next <= DRAW_LINE_INIT;
					when GCNTL_INSTR_DRAW_RECTANGLE =>
						rasterizer_state_next <= DRAW_RECT_INIT;
					when GCNTL_INSTR_DRAW_CIRCLE => 
						rasterizer_state_next <= DRAW_CIRCLE_INIT;
					when others =>
						rasterizer_state_next <= IDLE;
				end case;
			when SET_PIXEL =>
				if (fb_stall = '0') then
					rasterizer_state_next <= IDLE;
				end if;
			when DRAW_LINE_INIT =>
				rasterizer_state_next <= DRAW_LINE_SET_PIXEL;
			when DRAW_RECT_INIT =>
				rasterizer_state_next <= DRAW_RECT_SET_PIXEL;
			when DRAW_LINE_SET_PIXEL =>
				-- Stop condition when drawing segments.
				if (fb_stall = '0') then
					if bresenham_x0 = arg12_x1 and 
						bresenham_y0 = arg12_y1 then
						rasterizer_state_next <= IDLE;
					end if;
				end if;
			when DRAW_RECT_SET_PIXEL =>
				-- Stop condition when drawing rectangles.
				if origin_x = arg12_x1 and origin_y = arg12_y1 then
					rasterizer_state_next <= IDLE;
				end if;
			when DRAW_CIRCLE_INIT => 
				rasterizer_state_next <= DRAW_CIRCLE_SET_PIXEL;
			when DRAW_CIRCLE_SET_PIXEL =>
				-- Stop condition when drawing circles.
				if circle_xoff > circle_yoff then
					rasterizer_state_next <= IDLE;
				end if;
			when SET_COLOR =>
				rasterizer_state_next <= IDLE;
			when CLEAR_SCREEN =>
				-- Stop condition when clearing the display.
				if bresenham_x0 = DISPLAY_WIDTH and bresenham_y0 = DISPLAY_HEIGHT then
					rasterizer_state_next <= IDLE;
				end if;
		end case;
	end process;

	--------------------------------------------------------------------
	--                    PROCESS : OUTPUT                            --
	--------------------------------------------------------------------
	output : process (
		rasterizer_state, 
		instr_empty, 
		instr, 
		color, 
		bresenham_x0, 
		bresenham_y0, 
		dx, dy, sx, sy, err, 
		origin_x, origin_y,
		walk_x, walk_y,
		march_to_origin, 
		--circle_balance, 
		circle_xoff, circle_yoff,
		circle_set_pixel_counter,fb_stall)
	
		-- Variables for Bresenham's segment algorithm.
		variable err_temp_var : integer range -2**11 to 2**11-1 := 0;
	
		-- Variable for Bresenham's circle algorithm.
		variable var_circle_balance : integer range -2**11 to (2**11)-1;
		variable var_circle_xoff :    integer range -2**10 to 2**10-1;
		variable var_circle_yoff :    integer range -2**10 to 2**10-1;
		variable var_setpixel_x :     integer range -2**11 to (2**11)-1;
		variable var_setpixel_y :     integer range -2**11 to (2**11)-1;
	begin
	
		-- Default assignments.
		instr_rd <= '0';
		color_next <= color;
		pixel_wr <= '0';
		pixel_x <= (others=>'0');
		pixel_y <= (others=>'0');
		pixel_color <= (others=>'0');

		bresenham_x0_next <= bresenham_x0;
		bresenham_y0_next <= bresenham_y0;

		err_temp_var := err; 
		
		dx_next <= dx;
		dy_next <= dy;
		sx_next <= sx;
		sy_next <= sy; 
		err_next <= err;

		-- Signals for drawing rectangles
		origin_x_next <= origin_x;
		origin_y_next <= origin_y;
		walk_x_next <= walk_x;
		walk_y_next <= walk_y;
		march_to_origin_next <= march_to_origin;
		
		-- Signals for drawing circles.
		circle_balance_next <= circle_balance;
		circle_xoff_next <= circle_xoff;
		circle_yoff_next <= circle_yoff;
		circle_set_pixel_counter_next <= circle_set_pixel_counter;

		-- Variables for drawing circles.
		var_circle_balance := circle_balance;
		var_circle_xoff := circle_xoff;
		var_circle_yoff := circle_yoff;
		
		var_setpixel_x := 0;
		var_setpixel_y := 0;
		
		
		case rasterizer_state is
			when IDLE =>
				if instr_empty = '0' then
					instr_rd <= '1';
				end if;
			when DECODE_INSTRUCTION =>
				case opcode is 
					when GCNTL_INSTR_CLEAR_SCREEN =>
						bresenham_x0_next <= 0;
						bresenham_y0_next <= 0;
					when GCNTL_INSTR_CHANGE_COLOR =>
					when GCNTL_INSTR_SET_PIXEL =>
					when GCNTL_INSTR_DRAW_LINE =>
					when GCNTL_INSTR_DRAW_RECTANGLE =>
					when GCNTL_INSTR_DRAW_CIRCLE =>
					when others =>
				end case;
			when CLEAR_SCREEN =>
				pixel_color <= (others=>'0');
				pixel_y <= std_logic_vector(to_unsigned(bresenham_y0,10));
				pixel_x <= std_logic_vector(to_unsigned(bresenham_x0,10));
				
				if (fb_stall = '0') then  
					pixel_wr <= '1';
					if bresenham_x0 < DISPLAY_WIDTH then 
						bresenham_x0_next <= bresenham_x0 + 1;
					else
						bresenham_x0_next <= 0;
						bresenham_y0_next <= bresenham_y0 + 1;
					end if;
				end if;
			when DRAW_LINE_INIT =>

				bresenham_x0_next <= to_integer(unsigned(arg12_x0));
				bresenham_y0_next <= to_integer(unsigned(arg12_y0));

				-- Initialize all the signals needed for drawing a segment line with 
				-- Bresenham's algorithm.
				dx_next <= abs(
					to_integer(signed('0' & arg12_2) - signed('0' & arg12_0))
				);
				
				dy_next <= -abs(
					to_integer(signed('0' & arg12_3) - signed('0' & arg12_1))
				);
				
				
				if arg12_0 < arg12_2 then
					sx_next <= 1;
				else
					sx_next <= -1;
				end if;

				if arg12_1 < arg12_3 then
					sy_next <= 1;
				else
					sy_next <= -1;
				end if;

				err_next <= abs(to_integer(signed('0' & arg12_2) - signed('0' & arg12_0)))-
				            abs(to_integer(signed('0' & arg12_3) - signed('0' & arg12_1)));
				            
			when DRAW_LINE_SET_PIXEL =>
				pixel_color <= color;
				pixel_y <= std_logic_vector(to_unsigned(bresenham_y0,10));
				pixel_x <= std_logic_vector(to_unsigned(bresenham_x0,10));

				if ( fb_stall = '0') then 
					pixel_wr <= '1';
					--
					-- The following two if-statements can be true 
					-- at the same time!!!! That means that only 
					-- the last signal assignment is executed if 
					-- only signals for the error are used!!!!!
					if (err*2) >= dy then 
						err_temp_var := err + dy;
						bresenham_x0_next <= bresenham_x0 + sx; 
					end if; 
				
					if (err*2) <= dx then 
						err_temp_var := err_temp_var + dx;
						bresenham_y0_next <= bresenham_y0 + sy; 
					end if;
				
					err_next <= err_temp_var;
				end if;
				
			when DRAW_RECT_INIT =>
				bresenham_x0_next <= to_integer(unsigned(arg12_x0));
				bresenham_y0_next <= to_integer(unsigned(arg12_y0));
				-- Save the starting point.
				origin_x_next <= to_integer(unsigned(arg12_x0));
				origin_y_next <= to_integer(unsigned(arg12_y0));
				
				-- Find out the marching direction.
				if arg12_x0 < arg12_x1 then 
					walk_x_next <= 1;
				else
					walk_x_next <= -1;
				end if;
				
				if arg12_y0 < arg12_y1 then
					walk_y_next <= 1;
				else
					walk_y_next <= -1;
				end if;
				
			when DRAW_RECT_SET_PIXEL =>
				pixel_color <= color;
				pixel_y <= std_logic_vector(to_unsigned(bresenham_y0,10));
				pixel_x <= std_logic_vector(to_unsigned(bresenham_x0,10));

				if (fb_stall = '0') then
					pixel_wr <= '1';
					-- Always march in x-direction first, then y-, then x- and finally y-direction i. e.
					-- march in a rectangular circle (from the origin to the second point and then back 
					-- to the origin) :-D
				
					-- March from the origin to the second point.
					if march_to_origin = false then
						if bresenham_x0 /= arg12_x1 then
							bresenham_x0_next <= bresenham_x0 + walk_x;
						elsif bresenham_y0 /= arg12_y1 then
							bresenham_y0_next <= bresenham_y0 + walk_y;
						else
							march_to_origin_next <= true;
						end if;
					else
						-- March from the second point back to the origin.
						if bresenham_x0 /= origin_x then
							bresenham_x0_next <= bresenham_x0 - walk_x;
						elsif bresenham_y0 /= origin_y then
							bresenham_y0_next <= bresenham_y0 - walk_y;
						else
							march_to_origin_next <= false;
							origin_x_next <= to_integer(unsigned(arg12_x1));
							origin_y_next <= to_integer(unsigned(arg12_y1));
						end if;
					end if;
				end if;

			when DRAW_CIRCLE_INIT =>
				
				bresenham_x0_next <= to_integer(unsigned(arg12_x0));
				bresenham_y0_next <= to_integer(unsigned(arg12_y0));
				
				-- Initialize all the signals needed for drawing a circle with 
				-- an algorithm found at http://actionsnippet.com/?p=492.
				circle_set_pixel_counter_next <= 0;
				
				circle_balance_next <= -to_integer(signed('0' & arg12_2));
				circle_xoff_next <= 0;
				circle_yoff_next <= to_integer(unsigned(arg12_2));
				
			when DRAW_CIRCLE_SET_PIXEL => 
			
				-- Calculate the next pixel address to color when drawing circles
				-- with an algorithm found at http://actionsnippet.com/?p=492.
				pixel_color <= color;
				
				if circle_set_pixel_counter = 0 then
					var_setpixel_y := bresenham_y0 + var_circle_yoff;
					var_setpixel_x := bresenham_x0 + var_circle_xoff;
					
				elsif circle_set_pixel_counter = 1 then
					var_setpixel_y := bresenham_y0 + var_circle_yoff;
					var_setpixel_x := bresenham_x0 - var_circle_xoff;
										
				elsif circle_set_pixel_counter = 2 then
					var_setpixel_y := bresenham_y0 - var_circle_yoff;
					var_setpixel_x := bresenham_x0 + var_circle_xoff;
					
				elsif circle_set_pixel_counter = 3 then
					var_setpixel_y := bresenham_y0 - var_circle_yoff;
					var_setpixel_x := bresenham_x0 - var_circle_xoff;
					
				elsif circle_set_pixel_counter = 4 then
					var_setpixel_y := bresenham_y0 + var_circle_xoff;
					var_setpixel_x := bresenham_x0 + var_circle_yoff;
					
				elsif circle_set_pixel_counter = 5 then
					var_setpixel_y := bresenham_y0 + var_circle_xoff;
					var_setpixel_x := bresenham_x0 - var_circle_yoff;
					
				elsif circle_set_pixel_counter = 6 then
					var_setpixel_y := bresenham_y0 - var_circle_xoff;
					var_setpixel_x := bresenham_x0 + var_circle_yoff;
					
				elsif circle_set_pixel_counter = 7 then
					var_setpixel_y := bresenham_y0 - var_circle_xoff;
					var_setpixel_x := bresenham_x0 - var_circle_yoff;
				end if;
				
				-- Apply the LCD pixel address limits (i. e. native LCD 
				-- resolution) to the calculated pixel addresses.
				if (fb_stall = '0') then
				
					if circle_set_pixel_counter = 7 then   --only for stupid model sim
						circle_set_pixel_counter_next <= 0;
				
						var_circle_balance := var_circle_balance + (2*var_circle_xoff);
					
						if var_circle_balance  >= 0 then
		
							var_circle_yoff := var_circle_yoff - 1;
							var_circle_balance := var_circle_balance - (2*var_circle_yoff);
					
						end if;
					
						var_circle_xoff := var_circle_xoff + 1;
					
						circle_balance_next <= var_circle_balance;
						circle_xoff_next <= var_circle_xoff;
						circle_yoff_next <= var_circle_yoff;
					else
						circle_set_pixel_counter_next <= circle_set_pixel_counter + 1;
					end if;
				
					if var_setpixel_x >= 0 and var_setpixel_x < 800 and 
					   var_setpixel_y >= 0 and var_setpixel_y < 480 then
					
						pixel_y <= std_logic_vector(to_unsigned(var_setpixel_y,10));
						pixel_x <= std_logic_vector(to_unsigned(var_setpixel_x,10));
						pixel_wr <= '1';
					end if;
				end if;

			when SET_PIXEL =>
				if (fb_stall = '0') then
					pixel_color <= color;
					pixel_y <= arg12_y0(pixel_y'range);
					pixel_x <= arg12_x0(pixel_x'range);
					pixel_wr <= '1';
				end if;
			when SET_COLOR => 
				color_next <= instr(COLOR_DEPTH+8 - 1 downto 8);
			when others =>
		end case;
	
	end process;


	address_generator : block
		signal pixel_color_stage1 : std_logic_vector(COLOR_DEPTH-1 downto 0);
		signal pixel_x_stage1     : std_logic_vector(9 downto 0);
		signal pixel_y_stage1     : std_logic_vector(9 downto 0);
		signal pixel_wr_stage1    : std_logic;
		
		signal pixel_color_stage2 : std_logic_vector(COLOR_DEPTH-1 downto 0);
		signal pixel_addr_stage2  : std_logic_vector(fb_addr'range);
		signal pixel_wr_stage2    : std_logic;
	begin
	
		process(res_n, clk)
			variable mul_result : std_logic_vector(pixel_x'length+pixel_y'length-1 downto 0);
		begin
			if res_n = '0' then
				pixel_color_stage1 <= (others=>'0');
				pixel_x_stage1 <= (others=>'0');
				pixel_y_stage1 <= (others=>'0');
				pixel_wr_stage1 <= '0';
				pixel_wr_stage2 <= '0';
				pixel_color_stage2 <= (others=>'0');
				pixel_addr_stage2 <= (others=>'0');
			elsif rising_edge(clk) then
				if(fb_stall = '0') then
					pixel_color_stage1 <= pixel_color;
					pixel_x_stage1 <= pixel_x;
					pixel_y_stage1 <= pixel_y;
					pixel_wr_stage1 <= pixel_wr;
					
					pixel_wr_stage2 <= pixel_wr_stage1;
					pixel_color_stage2 <= pixel_color_stage1;
					mul_result := std_logic_vector(unsigned(pixel_y_stage1) * DISPLAY_WIDTH + unsigned(pixel_x_stage1));
					pixel_addr_stage2 <= mul_result(fb_addr'range);
				end if;
			end if;
		end process;
		
		process (pixel_color_stage2, pixel_wr_stage2, pixel_addr_stage2, fb_stall)
		begin
			fb_data <= pixel_color_stage2;
			fb_addr <= pixel_addr_stage2;
			if(fb_stall = '0') then
				fb_wr <= pixel_wr_stage2;
			else
				fb_wr <= '0';
			end if;
		end process;
	end block;

end architecture;


