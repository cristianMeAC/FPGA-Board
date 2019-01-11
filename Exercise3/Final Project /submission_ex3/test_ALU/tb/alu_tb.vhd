library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_util_pkg.all;
use work.core_pack.all;
use work.op_pack.all;
use work.alu;

library std;
use std.textio.all;
use ieee.std_logic_textio.all;

entity alu_tb is
end entity;

architecture beh of alu_tb is
  signal TB_op : alu_op_type := ALU_NOP;
  signal TB_A, TB_B, TB_R : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal TB_Z, TB_V : std_logic := '0';
  
  signal r_flag : std_logic := '0';
 
  file input_file : text;
  file output_ref_file : text;
  
begin

  uut: entity work.alu port map (
         op => TB_op,
         A => TB_A,
         B => TB_B,
         R => TB_R,
         Z => TB_Z,
         V => TB_V
       );
       
   stimulus: process
     variable fstatus: file_open_status;
     variable l : line;
     variable op_temp : alu_op_type;
     variable a_temp : std_logic_vector(DATA_WIDTH-1 downto 0);
     variable b_temp : std_logic_vector(DATA_WIDTH-1 downto 0);
   begin

       file_open(fstatus, input_file, "testdata/input.txt", READ_MODE);

   
       --readline(input_file, l);

       while not endfile(input_file) loop
         wait for 3 ns;
     
         readline(input_file, l);
         if(l(1) = '#') then --ignore comments
           next;
         end if;
       
         op_temp := get_op(hex_to_slv(l(1 to 1), 4));
         readline(input_file, l);
         a_temp := hex_to_slv(l(1 to 8), 32);
         readline(input_file, l);
         b_temp := hex_to_slv(l(1 to 8), 32);
       
         TB_op <= op_temp;
         TB_a <= a_temp;
         TB_b <= b_temp;
       end loop;
       file_close(input_file);

     wait;
   end process;
   

   check_output: process
     variable fstatus: file_open_status;
     variable l : line;
     variable temp_r : std_logic_vector(DATA_WIDTH-1 downto 0);
     variable temp_z : std_logic;
     variable temp_v : std_logic;
   begin


       file_open(fstatus, output_ref_file, "testdata/output.txt", READ_MODE);

       wait for 1 ns;
     
       while not endfile(output_ref_file) loop
         wait for 3 ns;

         readline(output_ref_file, l);
         if(l(1) = '#') then --ignore comment lines 
           next;
         end if;
         temp_r := hex_to_slv(l(1 to 8), 32);
         readline(output_ref_file, l);
         temp_z := slv_to_sl(l(1 to 1));
         readline(output_ref_file, l);
         temp_v := slv_to_sl(l(1 to 1));

         assert(temp_r = TB_r and temp_z = TB_z and temp_v = TB_v) report "got [" & slv_to_hex(TB_r) & "][" & sl_to_hex(TB_z) & "][" & sl_to_hex(TB_v) & "] expected [" & slv_to_hex(temp_r) & "][" & sl_to_hex(temp_z) & "][" & sl_to_hex(temp_v) & "] by operation " & slv_to_op(TB_op) & " with A=[" & slv_to_hex(TB_A) & "], B=[" & slv_to_hex(TB_B) & "]" severity error;
       end loop;
       file_close(output_ref_file);

     wait;

   end process; 
   

end architecture;
