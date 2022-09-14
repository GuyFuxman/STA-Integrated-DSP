/*

This Entity is the FFT Controller, that manages the configuration of the FFT QIP and data sending.
The data transmition will be under the Avalon-ST interface.

Generics:

- FFT_In_Data_Width		 	 : The FFT real and imaginery input width (16).		  
- FFT_Transform_Width	 	 : The fft transform size (9).
- FFT_Max_Transform_Width	 : The fft maximum transform width, Log2(MaxTransformSize).
- FFT_inverse			    	 : Determines the direction of the transform. '0' -> FFT, '1' -> IFFT.
- imag_data              	 : Imaginery data of the FFT input, set to all '0'.

Inputs:

- csi_sink_clk          	 : System clock (96 MHz).
- rsi_sink_reset_n      	 : Active-low asynchronous.
- asi_sink_FFT_ready    	 : Asserted when the FFT can accept data, connected to FFT source_ready.
- asi_sink_Multiplier_ready : Asserted when the data and window multiplier is ready to send data to the controller.
- asi_sink_windowed_data 	 : The windowed multiplied and divided data, connected to the output of the multiplier.

Outputs:

- aso_source_valid       	 : Asserted when data bus is valid, connected to FFT sink_valid.
- aso_source_sop         	 : Asserted for one clock when data starts, with the first data of the packet, connected to FFT sink_sop.
- aso_source_eop         	 : Asserted for one clock when data ends, with the last data of the packet, connected to FFT sink_eop.
- aso_source_error       	 : No use, set to "00", connected to FFT sink_error.
- aso_source_data_to_FFT 	 : The windowed multiplied and divided data, connected to FFT sink_data.
							         The bus will include the real data (sink_real), imaginery data (sink_imag), fftpts_in (Log2(maxmimum FFT length)) 
										and inverse bit.
- aso_source_FFT_reset      : The output will reset to FFT in case of system reset or packet error.

State Machine States:

- Idle : Waiting for a ready signal from the FFT.
- Sop  : Start of Packet signal.
- Data : Data transmition to the FFT.
- Eop  : End of Packet.

*/

Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity FFT_Controller is

	Generic(FFT_In_Data_Width       : integer   := 16;
			FFT_Transform_Width     : integer   := 9;
			FFT_Max_Transform_Width : integer   := 9;
			FFT_inverse			     : std_Logic := '0';
			imag_data               : std_logic_vector := "0000000000000000");
	
	Port(csi_sink_clk     				  : in std_logic;
		  rsi_sink_reset_n 				  : in std_logic;
		  asi_sink_FFT_ready    		  : in std_logic;
		  asi_sink_Multiplier_ready     : in std_logic;
		  asi_sink_windowed_data		  : in std_logic_vector((FFT_In_Data_Width - 1) downto 0);
		  		  
		  aso_source_sop        		  : out std_logic;
		  aso_source_valid      		  : out std_logic;
		  aso_source_eop        		  : out std_logic;
--		  aso_source_error      		  : out std_logic_vector(1 downto 0);
		  aso_source_data_to_FFT		  : out std_logic_vector((FFT_In_Data_Width * 2) + FFT_Transform_Width + 1 downto 0);
		  aso_source_FFT_reset          : out std_logic; 
		
		  -- Debug Outputs
		  o_counter : out std_logic_vector (FFT_Max_Transform_Width downto 0)
		  --		
		  );
		  
End Entity;

Architecture Arch_FFT_Controller of FFT_Controller is

Signal s_counter : integer range 0 to 2**FFT_Max_Transform_Width;

Begin

--	aso_source_error <= "00";
	
	-- Debug Outputs
	o_counter <= std_logic_vector(to_unsigned(s_counter, FFT_Transform_Width + 1));
	--

	Process(rsi_sink_reset_n, csi_sink_clk)
	Begin
		
		if (rsi_sink_reset_n = '0') then
		
			aso_source_valid <= '0';
			aso_source_sop <= '0';
			aso_source_eop <= '0';
			aso_source_data_to_FFT <= (others => '0');
			s_counter <= (2**(FFT_Max_Transform_Width) - 1);
			aso_source_FFT_reset <= '0';
			
		elsif (rising_edge(csi_sink_clk)) then
		
			aso_source_FFT_reset <= '1';
			
			if (asi_sink_FFT_ready = '0') then
			
				s_counter <= (2**(FFT_Max_Transform_Width) - 1);
				
			elsif (asi_sink_FFT_ready = '1' and asi_sink_Multiplier_ready = '1') then	

				case s_counter is

					when 0 to (2**(FFT_Max_Transform_Width) - 3) => aso_source_sop <= '0';
																					aso_source_eop <= '0';					 
																					aso_source_data_to_FFT <= asi_sink_windowed_data & imag_data & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= s_counter + 1;
																					
					when (2**(FFT_Max_Transform_Width) - 2) => 		aso_source_sop <= '0';
																					aso_source_eop <= '1';					 
																					aso_source_data_to_FFT <= asi_sink_windowed_data & imag_data & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width  + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= s_counter + 1;
																					
					when (2**(FFT_Max_Transform_Width) - 1) =>  		aso_source_sop <= '1';
																					aso_source_eop <= '0';					 
																					aso_source_data_to_FFT <= asi_sink_windowed_data & imag_data & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width  + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= 0;
																					
					when others =>
					
				end case;
				
			end if;	
			
		end if;
	End Process;

End Arch_FFT_Controller;

	