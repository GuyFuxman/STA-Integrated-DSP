/* 
RON KRAKOVSKY
Convolution with hann function, window function.
*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------

entity Window_Multipication_Modified is
generic(
	samples : integer := 16384;
	width_input_data_bits : integer := 16; 
	width_memory_data : integer := 10 -- ufix10_En8
);
port(	
	csi_sink_clk	 	 : in std_logic; -- clock
	rsi_sink_reset	 	 : in std_logic; -- reset in LOW = '0'
	asi_sink_valid_data	 : in std_logic; -- valid for start convolution, start when fft need for data.(start of pucket)
	asi_sink_data		 : in std_logic_vector(width_input_data_bits - 1 downto 0); -- s10_En0 ,input data

	asi_sink_sop, asi_sink_eop, asi_sink_valid : in std_logic;

	in_amps : in std_logic_vector(2 downto 0);
	in_filters : in std_logic_vector(1 downto 0);
	in_attenuator : in std_logic_vector(5 downto 0);
	in_protection : in std_logic;
	in_error : in std_logic;

	aso_source_data		 : out std_logic_vector(width_input_data_bits - 1 downto 0); -- s10_En0 ,output data
	aso_source_sop, aso_source_eop, aso_source_valid : out std_logic;

	out_amps : out std_logic_vector(2 downto 0);
	out_filters : out std_logic_vector(1 downto 0);
	out_attenuator : out std_logic_vector(5 downto 0);
	out_protection : out std_logic;
	out_error : out std_logic;

	aso_Window_Multipication : out std_logic

);
end Window_Multipication_Modified;  

--------------------------------------------------

architecture arch_Window_Multipication_Modified of Window_Multipication_Modified is
type mem_t is array(0 to samples-1) of unsigned(width_memory_data-1 downto 0); -- ufix10_En8
signal ram : mem_t;
attribute ram_init_file : string;
attribute ram_init_file of ram :
-- signal is "mif_hann.mif";
signal is "Hann1024.mif";

TYPE STATE_TYPE IS (idle, start);
signal state : STATE_TYPE;

signal s_convolution : integer;
signal index_hann : integer range 0 to samples;
begin

    process(csi_sink_clk, rsi_sink_reset)
    begin
		if rsi_sink_reset = '0' then 
			s_convolution <= 0;
			index_hann <= 0;
			state <= idle;
			aso_Window_Multipication <= '0';
			aso_source_valid <= '0';
			out_amps <= "000";
			out_attenuator <= "000000";
			out_filters <= "00";

		elsif rising_edge(csi_sink_clk) then 
			aso_source_sop <= asi_sink_sop;
			aso_source_eop <= asi_sink_eop;
			aso_source_valid <= asi_sink_valid;	
			out_error <= in_error;
			out_protection <= in_protection;
		
			case state is 
				when idle => 
					s_convolution <= 0;
					index_hann <= 0;
					if asi_sink_sop = '1'  and asi_sink_valid = '1' then
						state <= start;
						aso_Window_Multipication <= '1';
						aso_source_valid <= '1';
					end if;
					
				when start => 
				--	aso_source_valid <= '1';
					if (asi_sink_valid = '1') then
						if ((index_hann = samples - 2) or (asi_sink_sop = '1')) then 
							index_hann <= 0;
							state <= idle;
						else
							s_convolution <= to_integer(ram(index_hann)) * to_integer(signed(asi_sink_data));
							index_hann <= index_hann + 1;
							if asi_sink_eop = '1' then
								index_hann <= 0;
							end if;
						end if;
					else 
						index_hann <= 0;
						state <= idle;
					end if;
			end case;	

			if (asi_sink_sop = '1') then -- Data That Passes Through All System Components
				out_amps <= in_amps;
				out_attenuator <= in_attenuator;
				out_filters <= in_filters; 
			end if;

		end if;
    end process;
aso_source_data <= std_logic_vector(to_signed(s_convolution/256,width_input_data_bits)); -- 2^8 because we dont need fix point number
end arch_Window_Multipication_Modified;
