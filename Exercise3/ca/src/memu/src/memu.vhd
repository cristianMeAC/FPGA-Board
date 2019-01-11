library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

entity memu is
	port (
		op   : in  mem_op_type;
		A    : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
		W    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		D    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		M    : out mem_out_type;
		R    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		XL   : out std_logic;
		XS   : out std_logic);
end memu;

architecture rtl of memu is

  signal XL_buf : std_logic := '0';
  signal XS_buf : std_logic := '0';

begin  -- rtl



  M.byteena <=  "1000" when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "00") else -- MEM_B || MEM_BU
		"0100" when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "01") else
		"0010" when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "10") else
		"0001" when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "11") else
		"1100" when ((op.memtype = MEM_H or op.memtype = MEM_HU) and (A(1 downto 0) = "00" or A(1 downto 0) = "01")) else -- MEM_H || MEM_HU
		"0011" when ((op.memtype = MEM_H or op.memtype = MEM_HU) and (A(1 downto 0) = "10" or A(1 downto 0) = "11")) else
		"1111" when (op.memtype = MEM_W); -- MEM_W

  M.wrdata <=   (W(7 downto 0) & x"000000") when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "00") else -- MEM_B || MEM_BU
		(x"00" & W(7 downto 0) & x"0000") when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "01") else
		(x"0000" & W(7 downto 0) & x"00") when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "10") else
		(x"000000" & W(7 downto 0)) when ((op.memtype = MEM_B or op.memtype = MEM_BU) and A(1 downto 0) = "11") else
		(W(15 downto 0) & x"0000") when ((op.memtype = MEM_H or op.memtype = MEM_HU) and (A(1 downto 0) = "00" or A(1 downto 0) = "01")) else -- MEM_H || MEM_HU
		(x"0000" & W(15 downto 0)) when ((op.memtype = MEM_H or op.memtype = MEM_HU) and (A(1 downto 0) = "10" or A(1 downto 0) = "11")) else
		W(31 downto 0) when (op.memtype = MEM_W); -- MEM_W


  R <= 		std_logic_vector(shift_right(signed(D(31 downto 24) & x"000000"), 24)) when (op.memtype = MEM_B and A(1 downto 0) = "00") else -- MEM_B
		std_logic_vector(shift_right(signed(D(23 downto 16) & x"000000"), 24)) when (op.memtype = MEM_B and A(1 downto 0) = "01") else
		std_logic_vector(shift_right(signed(D(15 downto 8) & x"000000"), 24)) when (op.memtype = MEM_B and A(1 downto 0) = "10") else
		std_logic_vector(shift_right(signed(D(7 downto 0) & x"000000"), 24)) when (op.memtype = MEM_B and A(1 downto 0) = "11") else
		std_logic_vector(shift_right(unsigned(D(31 downto 24) & x"000000"), 24)) when (op.memtype = MEM_BU and A(1 downto 0) = "00") else -- MEM_BU
		std_logic_vector(shift_right(unsigned(D(23 downto 16) & x"000000"), 24)) when (op.memtype = MEM_BU and A(1 downto 0) = "01") else
		std_logic_vector(shift_right(unsigned(D(15 downto 8) & x"000000"), 24)) when (op.memtype = MEM_BU and A(1 downto 0) = "10") else
		std_logic_vector(shift_right(unsigned(D(7 downto 0) & x"000000"), 24)) when (op.memtype = MEM_BU and A(1 downto 0) = "11") else
		std_logic_vector(shift_right(signed(D(31 downto 16) & x"0000"), 24)) when (op.memtype = MEM_H and (A(1 downto 0) = "00" or A(1 downto 0) = "01")) else -- MEM_H
		std_logic_vector(shift_right(signed(D(15 downto 0) & x"0000"), 24)) when (op.memtype = MEM_H and (A(1 downto 0) = "10" or A(1 downto 0) = "11")) else
		std_logic_vector(shift_right(unsigned(D(31 downto 16) & x"0000"), 24)) when (op.memtype = MEM_HU and (A(1 downto 0) = "00" or A(1 downto 0) = "01")) else -- MEM_HU
		std_logic_vector(shift_right(unsigned(D(15 downto 0) & x"0000"), 24)) when (op.memtype = MEM_HU and (A(1 downto 0) = "10" or A(1 downto 0) = "11")) else
		D(31 downto 0) when (op.memtype = MEM_W);

	
  XL_buf <= 	'1' when (op.memread = '1' and A(1 downto 0) = "00" and A(ADDR_WIDTH-1 downto 2) = (0 to ADDR_WIDTH-3 => '0')) else 
		'1' when (op.memread = '1' and (op.memtype = MEM_H or op.memtype = MEM_HU) and (A(1 downto 0) = "01" or A(1 downto 0) = "11")) else 
		'1' when (op.memread = '1' and op.memtype = MEM_W and (A(1 downto 0) = "01" or A(1 downto 0) = "10" or A(1 downto 0) = "11")) else
		'0';

  XS_buf <= 	'1' when (op.memwrite = '1' and A(1 downto 0) = "00" and A(ADDR_WIDTH-1 downto 2) = (0 to ADDR_WIDTH-3 => '0')) else 
		'1' when (op.memwrite = '1' and (op.memtype = MEM_H or op.memtype = MEM_HU) and (A(1 downto 0) = "01" or A(1 downto 0) = "11")) else 
		'1' when (op.memwrite = '1' and op.memtype = MEM_W and (A(1 downto 0) = "01" or A(1 downto 0) = "10" or A(1 downto 0) = "11")) else
		'0';

  XS <= XS_buf;
  XL <= XL_buf;

  M.rd <=	op.memread when (XL_buf = '0' and XS_buf = '0') else
		'0';

  M.wr <= 	op.memwrite when (XL_buf = '0' and XS_buf = '0') else
		'0';

  M.address <= A;
  


end rtl;