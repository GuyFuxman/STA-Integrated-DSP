Library IEEE;
USE IEEE.Std_logic_1164.all;
use ieee.numeric_std.all;

Entity Fixed_Point_Data_Sizer is 

	Generic(FFT_In_Data_Width       : integer   := 16;
			  FFT_Transform_Width     : integer   := 9;
			  FFT_Max_Transform_Width : integer   := 9;
			  MsbWidth                : integer   := 32;
			  Fraction_Size           : integer   := 3);


   port( i_Squared_Data         : in std_logic_vector ((MsbWidth - 1) downto 0);
			i_Bit_Reversed_Counter : in std_logic_vector ((FFT_Transform_Width - 1) downto 0);
		   O_Data_To_Logger       : out std_logic_vector ((MsbWidth - 2) downto 0); -- ufixed31_3
			O_Data_to_HPS          : out std_logic_vector ((MsbWidth - 1) downto 0)
		 );
end Entity;

Architecture Arch_Fixed_Point_Data_Sizer of Fixed_Point_Data_Sizer is

begin  

o_Data_To_Logger((Fraction_Size - 1) downto 0) <= (others => '0');
o_Data_To_Logger((MsbWidth - 2) downto Fraction_Size) <= i_Squared_Data((MsbWidth - 2 - Fraction_Size) downto 0);

o_Data_to_HPS((FFT_Transform_Width - 1) downto 0) <= i_Bit_Reversed_Counter;
o_Data_to_HPS((MsbWidth - 1) downto FFT_Transform_Width) <= (others => '0');

 
end Arch_Fixed_Point_Data_Sizer; 