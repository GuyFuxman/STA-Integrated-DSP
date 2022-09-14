Library IEEE;
USE IEEE.Std_logic_1164.all;
use ieee.numeric_std.all;

Entity IFFT_Data_Sender is 

	Generic(FFT_In_Data_Width       : integer   := 16;
			  FFT_Transform_Width     : integer   := 9;
			  FFT_Max_Transform_Width : integer   := 9;
			  FFT_inverse			     : std_Logic := '1';
			  imag_data               : std_logic_vector := "0000000000000000";
			  real_data               : std_logic_vector := "0000000000000000";
			  zeros                   : std_logic_vector := "0000000000000000";
			  sending_point           : integer  := 128);

   Port(csi_sink_clk     	        : in std_logic;
		  rsi_sink_reset_n 	        : in std_logic;
		  asi_sink_FFT_ready         : in std_logic;
		  asi_sink_windowed_data	  : in std_logic_vector((FFT_In_Data_Width - 1) downto 0);
		
		  aso_source_sop        	  : out std_logic;
		  aso_source_valid           : out std_logic;
		  aso_source_eop        	  : out std_logic;
		  aso_source_data_to_FFT	  : out std_logic_vector((FFT_In_Data_Width * 2) + FFT_Transform_Width + 1 downto 0);
		  aso_source_FFT_reset       : out std_logic; 
		
		  -- Debug Outputs
		  o_counter : out std_logic_vector (FFT_Max_Transform_Width downto 0));
		  
end Entity;

Architecture Arch_IFFT_Data_Sender of IFFT_Data_Sender is 

Signal s_counter : integer range 0 to 2**FFT_Max_Transform_Width;

Begin

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
				
			elsif (asi_sink_FFT_ready = '1') then	

				case s_counter is

					when 0 to (2**(FFT_Max_Transform_Width) - sending_point) => aso_source_sop <= '0';
																					aso_source_eop <= '0';					 
																					aso_source_data_to_FFT <= zeros & zeros & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= s_counter + 1;
					when (2**(FFT_Max_Transform_Width) - (sending_point - 2)) to (2**(FFT_Max_Transform_Width) - 3) => aso_source_sop <= '0';
																					aso_source_eop <= '0';					 
																					aso_source_data_to_FFT <= zeros & zeros & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= s_counter + 1;																
					when (2**(FFT_Max_Transform_Width) - (sending_point - 1)) =>    aso_source_sop <= '0';
																					aso_source_eop <= '0';					 
																					aso_source_data_to_FFT <= real_data & imag_data & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= s_counter + 1;																
																					
					when (2**(FFT_Max_Transform_Width) - 2) => 		aso_source_sop <= '0';
																					aso_source_eop <= '1';					 
																					aso_source_data_to_FFT <= zeros & zeros & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width  + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= s_counter + 1;
																					
					when (2**(FFT_Max_Transform_Width) - 1) =>  		aso_source_sop <= '1';
																					aso_source_eop <= '0';					 
																					aso_source_data_to_FFT <= zeros & imag_data & std_logic_vector(to_unsigned((2**(FFT_Max_Transform_Width)), FFT_Max_Transform_Width  + 1)) & fft_inverse; -- data assertion.
																					aso_source_valid <= '1';
																					s_counter <= 0;
																					
					when others =>
					
				end case;
				
			end if;	
			
		end if;
	End Process;

end Arch_IFFT_Data_Sender; 