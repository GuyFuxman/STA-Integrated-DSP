/*

This Entity is the Delay_DFF, that adds latency to the bit-reversed counter, the latency will correspond to the CORDIC_Latency.

Generics:

- CORDIC_Latency : the needed amount of latency.
- FFT_In_Data_Width		 	 : The FFT real and imaginery input width (16).		  
- FFT_Transform_Width	 	 : The fft transform size (9).
- FFT_Max_Transform_Width	 : The fft maximum transform width, Log2(MaxTransformSize).

Inputs:

- csi_sink_clk   	 : System clock (96 MHz).
- rsi_sink_reset_n : Active-low asynchronous.
- asi_sink_D    	 : The bit-reversed counter input.

Outputs:

- aso_source_Q       	 : Latenced bit-reversed output.

FFT Calculation:

- System Clock * NCO Input / NCO Size = Desired FFT Result.
- System Clock / FFT Size = FFT Resolution.
- FFT Bit-Reversed Result * FFT Resolution = Actual FFT Result.							      

*/


Library IEEE;
USE IEEE.Std_logic_1164.all;
use ieee.numeric_std.all;

Entity Delay_DFF is 

	Generic(CORDIC_Latency          : integer   := 9;
			 FFT_In_Data_Width        : integer   := 16;
			  FFT_Transform_Width     : integer   := 9;
			  FFT_Max_Transform_Width : integer   := 9);
			  
   port(
         
      csi_sink_clk,rsi_sink_reset_n : in  std_logic;   
      asi_sink_D 	: in  std_logic_vector ((FFT_Transform_Width - 1) downto 0);
		aso_source_Q   : out std_logic_vector ((FFT_Transform_Width - 1) downto 0)    
   );
end Entity;

Architecture Arch_Delay_DFF of Delay_DFF is 

signal s_Latency_Counter : integer range 0 to (CORDIC_Latency - 1);

type t_Latency_Array is array ((CORDIC_Latency - 1) downto 0) of std_logic_vector((FFT_Transform_Width - 1) downto 0);
signal s_Latency_Array : t_Latency_Array;

begin  

aso_source_Q <= s_Latency_Array(CORDIC_Latency - 2);

 process(csi_sink_clk,rsi_sink_reset_n)
 begin 
 
    if (rsi_sink_reset_n = '0') then
		
		s_Latency_Counter <= 0;
	 
	 elsif(rising_edge(csi_sink_clk)) then
	 
		if (s_Latency_Counter < (CORDIC_Latency - 1)) then
		
			s_Latency_Counter <= s_Latency_Counter + 1;
		
		end if;
		
		s_Latency_Array(0) <= asi_sink_D;
		
		s_Latency_Array((CORDIC_Latency - 1) downto 1) <= s_Latency_Array((CORDIC_Latency - 2) downto 0);
				
    end if; 
	 
 end process;
 
end Arch_Delay_DFF; 