-- Name : Ron Krakovsky 
-- Component : Calculate 10LOG(in) with 2 components from ip core, 
-- ALTFP_CONVERT & ALTFP_LOG (this components work in FLOATING POINT).
-- The component take 33 clocks for result : 12 for convert & 21 for log.
-- the input is integer 32 bit and output sfix32_En10  

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity log10 is
    port (
        i_clk : in std_logic;
        i_reset : in std_logic;
        
        -- AVALON STRIMING SINK
        asi_sink_ready : out std_logic;
        asi_sink_valid : in std_logic;
        asi_sink_data : in std_logic_vector(31 DOWNTO 0); --sfix32_En0

        -- AVALON STRIMING SOURCE
        aso_source_data   : out std_logic_vector(31 DOWNTO 0); --sfix32_En10
        aso_source_valid  : out std_logic 

    );
end entity log10;

architecture rtl of log10 is
     
    component conv_int2FP
        PORT
        (
            clock		: IN STD_LOGIC ;
            dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
        );
    end component;
    
    component log_v2
        PORT
        (
            aclr		: IN STD_LOGIC ;
            clock		: IN STD_LOGIC ;
            data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
        );
    end component;

   component conv_FP2FIX
	    PORT
	    (
	    	clock		: IN STD_LOGIC ;
	    	dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
	    	result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	    );
    end component;
    

signal sig_result, sig_result2, sig_result3 : std_logic_vector(31 DOWNTO 0);
signal sig_past_argu, sig_cal_argu : std_logic_vector(31 downto 0);
signal sig_log, counter : integer;
signal sig_aclr, sig_ready: std_logic;

type states_T is (idle, cal);
signal state : states_T;

begin

    main : process(i_clk)
    begin
        if i_reset = '0' then 
            state <= idle;
            sig_ready <= '0';
            aso_source_valid <= '0';
        elsif rising_edge(i_clk) then
            case state is
                when idle =>

                    if asi_sink_valid = '1' and sig_ready = '1' then 
                        state <= cal;
                        sig_cal_argu <= asi_sink_data;
                        sig_aclr <= '0';
                        counter <= 1;
                        sig_ready <= '0';
                    else
                        sig_aclr <= '1';
                        counter <= 0;
                        sig_ready <= '1';
                    end if;
                    
                    aso_source_valid <= '0';
                    
                    
                when cal =>
                    
                    if counter = 33 then 
                        aso_source_valid <= '1';
                        counter <= 0;
                        state <= idle;
                    else
                        counter <= counter + 1;
                    end if;
                    
            end case;

        end if;
    end process main;

    u1 : conv_int2FP port map (clock => i_clk ,dataa => sig_cal_argu , result => sig_result);
    u2 : log_v2 port map (aclr => sig_aclr ,clock => i_clk ,data => sig_result , result => sig_result2);
    u3 : conv_FP2FIX port map (clock => i_clk ,dataa => sig_result2 , result => sig_result3);
    
    sig_log <= (to_integer(signed(sig_result3)))*4451; -- 4.347*ln(in) = 10log(in)
    aso_source_data <= STD_LOGIC_VECTOR(shift_right(to_signed(sig_log,32),10));

    asi_sink_ready <= sig_ready;
end architecture rtl;
