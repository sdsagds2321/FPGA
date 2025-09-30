library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity counter is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           o_count1 : out STD_LOGIC_VECTOR (7 downto 0);
           o_count2 : out STD_LOGIC_VECTOR (7 downto 0);
           o_count3 : out STD_LOGIC_VECTOR (7 downto 0)
           );
end counter;

architecture Behavioral of counter is
    signal count1 : STD_LOGIC_VECTOR (7 downto 0);
    signal count2 : STD_LOGIC_VECTOR (7 downto 0);
    signal count3 : STD_LOGIC_VECTOR (7 downto 0);
    type FSM_STATE is (s0, s1, s2, s3, s4, s5);
    signal state : FSM_STATE;
begin
    o_count1 <= count1;
    o_count2 <= count2;
    o_count3 <= count3;

    -- FSM process
    FSM:process(i_clk, i_rst, count1, count2, count3)
    begin
        if i_rst = '0' then
            state <= s0;
        elsif rising_edge(i_clk) then
            case state is
                when s0 =>
                    if count1 = "00001000" then
                        state <= s3;
                    end if;
                when s1 =>
                    if count2 = "01010000" then
                        state <= s4;
                    end if;
                when s2 =>
                    if count3 = "00010100" then
                        state <= s5;
                    end if;
                when s3 =>
                    state <= s1;
                when s4 =>
                    state <= s2;
                when s5 =>
                    state <= s0;
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Counter1 process
    counter1:process(i_clk, i_rst, state)
    begin
        if i_rst = '0' then
            count1 <= (others => '0');
        elsif rising_edge(i_clk) then
            case state is
                when s0 =>
                    count1 <= count1 + '1';
                when s3 =>
                    count1 <= (others => '0');
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Counter2 process
    counter2:process(i_clk, i_rst, state)
    begin
        if i_rst = '0' then
            count2 <= "11111101";
        elsif rising_edge(i_clk) then
            case state is
                when s1 =>
                    count2 <= count2 - '1';
                when s4 =>
                    count2 <= "11111101";
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Counter3 process
    counter3:process(i_clk, i_rst, state)
    begin
        if i_rst = '0' then
            count3 <= "00001011";
        elsif rising_edge(i_clk) then
            case state is
                when s2 =>
                    count3<=count3 + '1'; 
                when s5 =>
                    count3 <= "00001010";
                when others =>
                    null;
            end case;
        end if;
    end process;

end Behavioral;