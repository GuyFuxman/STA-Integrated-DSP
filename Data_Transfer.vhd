Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity Data_Transfer is

    Generic(FFT_In_Data_Width       : integer   := 16;
            FFT_Transform_Width     : integer   := 14;
            FFT_Max_Transform_Width : integer   := 14);
	
	Port( csi_sink_clk     				  : in std_logic;
		  rsi_sink_reset_n 				  : in std_logic;

		  asi_sink_Controller_sop, asi_sink_Controller_eop, asi_sink_Controller_valid : in std_logic;
          asi_sink_FFT_sop, asi_sink_FFT_eop, asi_sink_FFT_valid : in std_logic;

          asi_sink_FFT_data		  		  : in std_logic_vector((FFT_In_Data_Width * 2) + FFT_Transform_Width downto 0);

		  in_amps : in std_logic_vector(2 downto 0);
		  in_filters : in std_logic_vector(1 downto 0);
		  in_attenuator : in std_logic_vector(5 downto 0);
		  in_protection : in std_logic;
		  in_error : in std_logic;
		  		  
		  aso_source_sop        		  : out std_logic;
		  aso_source_eop     		      : out std_logic;
		  aso_source_valid        		  : out std_logic;

          aso_source_FFT_data		  		  : out std_logic_vector((FFT_In_Data_Width * 2) + FFT_Transform_Width downto 0);
		  
		  out_amps : out std_logic_vector(2 downto 0);
		  out_filters : out std_logic_vector(1 downto 0);
		  out_attenuator : out std_logic_vector(5 downto 0);
		  out_protection : out std_logic;
		  out_error : out std_logic
			
		  );
		  
End Entity;

Architecture Arch_Data_Transfer of Data_Transfer is

    Signal s_amps0,s_amps1              : std_logic_vector(2 downto 0);
    Signal s_filters0,s_filters1        : std_logic_vector(1 downto 0);
    Signal s_attenuator0,s_attenuator1 : std_logic_vector(5 downto 0);

    Signal s_switch : std_Logic;

Begin

	Process(rsi_sink_reset_n, csi_sink_clk)
	Begin
		
		if (rsi_sink_reset_n = '0') then
		
			aso_source_valid <= '0';
			aso_source_sop <= '0';
			aso_source_eop <= '0';
			out_amps <= "000";
			out_attenuator <= "000000";
			out_filters <= "00";
           s_switch <= '0';
			
		elsif (rising_edge(csi_sink_clk)) then

			out_error <= in_error;
			out_protection <= in_protection;
            aso_source_FFT_data <= asi_sink_FFT_data;
            aso_source_sop <= asi_sink_FFT_sop;
            aso_source_eop <= asi_sink_FFT_eop;
            aso_source_valid <= asi_sink_FFT_valid;

			if (asi_sink_Controller_sop = '1') then -- Data That Passes Through All System Components
                case s_switch is -- Decides which signal will be written to, every sop changes
				    when '0' => s_amps0 <= in_amps;
				                s_attenuator0 <= in_attenuator;
				                s_filters0 <= in_filters;
                                s_switch <= '1';
                    when '1' => s_amps1 <= in_amps;
				                s_attenuator1 <= in_attenuator;
				                s_filters1 <= in_filters;
                                s_switch <= '0';
                    when others =>
                end case; 
			end if;

            if (asi_sink_FFT_sop = '1') then -- Data That Passes Through All System Components
                case s_switch is -- Decides which signal will be outputed to
                    when '0' => out_amps <= s_amps1;
				                out_attenuator <= s_attenuator1;
				                out_filters <= s_filters1;
                    when '1' => out_amps <= s_amps0;
				                out_attenuator <= s_attenuator0;
				                out_filters <= s_filters0;
                    when others =>
                end case;
			end if;

		end if;
	End Process;

End Arch_Data_Transfer;
