--12/3/20
--this entity is the intel fft ip core data source.
--the fft data source is an avalon-st interface source,transmiting the data for the fft/Ifft.
-----------------------------------------------------------------
--entity pin discription :
--	inputs 	:
--	i_clk				  - input clock signal.
-- i_reset			  - input Asynchrounous reset signal, active High.
--	i_ready			  - input fft sink ready to transform signal,Active high.
-- i_error			  - input avalon st interface error signal,when error is recieved the fft sink must be reset,"00"-no error,"01"-missing start of packet (sop),"10"-missing end of packet (EOP),"11"-unexpected EOP.
--	i_start			  - input start transforming data,active high.
--	i_realData		  - input real data for the transformation.
--	i_complexData	  - input complex data for the transformation.

--	outputs	:
--	o_valid			  - output data to transform ready.
--	o_data			  - output data ,26-19 :Real data ,18-11:Complex data,10-1:fft pts (transform size),0:inverse(determines direction of the transform,o_inverse='1' =>IFFT,o_inverse='0' =>FFT).
--	o_sop				  - output start of packet signal.
--	o_eop				  - output end of packet signal.
--	o_fftReset		  - output reset for the fft when there is an error on the avalon-st interface,active low.
--	o_RomAddress	  - output Rom address(temporary for test bench ).
-----------------------------------------------------------------
--entity generics discription :
--	FFT_InDataWidth		 - input real and image data Width.		  
--	FFT_TransformSize	  	 -	the fft transform size .
--	FFT_MaxTransformWidth  - the fft maximum transform width.--log2(MaxTransformSize),for example log2(1024)=10;;
--	FFT_inverse			    -	determines direction of the transform,o_inverse='1' =>IFFT,o_inverse='0' =>FFT.
-----------------------------------------------------------------
--FSM moore state discription	:
-- reset 	 - reset state .
--	idle		 - idle state ,waiting for the start signal .
-- error 	 - error state,a state for handling an error recieved from the FFT core.
--	sop		 -	start of packet state,begining to transform.
--	packetFFT -	the packet FFT state,the transformation takes place.
-- eop		 - end of packet state.
-----------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
entity fft_dataSource is
generic(FFT_InDataWidth		  :integer:=10;
		  FFT_TransformSize	  :integer:=512;
		  FFT_MaxTransformWidth:integer:=9;
		  FFT_inverse			  :std_Logic:='0');
		   
port(i_clk,i_reset,i_ready,i_start	:in  std_logic;
	  i_realData							:in  signed(FFT_InDataWidth -1 downto 0);
	  i_imageData							:in  signed(FFT_InDataWidth-1 downto 0);
	  i_error								:in  std_logic_vector(1 downto 0);
	  o_valid,o_sop,o_eop,o_fftReset	:out std_logic;
	  o_data									:out signed((2*FFT_InDataWidth+FFT_MaxTransformWidth+1) downto 0));
end entity;

architecture arch_fft_dataSource	of fft_dataSource is 
type fftStateType	is (reset,error,idle,sop,packetFFT,eop);
signal fftState	:fftStateType;
signal symbolsCounter					: integer range 0 to FFT_TransformSize-1;
signal delayCounter						: integer range 0 to 1;
begin 
--	FFT FSM moore process :
	process(i_reset,i_clk)
	begin
		if i_reset ='0' then 
			fftState<=reset;	
			symbolsCounter<=FFT_TransformSize-1;
			delayCounter<=0;
		elsif rising_edge(i_clk) then
			case fftState is 
			when reset		=> fftState<=idle;
			
			when idle 		=> if i_start='1' then 
										fftState<=sop;
									end if;
							  
			when sop			=>	if i_ready ='1' and delayCounter=0 then 
										delayCounter<=delayCounter+1;
									elsif i_ready='1' and delayCounter=1 then 
										fftState<=packetFFT;
										symbolsCounter<=symbolsCounter-1;
										delayCounter<=0;
									end if;
							  
			when packetFFT	=> if symbolsCounter=1  then
										fftState<=eop;
										symbolsCounter<=symbolsCounter-1;
									else
										symbolsCounter<=symbolsCounter-1;
									end if;		
			when eop			=>fftState<=idle;
								  symbolsCounter<=FFT_TransformSize-1;
			
			when error 		=>fftState<=idle;
								  symbolsCounter<=FFT_TransformSize-1;
			
			end case;
			
			if i_error /= "00" then 
				fftState<=error;
			end if;
		end if;
	end process;
--	FFT signal Assignments :	
o_fftReset	<=	'0' 				when fftState=reset						 else
					'0'				when fftState=error 						 else
					'1';
					
o_sop			<=	'1'				when fftState=sop							 else
					'1'				when fftState=idle and i_start='1'	 else
					'0';
					
o_eop			<=	'1'				when fftState=eop							 else
					'0';
					

o_valid		<=	'0'				when fftState=reset 						 else
					'0'				when fftState=error						 else
					'0'				when fftState=idle						 else
					'0'				when fftState=sop and delayCounter=0 else
					'1'; 

o_data(0)			  <=FFT_inverse;					
o_data(FFT_MaxTransformWidth+1 downto 1) <=to_signed(FFT_TransformSize,FFT_MaxTransformWidth+1);
o_data((FFT_MaxTransformWidth+2+(FFT_InDataWidth-1)) downto FFT_MaxTransformWidth+2)<=i_imageData;
o_data((2*FFT_InDataWidth+FFT_MaxTransformWidth+1) downto (FFT_MaxTransformWidth+2+FFT_InDataWidth))<=i_RealData;		 					
end architecture;