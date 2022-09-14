library IEEE;
use IEEE.std_logic_1164.all;

entity AndGate is

    port(A : in std_logic;      
         B : in std_logic;      
         Y : out std_logic);    

end AndGate;

architecture AndLogic of AndGate is

 begin
    
    Y <= A AND B;

end AndLogic; 