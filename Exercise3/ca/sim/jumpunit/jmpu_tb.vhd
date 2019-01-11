library ieee;
use ieee.std_logic_1164.all;

use work.core_pack.all;
use work.op_pack.all;

entity jmpu_tb is
end entity;

architecture beh of jmpu_tb is

   signal TB_op   : jmp_op_type; 
   signal TB_N    : std_logic;   
   signal TB_Z    : std_logic;   
   signal TB_J    : std_logic;   

    component jmpu is
    
        port(
        	op   : in  jmp_op_type;  -- operation
            N    : in  std_logic;    -- negative flag 
            Z    : in  std_logic;    -- zero flag
            J    : out std_logic     -- jump
        );
    
    end component;
    
    -- Signals that we need for the TB
    --signal address1, address2  : std_logic_vector(ADDR_WIDTH-1 downto 0) <= (1 & x"070a");

begin 


    -----------------------------------------------
	--                jmpu instance              --
	-----------------------------------------------
    
    jmpu_instance : jmpu
        port map(
            op   => TB_op,
            N    => TB_N,
            Z    => TB_Z,
            J    => TB_J
        
        );
        
        
  
    testbench : process
    begin 
    
        TB_op <= JMP_NOP;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_NOP;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_NOP;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_NOP;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   1st Operation Ended --
        -----------------------------
        
        TB_op <= JMP_JMP;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_JMP;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_JMP;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_JMP;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   2nd Ended --
        -----------------------------
        
        TB_op <= JMP_BEQ;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_BEQ;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BEQ;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BEQ;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   3rd Ended --
        -----------------------------
        
        TB_op <= JMP_BNE;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_BNE;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BNE;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BNE;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   4th Ended --
        -----------------------------
        
        TB_op <= JMP_BLEZ;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_BLEZ;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BLEZ;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BLEZ;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   5th Ended --
        -----------------------------
        
        TB_op <= JMP_BGTZ;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
           
        TB_op <= JMP_BGTZ;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
           
        TB_op <= JMP_BGTZ;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
           
        TB_op <= JMP_BGTZ;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   6th Ended --
        -----------------------------
        
        TB_op <= JMP_BLTZ;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_BLTZ;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BLTZ;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BLTZ;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   7th Ended --
        -----------------------------
        

        TB_op <= JMP_BGEZ;
        TB_N <= '0';
        TB_Z <= '1';
        wait for 3 us;
        
        TB_op <= JMP_BGEZ;
        TB_N <= '1';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BGEZ;
        TB_N <= '0';
        TB_Z <= '0';
        wait for 3 us;
        
        TB_op <= JMP_BGEZ;
        TB_N <= '1';
        TB_Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   Finish --
        -----------------------------
       
        wait;

    end process;


end architecture;