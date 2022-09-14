/*

This Entity is the FFT Controller, that manages the configuration of the FFT QIP and data sending.
The data transmition will be under the Avalon-ST interface.

Generics:

- FFT_In_Data_Width		 	 : The FFT real and imaginery input width (16).		  
- FFT_Transform_Width	 	 : The fft transform size (9).
- FFT_Max_Transform_Width	 : The fft maximum transform width, Log2(MaxTransformSize).
- FFT_inverse			     : Determines the direction of the transform. '0' -> FFT, '1' -> IFFT.
- imag_data              	 : Imaginery data of the FFT input, set to all '0'.

Inputs:

- csi_sink_clk          	 : System clock (96 MHz).
- rsi_sink_reset_n      	 : Active-low asynchronous.
- asi_sink_FFT_ready    	 : Asserted when the FFT can accept data, connected to FFT source_ready.
- asi_sink_Multiplier_ready  : Asserted when the data and window multiplier is ready to send data to the controller.
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

Entity FFT_Controller_Modified is

	Generic(FFT_In_Data_Width       	  : integer   := 16;
			FFT_Transform_Width     	  : integer   := 14;
			FFT_Max_Transform_Width 	  : integer   := 14;
			FFT_inverse			    	  : std_Logic := '0';
			imag_data               	  : std_logic_vector := "0000000000000000");
	
	Port( csi_sink_clk     				  : in std_logic;
		  rsi_sink_reset_n 				  : in std_logic;
		  asi_sink_FFT_ready    		  : in std_logic;
		  asi_sink_windowed_data		  : in std_logic_vector((FFT_In_Data_Width - 1) downto 0);

		  asi_sink_sop, asi_sink_eop, asi_sink_valid : in std_logic;

		  in_amps : in std_logic_vector(2 downto 0);
		  in_filters : in std_logic_vector(1 downto 0);
		  in_attenuator : in std_logic_vector(5 downto 0);
		  in_protection : in std_logic;
		  in_error : in std_logic;
		  		  
		  aso_source_sop        		  : out std_logic;
		  aso_source_eop      		  : out std_logic;
		  aso_source_valid        		  : out std_logic;
		  aso_source_data_to_FFT		  : out std_logic_vector((FFT_In_Data_Width * 2) + FFT_Transform_Width + 1 downto 0);
		  
		  out_amps : out std_logic_vector(2 downto 0);
		  out_filters : out std_logic_vector(1 downto 0);
		  out_attenuator : out std_logic_vector(5 downto 0);
		  out_protection : out std_logic;
		  out_error : out std_logic;
		  
		  fft_reset : out std_logic
			
		  );
		  
End Entity;

Architecture Arch_FFT_Controller_Modified of FFT_Controller_Modified is

Begin

	Process(rsi_sink_reset_n, csi_sink_clk)
	Begin
		
		if (rsi_sink_reset_n = '0') then
		
			aso_source_valid <= '0';
			aso_source_sop <= '0';
			aso_source_eop <= '0';
			aso_source_data_to_FFT <= (others => '0');
			out_amps <= "000";
			out_attenuator <= "000000";
			out_filters <= "00";
			fft_reset <= '0';
			
		elsif (rising_edge(csi_sink_clk)) then

			out_error <= in_error;
			out_protection <= in_protection;
			
			fft_reset <= '1';

			if (asi_sink_FFT_ready = '1') then
				aso_source_valid <= asi_sink_valid;
				aso_source_sop <= asi_sink_sop;
				aso_source_eop <= asi_sink_eop;
				aso_source_data_to_FFT <= asi_sink_windowed_data & imag_data & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width  + 1)) & fft_inverse; -- data assertion.
			end if;

			if (asi_sink_sop = '1') then -- Data That Passes Through All System Components
				out_amps <= in_amps;
				out_attenuator <= in_attenuator;
				out_filters <= in_filters; 
			end if;

		end if;
	End Process;

End Arch_FFT_Controller_Modified;

	