library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity alu is
	port (
		op   : in  alu_op_type;
		A, B : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		R    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		Z    : out std_logic;
		V    : out std_logic);

end alu;

architecture rtl of alu is

    signal lt  : std_logic;
    signal ltu : std_logic;

    signal eq  : std_logic;
    signal eqz : std_logic;

    signal va : std_logic;
    signal vs : std_logic;

begin  -- rtl

lt  <= '1' when signed(A)   < signed (B) else '0';
ltu <= '1' when unsigned(A) < unsigned(B) else '0';

with op select 
    R <= A                                             when ALU_NOP,
	     std_logic_vector(shift_left(unsigned(B), 16)) when ALU_LUI,
	     (0 => lt, others => '0')                      when ALU_SLT,  -- 0-te Bit bekommt wert von lt
       
	     (0 => ltu, others => '0')                     when ALU_SLTU,
	     std_logic_vector(shift_left(unsigned(B), to_integer(unsigned(A(DATA_WIDTH_BITS-1 downto 0)))))  when ALU_SLL,
	     std_logic_vector(shift_right(unsigned(B), to_integer(unsigned(A(DATA_WIDTH_BITS-1 downto 0))))) when ALU_SRL,
	     std_logic_vector(shift_right(signed(B), to_integer(unsigned(A(DATA_WIDTH_BITS-1 downto 0)))))   when ALU_SRA,
	     std_logic_vector(unsigned(A)+unsigned(B)) when ALU_ADD,
	     std_logic_vector(unsigned(A)-unsigned(B)) when ALU_SUB,
	     (A and B) when ALU_AND,
	     (A or B)  when ALU_OR,
	     (A xor B) when ALU_XOR,
	     (not (A or B)) when ALU_NOR;


eq  <= '1' when A = B else '0';
eqz <= '1' when unsigned(A) = 0 else '0';

with op select 
    Z <= eq  when ALU_SUB,
	     eqz when others;

va <= '1' when ((signed(A) >= 0 and signed(B) >= 0 and signed(R) < 0) or (signed(A) < 0 and signed(B) < 0 and signed(R) >= 0)) else '0';
vs <= '1' when ((signed(A) >= 0 and signed(B) < 0 and signed(R) < 0) or (signed(A) < 0 and signed(B) >= 0 and signed(R) >= 0)) else '0';

with op select 
    V <= va when ALU_ADD,
	     vs when ALU_SUB,
	     '0' when others;



end rtl;
