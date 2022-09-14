/* This Entity is the 3 Stage RAM Manager, the Componment will handle the the write/read operations.

    Read - Write Operation:
    The RAM Data will be the FFT Magnitude, while the RAM Address will be the Bit-Reversed Index.
    
    The RAM will consist 3 parts: 30MHz -> 43MHz, 43MHz -> 58MHz, 58MHz -> 88MHz, each corresponding to the FFT index.
    
    The RAM will be loaded and read from, according to the decimation factor (how many packets will be thrown away).

*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Three_Filter_RAM_Manager is

    Generic(FFT_Transform_Width          : integer   := 14;
            Magnitude_Width              : integer   := 32;
            RAM_Size                     : integer   := 12;
            First_Stage_Frequency        : integer   := 3277;   -- 30MHz
            Second_Stage_Frequency       : integer   := 4697;   -- 43MHz
            Third_Stage_Frequency        : integer   := 6335;   -- 58MHz
            End_Frequency                : integer   := 7209);  -- 66MHz

    port (i_clk, i_reset, i_valid, i_sop, i_eop, i_enable : in std_logic;
          i_Magnitude                                     : in std_logic_vector((Magnitude_Width - 1) downto 0);
          i_Bit_Reversed_Counter                          : in std_logic_vector((FFT_Transform_Width - 1) downto 0);
          i_Filter_Info                                   : in std_logic_vector(1 downto 0);
          o_Write_Address                                 : out std_logic_vector((RAM_Size - 1) downto 0);
          o_Write_Data                                    : out std_logic_vector((Magnitude_Width - 1) downto 0);
          o_Write_Enable, o_RAM_Mux_Select                : out std_logic;
          o_Read_Address                                  : out std_logic_vector((RAM_Size - 1) downto 0);
          o_sop,o_eop,o_valid                             : out std_logic;

          -- Debug Outputs
          o_Write_Address_Debug : out std_logic_vector(13 downto 0)
          --
    );
end entity Three_Filter_RAM_Manager;

architecture Arch_Three_Filter_RAM_Manager of Three_Filter_RAM_Manager is
    
    type t_Filter_Stage is (st_Filter_Stage_1, st_Filter_Stage_2, st_Filter_Stage_3);
    signal s_Filter_Stage : t_Filter_Stage;

    signal s_Reading_Address  : integer range (2**(RAM_Size) - 1) downto 0;
    signal s_RAM_Mux_Select   : std_logic; -- Read/Write Mux Control

    signal s_Writing_Address  : integer range (2**RAM_Size) downto 0;

begin
    
    -- Output Value Asserting
    o_Read_Address <= std_logic_vector(to_unsigned(s_Reading_Address, o_Read_Address'length)); 
    o_RAM_Mux_Select <= s_RAM_Mux_Select;

    -- Write Address Manipulation to Match RAM Indexes (RAM Starts from Index 0, The First Bit-Reversed Index is The First Frequency Value)
   -- s_Writing_Address <= (to_integer(unsigned(i_Bit_Reversed_Counter))) - First_Stage_Frequency; 
    o_Write_Address <= std_logic_vector(to_unsigned(s_Writing_Address, o_Write_Address'length));

    -- Packeted Output
    o_sop <= i_sop when ((i_reset = '1') and (s_Filter_Stage = st_Filter_Stage_1)) else '0'; 
    o_eop <= i_eop when ((i_reset = '1') and (s_Filter_Stage = st_Filter_Stage_1)) else '0'; 
    o_valid <= i_valid when ((i_reset = '1') and (s_Filter_Stage = st_Filter_Stage_1)) else '0';          

    -- Debug Outputs
    o_Write_Address_Debug <= std_logic_vector(to_unsigned(s_Writing_Address, o_Write_Address_Debug'length));
    --


    process(i_clk, i_reset) -- Regular Constant Loading RAM
    begin
        
        if (i_reset = '0') then -- Asyc Active Low Reset
            o_Write_Enable <= '0';
            s_RAM_Mux_Select <= '0';
        
        elsif rising_edge(i_clk) then
            s_Writing_Address <= (to_integer(unsigned(i_Bit_Reversed_Counter))) - First_Stage_Frequency;
            case s_Filter_Stage is

                when st_Filter_Stage_1 => -- 30MHz -> 43MHz Write Operation
                    if (((to_integer(unsigned(i_Bit_Reversed_Counter))) >= First_Stage_Frequency) and (((to_integer(unsigned(i_Bit_Reversed_Counter))) < Second_Stage_Frequency))) then
                         o_Write_Enable <= '1'; -- While The Bit-Reversed Counter is in The Filter-Stage Range, Write the Magnitude to The RAM
                         o_Write_Data <= i_Magnitude; 
                    else
                         o_Write_Enable <= '0'; -- Bit-Reversed Counter is not in The Filter-Stage Range
                    end if;

                when st_Filter_Stage_2 => -- 43MHz -> 58MHz Write Operation
                    if (((to_integer(unsigned(i_Bit_Reversed_Counter))) >= Second_Stage_Frequency) and (((to_integer(unsigned(i_Bit_Reversed_Counter))) < Third_Stage_Frequency))) then
                        o_Write_Enable <= '1';
                        o_Write_Data <= i_Magnitude;
                    else
                        o_Write_Enable <= '0';
                    end if;

                when st_Filter_Stage_3 => -- 58MHz -> 88MHz Write Operation
                    if (((to_integer(unsigned(i_Bit_Reversed_Counter))) >= Third_Stage_Frequency) and (((to_integer(unsigned(i_Bit_Reversed_Counter))) <= End_Frequency))) then
                        o_Write_Enable <= '1';
                        o_Write_Data <= i_Magnitude;
                    else
                        o_Write_Enable <= '0';
                    end if;
                    if ((to_integer(unsigned(i_Bit_Reversed_Counter))) = (2**FFT_Transform_Width - 1)) then -- Last Index of Last Filter-Stage (End of Packet)
                        s_RAM_Mux_Select <= not(s_RAM_Mux_Select); -- Mux Control will Flip Value, Switching The RAMs Read/Write Operations
                    end if; 

                when others =>

            end case;   
      end if;

    end process;

    process(i_clk, i_reset) -- Reading Operation
    begin

        if (i_reset = '0') then -- Asyc Active Low Reset
            s_Reading_Address <= 0;
        elsif rising_edge(i_clk) then
            if (i_eop = '1') then -- New Packet is About To Start
                s_Reading_Address <= 0;
            else
                s_Reading_Address <= s_Reading_Address + 1; -- Constant Read
            end if;
        end if;

    end process;

    process(i_clk, i_reset) -- Filter Stages Navigation Process, The Stage Will Change After Each Packet in a Cyclic Way (1->2->3->1...)
    begin
        
        if (i_reset = '0') then -- Asyc Active Low Reset
            s_Filter_Stage <= st_Filter_Stage_1;

        elsif rising_edge(i_clk) then
				if (i_sop = '1') then
					case i_Filter_Info is
	
						when "00" => 
							s_Filter_Stage <= st_Filter_Stage_1;
	
						when "01" => 
							s_Filter_Stage <= st_Filter_Stage_2;
	
						when "10" => 
							s_Filter_Stage <= st_Filter_Stage_3;
	
						when others =>
	
					end case;
				 end if; 

         /*   if (i_eop = '1') then 
                case s_Filter_Stage is

                    when st_Filter_Stage_1 => -- 30MHz -> 43MHz 
                        s_Filter_Stage <= st_Filter_Stage_2;
                    
                    when st_Filter_Stage_2 => -- 43MHz -> 58MHz 
                        s_Filter_Stage <= st_Filter_Stage_3;
                    
                    when st_Filter_Stage_3 => -- 58MHz -> 88MHz 
                        s_Filter_Stage <= st_Filter_Stage_1;
                    
                    when others =>
                
                end case;
            end if;    */

        end if;

    end process;
    
end architecture Arch_Three_Filter_RAM_Manager;



