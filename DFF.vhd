Library IEEE;
USE IEEE.Std_logic_1164.all;

Entity DFF is 
   port(
         
      i_Clk : in  std_logic;   
      i_D 	: in  std_logic;
		o_Q   : out std_logic    
   );
end Entity;

Architecture Arch_DFF of DFF is  
begin  

 process(i_Clk)
 begin 
 
    if(rising_edge(i_Clk)) then
	 
		o_Q <= i_D; 
		
    end if; 
	 
 end process;
 
end Arch_DFF; 