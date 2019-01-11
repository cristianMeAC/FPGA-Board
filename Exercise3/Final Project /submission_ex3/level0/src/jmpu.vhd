library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity jmpu is
	port (
		op   : in  jmp_op_type;  -- operation
		N    : in  std_logic;    -- negative flag 
        Z    : in  std_logic;    -- zero flag
		J    : out std_logic     -- jump
    );
        
end jmpu;


architecture rtl of jmpu is

  
begin  -- rtl

    with op select
        J <= '0' when JMP_NOP,
             '1' when JMP_JMP,
              Z  when JMP_BEQ,
             (not Z)       when JMP_BNE,
             (N or Z)      when JMP_BLEZ,
             not((N or Z)) when JMP_BGTZ,
             N             when JMP_BLTZ,
             not(N)        when JMP_BGEZ;
          
end rtl;
