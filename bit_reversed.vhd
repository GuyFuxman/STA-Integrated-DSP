--17/01/2021
--Ron Krakovsky
--this entity make counter(bit_reversed) according to fft data.
-------------------------------------------------------------------------------
--	entity Energy_detector pin discription :
--	inputs 	: i_clk				- input clock 
--				  i_valid			- input data from fft about valid 	 
--            i_sop				- input start of packet(fft)	
--				  i_eop				- input end of packet(fft)	
--				  i_reset			- input reset => '1' reset all
--
--	outputs 	: o_bit_reversed 	- outputs counter(bit_reversed) 


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_reversed is

Generic(FFT_Transform_Width       : integer   := 10);

port(
		i_clk : in std_logic;
		i_valid  : in std_logic;
		i_sop,i_eop: in std_logic;
		o_bit_reversed: out std_logic_vector(FFT_Transform_Width - 1 downto 0);
		i_reset : in std_logic


);
end entity bit_reversed;

architecture rtl of bit_reversed is
signal counter : integer range 0 to 511;
signal signal_counter : std_logic_vector(FFT_Transform_Width - 1 downto 0);
signal between : std_logic;
begin

	process(i_clk,i_reset)
	begin	
	if(i_reset = '0') then
		counter <= 0;
		between <= '0';
	elsif	rising_edge(i_clk) then 
			if i_sop = '1' and i_valid = '1' then 
				counter <= 1;
				between <= '1';
			end if;
			
			if i_eop = '1' and between = '1' then 
				between <= '0';
				counter <= 0;
			end if;
			
			if between = '1' then
				counter <= counter + 1 ;	
			end if;
	end if;
	end process;
	signal_counter <= std_logic_vector(to_unsigned(counter, FFT_Transform_Width));
	bit_reversed : for I in 0 to FFT_Transform_Width - 1 generate
		o_bit_reversed(FFT_Transform_Width - 1-I) <= signal_counter(I);		
  end generate bit_reversed;
end architecture rtl;