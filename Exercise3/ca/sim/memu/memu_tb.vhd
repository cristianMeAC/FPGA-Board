library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;

use work.memu;



entity tb is
end entity;


architecture beh of tb is

	constant WT : time := 20 ns;

	signal op   : mem_op_type;
	signal A    : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal W    : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal D    : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal M    : mem_out_type;
	signal R    : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal XL   : std_logic;
	signal XS   : std_logic;
begin


inst : entity work.memu 
port map(op => op, A => A, W => W, D => D, M => M, R => R, XL => XL, XS => XS);


testp : process
begin

	op.memread <= '0';
	op.memwrite <= '0';
	W <= x"FEDCBA98";
	D <= x"87654321";
	
	---------------------------
	-- general test
	---------------------------
	
	-- MEM_B
	op.memtype <= MEM_B;
	A <= (0 => '0', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '0', 1 => '1', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '1', others => '1');
	
	wait for WT;
	
	-- MEM_BU
	A <= (0 => '0', 1 => '0', others => '1');
	op.memtype <= MEM_BU;
	
	wait for WT;
	A <= (0 => '1', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '0', 1 => '1', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '1', others => '1');
	
	wait for WT;
	
	-- MEM_H
	op.memtype <= MEM_H;
	A <= (0 => '0', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '0', 1 => '1', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '1', others => '1');
	
	wait for WT;
	
	-- MEM_HU
	op.memtype <= MEM_HU;
	A <= (0 => '0', 1 => '0', others => '1');

	wait for WT;
	A <= (0 => '1', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '0', 1 => '1', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '1', others => '1');
	
	wait for WT;
	
	-- MEM_W
	op.memtype <= MEM_W;
	A <= (0 => '0', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '0', others => '1');
	
	wait for WT;
	A <= (0 => '0', 1 => '1', others => '1');
	
	wait for WT;
	A <= (0 => '1', 1 => '1', others => '1');
	
	wait for WT;
	
	wait for WT*10;

	---------------------------
	-- XL test
	---------------------------
	
	
	-- XL = 0
	A <= (others => '0');
	-- memread is '0'
	op.memread <= '0';
	op.memtype <= MEM_B;
	
	wait for WT;
	op.memtype <= MEM_BU;
	wait for WT;
	op.memtype <= MEM_H;
	wait for WT;
	op.memtype <= MEM_HU;
	wait for WT;
	op.memtype <= MEM_W;
	wait for WT;
	
	-- memread is '1'
	op.memread <= '1';
	-- test different A's - for A(1 downto 0) = "00"
	op.memtype <= MEM_B;
	A <= (2 => '1', others => '0');
	
	wait for WT;
	A(2) <= '0';
	A(5) <= '1';
	op.memtype <= MEM_BU;
	
	wait for WT;
	A(5) <= '0';
	A(3) <= '1';
	op.memtype <= MEM_H;
	
	wait for WT;
	A(3) <= '0';
	A(ADDR_WIDTH-1) <= '1';
	op.memtype <= MEM_HU;
	
	wait for WT;
	A(ADDR_WIDTH-1) <= '0';
	A(ADDR_WIDTH-2) <= '1';
	op.memtype <= MEM_W;
	
	wait for WT;
	-- test MEM_B checks (last A "00" was already tested by different A's above)
	op.memtype <= MEM_B;
	
	A <= (0 => '1', others => '0');
	wait for WT;
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_BU checks
	op.memtype <= MEM_BU;
	
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_H checks
	op.memtype <= MEM_H;
	
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_HU checks
	op.memtype <= MEM_HU;
	
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	
	-- no checks for MEM_W, "00" checked with A "00"s, others produce 1 by XL
	
	wait for WT*10;
	
	
	-- XL = 1
	op.memread <= '1'; -- was already '1'
	
	-- Address is 0
	A <= (others => '0');
	op.memtype <= MEM_B;
	
	wait for WT;
	op.memtype <= MEM_BU;
	wait for WT;
	op.memtype <= MEM_H;
	wait for WT;
	op.memtype <= MEM_HU;
	wait for WT;
	op.memtype <= MEM_W;
	wait for WT;
	
	-- test MEM_H checks (MEM_B and MEM_BU only give XL=1 by 
	-- address 0 which was checked above)
	
	op.memtype <= MEM_H;
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_HU checks
	op.memtype <= MEM_HU;
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_W checks
	op.memtype <= MEM_W;
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	---------------------------
	-- end of XL check
	---------------------------
	
	wait for WT*10;
	
	---------------------------
	-- XS check
	---------------------------
	
	-- XS = 0
	
	-- memwrite is '0'
	op.memwrite <= '0';
	A <= (others => '0');
	
	op.memtype <= MEM_B;
	wait for WT;
	op.memtype <= MEM_BU;
	wait for WT;
	op.memtype <= MEM_H;
	wait for WT;
	op.memtype <= MEM_HU;
	wait for WT;
	op.memtype <= MEM_W;
	wait for WT;
	
	-- memwrite is '1'
	op.memwrite <= '1';
	
	A <= (ADDR_WIDTH-1 => '1', others => '0');
	op.memtype <= MEM_B;
	wait for WT;
	A(ADDR_WIDTH-1) <= '0';
	A(ADDR_WIDTH-2) <= '1';
	op.memtype <= MEM_BU;
	wait for WT;
	A(ADDR_WIDTH-2) <= '0';
	A(3) <= '1';
	op.memtype <= MEM_H;
	wait for WT;
	A(3) <= '0';
	A(5) <= '1';
	op.memtype <= MEM_HU;
	wait for WT;
	A(5) <= '0';
	A(8) <= '1';
	op.memtype <= MEM_W;
	wait for WT;
	
	-- following is copy pasted from XL check
	-- test MEM_B checks (last A "00" was already tested by different A's above)
	op.memtype <= MEM_B;
	
	A <= (0 => '1', others => '0');
	wait for WT;
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_BU checks
	op.memtype <= MEM_BU;
	
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_H checks
	op.memtype <= MEM_H;
	
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_HU checks
	op.memtype <= MEM_HU;
	
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	
	-- no checks for MEM_W, "00" checked with A "00"s, others produce 1 by XL
	
	wait for WT*10;
	-- copy paste end
	
	
	-- XS = '1'
	op.memwrite <= '1';
	
	-- the following is copy-pasted from XL check
		
	-- Address is 0
	A <= (others => '0');
	op.memtype <= MEM_B;
	
	wait for WT;
	op.memtype <= MEM_BU;
	wait for WT;
	op.memtype <= MEM_H;
	wait for WT;
	op.memtype <= MEM_HU;
	wait for WT;
	op.memtype <= MEM_W;
	wait for WT;
	
	-- test MEM_H checks (MEM_B and MEM_BU only give XL=1 by 
	-- address 0 which was checked above)
	
	op.memtype <= MEM_H;
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_HU checks
	op.memtype <= MEM_HU;
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- test MEM_W checks
	op.memtype <= MEM_W;
	A(0) <= '1';
	A(1) <= '0';
	wait for WT;
	A(0) <= '0';
	A(1) <= '1';
	wait for WT;
	A(0) <= '1';
	A(1) <= '1';
	wait for WT;
	
	-- end of copy-paste
	wait for WT*10;
	
	---------------------------
	-- end of XS check
	---------------------------
	
	wait;
	

end process;



end architecture;
