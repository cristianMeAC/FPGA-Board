library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;
use work.alu;


entity tb is 
end tb;

architecture beh of tb is
  signal TB_op : alu_op_type;
  signal TB_a, TB_b, TB_r : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
  signal TB_z, TB_v : std_logic;
begin

  UUT: entity work.alu port map (
    op => TB_op,
    A => TB_a,
    B => TB_b,
    R => TB_r,
    Z => TB_z,
    V => TB_v
  );

  tb_proc: process
  begin
    wait for 1 ms;
    TB_a <= x"00004444";
    TB_b <= x"00001234";
    TB_op <= ALU_NOP; -- => R <= A

    wait for 1 ms;
    TB_op <= ALU_LUI; -- => R <= x"12340000"

    wait for 1 ms;
    TB_op <= ALU_SLT; -- => R <= 0

    wait for 1 ms;
    TB_a <= x"00001234";
    TB_b <= x"00004444";
    TB_op <= ALU_SLT; -- R <= 1

    wait for 1 ms;
    TB_a <= x"ffffff9c"; -- -100 => R <= 1

    wait for 1 ms;
    TB_b <= x"ffffff38"; -- -200 => R <= 0

    wait for 1 ms;
    TB_op <= ALU_SLTU;
    TB_b <= x"ffffff9c";
    TB_a <= x"ffffff38"; -- R <= 1
    

    wait for 1 ms;
    TB_op <= ALU_SLL;
    TB_b <= x"00000001";
    TB_a <= x"0000001f"; -- R <= "10000000" & x"000000"

    wait for 1 ms;
    TB_b <= x"80000000";
    TB_op <= ALU_SRL;  -- R <= x"00000001"

    wait for 1 ms;
    TB_op <= ALU_SRA;  -- R <= x"ffffffff"

    wait for 1 ms;
    TB_a <= x"00000000"; -- Z <= 1;
    TB_b <= x"00000005"; 
    TB_op <= ALU_ADD;    -- R <= x"00000005"

    wait for 1 ms;
    TB_a <= x"ffffffff"; -- Z <= 0, R <= -1 + 5 = 4

    wait for 1 ms;
    TB_a <= x"7fffffff"; -- V <= 1; R <= 2147483647 + 5 (overflow) 

    wait for 1 ms;
    TB_a <= x"80000000"; -- V <= 1; R <= -2147483648 + (-2147483648) (overflow)
    TB_b <=  x"80000000";

    wait for 1 ms;
    TB_op <= ALU_SUB;
    TB_a <= x"00000005";
    TB_b <= x"00000005"; -- Z <= 0, R <= 0

    wait for 1 ms;
    TB_a <= x"7fffffff";
    TB_b <= x"ffffffff"; -- V <= 1, R <= 2147483647 - (-1) (overflow)

    wait for 1 ms;
    TB_a <= x"80000000"; -- V <= 1. R <= -2147483648 - 2147483647 (overflow)
    TB_b <= x"7fffffff";

    wait for 1 ms;
    TB_a <= x"0000ffff";
    TB_b <= x"0000ffff";
    TB_op <= ALU_AND;

    wait for 1 ms;
    TB_b <= x"ffff0000";
    TB_op <= ALU_OR;

    wait for 1 ms;
    TB_a <= x"ffffffff";
    TB_b <= x"0f0f0f0f";
    TB_op <= ALU_XOR;

    wait for 1 ms;
    TB_a <= x"f0f0f0f0";
    TB_op <= ALU_NOR;

    
    

    wait;
  end process;
  

end architecture;