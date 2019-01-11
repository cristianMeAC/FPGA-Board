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
   signal TB_J    : std_logic     

    component jmpu is
    
        port(
        	op   : in  jmp_op_type;  -- operation
            N    : in  std_logic;    -- negative flag 
            Z    : in  std_logic;    -- zero flag
            J    : out std_logic     -- jump
        );
    
    end component;
    
    -- Signals that we need for the TB
    signal address1, address2  : std_logic_vector(ADDR_WIDTH-1 downto 0) <= (1 & x"070a");

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
    
        op <= JMP_NOP;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
        op <= JMP_NOP;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_NOP;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_NOP;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   1st Operation Ended --
        -----------------------------
        
        op <= JMP_JMP;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
         op <= JMP_JMP;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
         op <= JMP_JMP;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
         op <= JMP_JMP;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   2nd Ended --
        -----------------------------
        
        op <= JMP_BEQ;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
          op <= JMP_BEQ;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
          op <= JMP_BEQ;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
          op <= JMP_BEQ;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   3rd Ended --
        -----------------------------
        
        op <= JMP_BNE;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
        op <= JMP_BNE;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BNE;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BNE;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   4th Ended --
        -----------------------------
        
        op <= JMP_BLEZ;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
        op <= JMP_BLEZ;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BLEZ;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BLEZ;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   5th Ended --
        -----------------------------
        
        op <= JMP_BGTZ;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
           
        op <= JMP_BGTZ;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
           
        op <= JMP_BGTZ;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
           
        op <= JMP_BGTZ;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   6th Ended --
        -----------------------------
        
        op <= JMP_BLTZ;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
        op <= JMP_BLTZ;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BLTZ;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BLTZ;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   7th Ended --
        -----------------------------
        

        op <= JMP_BGEZ;
        N <= '0';
        Z <= '1';
        wait for 3 us;
        
        op <= JMP_BGEZ;
        N <= '1';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BGEZ;
        N <= '0';
        Z <= '0';
        wait for 3 us;
        
        op <= JMP_BGEZ;
        N <= '1';
        Z <= '1';
        wait for 3 us;
        
        -----------------------------
        --   Finish --
        -----------------------------
       
        wait;

    end process;


end erchitecture;