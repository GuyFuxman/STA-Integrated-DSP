Library IEEE;
USE IEEE.Std_logic_1164.all;
use ieee.numeric_std.all;

Entity Multiple_Delay_DFF is 

	Generic(FFT_In_Data_Width       : integer   			:= 16;
			  FFT_Transform_Width     : integer   			:= 9;
			  FFT_Max_Transform_Width : integer   			:= 9;
			  FFT_inverse			     : std_Logic 			:= '0';
			  imag_data               : std_logic_vector := "0000000000000000";
			  fcw                     : std_logic_vector := "0000010000000000";
			  Cordic_Latency          : integer  			:= 9);


   port(
         
      i_Clk : in  std_logic;   
      i_Din 	: in  std_logic_vector ((FFT_In_Data_Width - 1) downto 0);
		o_Qout   : out std_logic_vector ((FFT_In_Data_Width - 1) downto 0)    
   );
end Entity;

Architecture Arch_Multiple_Delay_DFF of Multiple_Delay_DFF is 
	component Delay_FFT
		Port (
			i_Clk : in  std_logic;   
			i_D 	: in  std_logic_vector ((FFT_In_Data_Width - 1) downto 0);
			o_Q   : out std_logic_vector ((FFT_In_Data_Width - 1) downto 0)    
		);
	end component;

begin
  
	Gen_Delay_FFT:
	for I in 0 to (Cordic_Latency - 1) generate 	
		
	Delay_FFT_LSB: if (I = 0) generate
		UFirst : Delay_FFT port map (i_clk,i_Din,o_Q(0));
	end generate Delay_FFT_LSB;
	
	Delay_FFT_MSB: if (I = Cordic_Latency - 1) generate
		ULast : Delay_FFT port map (i_clk,o_Q(I-1),o_Qout);
	end generate Delay_FFT_MSB;
	 
	Delay_FFT_X:   if (I > 0 and I < (Cordic_Latency - 1)) generate
		 URest  : Delay_FFT port map (i_clk,o_Q(I-1),o_Q(I));
	end generate Delay_FFT_X;	
		
	end generate Gen_Delay_FFT;

 
end Arch_Multiple_Delay_DFF; 