library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;

entity packetizer is
    generic (
        ADC_WIDTH      : integer := 16;
        MAX_PACKET_LEN : integer := 16384
    );
    port (
        clk     : in    std_logic;
        reset_n : in    std_logic;

        adc_i : in    std_logic_vector(ADC_WIDTH - 1 downto 0);

        cpld_amps_i       : in    std_logic_vector(2 downto 0);
        cpld_filters_i    : in    std_logic_vector(1 downto 0);
        cpld_attenuator_i : in    std_logic_vector(5 downto 0);
        cpld_valid_i      : in    std_logic;
        cpld_protection_i : in    std_logic;
        cpld_new_msg_i    : in    std_logic;

        cpld_filters_o : out   std_logic_vector(1 downto 0);
        cpld_valid_o   : out   std_logic;
        cpld_ready_i   : in    std_logic;

        out_adc        : out   std_logic_vector(ADC_WIDTH - 1 downto 0);
        out_amps       : out   std_logic_vector(2 downto 0);
        out_filters    : out   std_logic_vector(1 downto 0);
        out_attenuator : out   std_logic_vector(5 downto 0);
        out_protection : out   std_logic;
        out_error      : out   std_logic;
        out_valid      : out   std_logic;
        out_sop        : out   std_logic;
        out_eop        : out   std_logic
    );
end entity packetizer;

architecture rtl of packetizer is

    type t_states is (s0, s1, s2, s3);

    signal r_state : t_states;

    signal r_filters : std_logic_vector(1 downto 0);
    signal r_count   : integer range 0 to MAX_PACKET_LEN - 1;

begin

    p_state : process (clk) is
    begin

        if (clk'event and clk = '1') then
            if (reset_n = '0') then
                r_state <= s0;
                r_count <= 0;

                out_protection <= '0';
                out_error      <= '0';
                out_valid      <= '0';
                out_sop        <= '0';
                out_eop        <= '0';

                out_amps       <= (others => '0');
                out_filters    <= (others => '0');
                out_attenuator <= (others => '0');
                r_filters      <= (others => '0');
                cpld_filters_o <= (others => '0');
                cpld_valid_o   <= '0';
            else
                out_adc <= adc_i;

                case r_state is

                    when s0 =>

                        if (cpld_ready_i = '1') then
                            cpld_filters_o <= r_filters;
                            cpld_valid_o   <= '1';
                            r_state        <= s1;
                        end if;

                    when s1 =>

                        cpld_valid_o <= '0';
                        if (cpld_new_msg_i = '1' and cpld_valid_i = '1') then
                            if (r_filters /= cpld_filters_i) then
                                r_state <= s0;
                            else
                                -- if (cpld_protection_i = '1') then
                                --     out_protection <= '1';
                                -- end if;
                                out_protection <= cpld_protection_i;
                                r_state        <= s2;
                                out_valid      <= '1';
                                out_sop        <= '1';
                                out_amps       <= cpld_amps_i;
                                out_filters    <= cpld_filters_i;
                                out_attenuator <= cpld_attenuator_i;
                            end if;
                        end if;

                    when s2 =>

                        out_sop <= '0';
                        if (cpld_valid_i = '0') then
                            out_valid <= '0';
                            out_error <= '1';
                        else
                            if (r_count < MAX_PACKET_LEN - 2) then
                                r_count <= r_count + 1;
                            else
                                r_count <= 0;
                                out_eop <= '1';
                                r_state <= s3;
                            end if;
                            out_valid <= '1';
                        end if;

                        if (cpld_protection_i = '1') then
                            out_protection <= '1';
                        end if;

                    when s3 =>

                        r_state <= s0;

                        out_protection <= '0';
                        out_valid      <= '0';
                        out_sop        <= '0';
                        out_eop        <= '0';
                        out_error      <= '0';

                        if (r_filters < 2) then
                            r_filters <= r_filters + 1;
                        else
                            r_filters <= (others => '0');
                        end if;

                end case;

            end if;
        end if;

    end process p_state;

end architecture rtl;