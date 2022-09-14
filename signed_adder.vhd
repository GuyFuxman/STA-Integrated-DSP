-- Quartus Prime VHDL Template
-- Signed Adder

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signed_adder is

	generic
	(
		DATA_WIDTH : natural := 16
	);

	port 
	(
		a	   : in std_logic_vector ((DATA_WIDTH-1) downto 0);
		b	   : in std_logic_vector((DATA_WIDTH-1) downto 0);
		result : out std_logic_vector ((DATA_WIDTH-1) downto 0)
	);

end entity;

architecture rtl of signed_adder is
signal s_result : signed ((DATA_WIDTH) downto 0);
begin

	s_result <= resize(signed(a),DATA_WIDTH + 1) + resize(signed(b),DATA_WIDTH + 1);
	result <= std_logic_vector(s_result(DATA_WIDTH downto 1));

end rtl;


