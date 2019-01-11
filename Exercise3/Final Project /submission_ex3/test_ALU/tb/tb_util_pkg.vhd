library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.op_pack.all;

package tb_util_pkg is
	function hex_to_slv(hex : string; min_width : integer) return std_logic_vector;
	
	function slv_to_hex(slv : in std_logic_vector) return string;
	
	function get_op(code : std_logic_vector(3 downto 0)) return alu_op_type;
	function slv_to_sl(code : string) return std_logic;
	function sl_to_hex(code : std_logic) return string;
	function slv_to_op(code : alu_op_type) return string;
end package;

package body tb_util_pkg is

	function slv_to_hex(slv : in std_logic_vector) return string is
		constant hex_digits : string(1 to 16) := "0123456789abcdef";
		constant num_hex_digits : integer := integer((slv'length+3)/4);
		variable ret_value : string(1 to num_hex_digits);
		variable zero_padded_slv : std_logic_vector((4*num_hex_digits)-1 downto 0) := (others=>'0');
		variable r : integer := 0;
	begin
		zero_padded_slv(slv'range) := slv;
		loop
			ret_value(num_hex_digits-r) :=  hex_digits(to_integer(unsigned( zero_padded_slv( (r+1)*4-1 downto 4*r) ))+1);
			r := r + 1;
			if num_hex_digits-r = 0 then
				exit;
			end if;
		end loop;
		return ret_value;
	end function;
	
	
	function max(a,b : integer) return integer is
	begin
		if a > b then
			return a;
		else
			return b;
		end if;
	end function;
	
	
	function hex_to_slv(hex : string; min_width : integer) return std_logic_vector is
		variable ret_value : std_logic_vector(max(hex'length*4-1,min_width-1) downto 0) := (others=>'0');
		variable temp : std_logic_vector(3 downto 0);
		variable r : integer := 0;
	begin
		ret_value := (others=>'0');
		--assert hex'length = hex'high - hex'low + 1 severity failure;
		for i in 0 to hex'length-1 loop
			case hex(hex'high-i) is
				when '0' => temp := x"0";
				when '1' => temp := x"1";	
				when '2' => temp := x"2";
				when '3' => temp := x"3";
				when '4' => temp := x"4";
				when '5' => temp := x"5";
				when '6' => temp := x"6";
				when '7' => temp := x"7";
				when '8' => temp := x"8";
				when '9' => temp := x"9";
				when 'a' | 'A' => temp := x"a";
				when 'b' | 'B' => temp := x"b";
				when 'c' | 'C' => temp := x"c";
				when 'd' | 'D' => temp := x"d";
				when 'e' | 'E' => temp := x"e";
				when 'f' | 'F' => temp := x"f";
				when others => report "Conversion Error: char: " & hex(hex'high-i) severity error;
			end case;
			ret_value((i+1)*4-1 downto i*4) := temp;
		end loop;
		return ret_value;
	end function;
	
    function get_op(code : std_logic_vector(3 downto 0)) return alu_op_type is
    begin
      case code is
        when x"0" =>
          return ALU_NOP; 
        when x"1" =>
          return ALU_SLT;
        when x"2" =>
          return ALU_SLTU;
        when x"3" =>
          return ALU_SLL;
        when x"4" =>
          return ALU_SRL;
        when x"5" =>
          return ALU_SRA;
        when x"6" =>
          return ALU_ADD;
        when x"7" =>
          return ALU_SUB;
        when x"8" =>
          return ALU_AND;
        when x"9" =>
          return ALU_OR;
        when x"a" =>
          return ALU_XOR;
        when x"b" =>
          return ALU_NOR;
        when x"c" =>
          return ALU_LUI;
        when others =>
          return ALU_NOP;
      end case;    
    end function;
    
   function slv_to_op(code : alu_op_type) return string is
   begin
     case code is
       when ALU_NOP =>
         return "ALU_NOP";
       when ALU_SLT =>
         return "ALU_SLT";
       when ALU_SLTU =>
         return "ALU_SLTU";
       when ALU_SLL =>
         return "ALU_SLL";
       when ALU_SRL =>
         return "ALU_SRL";
       when ALU_SRA =>
         return "ALU_SRA";
       when ALU_ADD =>
         return "ALU_ADD";
       when ALU_SUB =>
         return "ALU_SUB";
       when ALU_AND =>
         return "ALU_AND";
       when ALU_OR =>
         return "ALU_OR";
       when ALU_XOR =>
         return "ALU_XOR";
       when ALU_NOR =>
         return "ALU_NOR";
       when ALU_LUI =>
         return "ALU_LUI";
       when others =>
         return "Unknown ALU_OP";
     end case; 
   end function;
    
    function slv_to_sl(code : string) return std_logic is
    begin
      if code(1) = '0' then
        return '0';
      else
        return '1';
      end if;    
    end function;
    
   function sl_to_hex(code : std_logic) return string is
   begin
     if code = '0' then
       return "0";
     else
       return "1";
     end if;
   end function;


end package body;

