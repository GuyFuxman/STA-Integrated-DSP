
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Demux is

    Generic(Data_Width : integer   := 13);

    port (i_Data   : in std_logic_vector((Data_Width - 1) downto 0);
          i_Select : in std_logic;
          o_Data0  : out std_logic_vector((Data_Width - 1) downto 0);
          o_Data1  : out std_logic_vector((Data_Width - 1) downto 0)
    );
end entity Demux;

architecture Arch_Demux of Demux is
    
begin

    o_Data0 <= i_Data when i_Select = '0' else (others => '0');
    o_Data1 <= i_Data when i_Select = '1' else (others => '0');
    
end architecture Arch_Demux;