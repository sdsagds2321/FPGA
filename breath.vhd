library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity breath is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           o_led : out STD_LOGIC
         );
end breath;

architecture Behavioral of breath is
    component hw1_2cnters 
        Port (
           i_clk       : in STD_LOGIC;
           i_rst        : in STD_LOGIC;
           i_upperBound1: in STD_LOGIC_VECTOR (7 downto 0);
           i_upperBound2: in STD_LOGIC_VECTOR (7 downto 0);
           o_state        : out STD_LOGIC
             );           
    end component;
    
    type STATE2TYPE is (gettingBright, gettingDark);
    signal              upbnd1 : STD_LOGIC_VECTOR (7 downto 0);
    signal              upbnd2 : STD_LOGIC_VECTOR (7 downto 0);
    signal              state2 : STATE2TYPE;
    signal alreadyP_PWM_cycles : STD_LOGIC;
    signal              pwmCnt : STD_LOGIC_VECTOR (7 downto 0);
    constant                 P : STD_LOGIC_VECTOR (7 downto 0) := "00000011"; --3
    signal           pwm_pedge : STD_LOGIC;
    signal              pwm : STD_LOGIC;
    signal             pwm_old : STD_LOGIC;
begin

    hw1: hw1_2cnters 
        port map (
            i_clk         => i_clk,
            i_rst         => i_rst,
            i_upperBound1 => upbnd1,
            i_upperBound2 => upbnd2,
            o_state       => pwm
        );
    
    o_led <= pwm;
        
    FSM2: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            state2 <= gettingBright;
        elsif i_clk'event and i_clk = '1' then
            case state2 is
                when gettingBright =>
                    if upbnd1 >= "11111111" then  -- 修正：用 >=
                        state2 <= gettingDark;
                    end if;
                when gettingDark =>
                    if upbnd1 <= "00000000" then  -- 修正：檢查 upbnd1
                        state2 <= gettingBright;
                    end if;
                when others =>
                    null;
            end case;
        end if;        
    end process;

    upbnd1p: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            upbnd1 <= "00000000";
        elsif i_clk'event and i_clk = '1' then
            case state2 is
                when gettingBright =>
                   if alreadyP_PWM_cycles = '1' then
                       if upbnd1 < "11111111" then  -- 修正：加入邊界檢查
                           upbnd1 <= upbnd1 + '1';
                       end if;
                   end if;
                when gettingDark =>
                   if alreadyP_PWM_cycles = '1' then
                       if upbnd1 > "00000000" then  -- 修正：加入邊界檢查
                           upbnd1 <= upbnd1 - '1';
                       end if;
                   end if;
                when others =>
                    null;
            end case;
        end if;
    end process upbnd1p;

    upbnd2p: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            upbnd2 <= "11111111";
        elsif i_clk'event and i_clk = '1' then
            case state2 is
                when gettingBright =>
                   if alreadyP_PWM_cycles = '1' then
                       if upbnd2 > "00000000" then  -- 修正：加入邊界檢查
                           upbnd2 <= upbnd2 - '1';
                       end if;
                   end if;
                when gettingDark =>
                   if alreadyP_PWM_cycles = '1' then
                       if upbnd2 < "11111111" then  -- 修正：加入邊界檢查
                           upbnd2 <= upbnd2 + '1';
                       end if;
                   end if;
                when others =>
                    null;
            end case;
        end if;
    end process upbnd2p;
        
    P_PWM_cycles:  process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            pwmCnt <= "00000000";
            alreadyP_PWM_cycles <= '0';
        elsif i_clk'event and i_clk = '1' then
            alreadyP_PWM_cycles <= '0';
            
            if pwm_pedge = '1' then
                if pwmCnt >= P then
                    pwmCnt <= "00000000";
                    alreadyP_PWM_cycles <= '1';
                else
                    pwmCnt <= pwmCnt + '1';
                end if;
            end if;
        end if;
    end process P_PWM_cycles;
    
    detect_PWM_edge: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            pwm_pedge <= '0';
            pwm_old <='0';
        elsif i_clk'event and i_clk = '1' then    
            pwm_old <= pwm;
            if pwm_old = '0' and pwm='1' then
                pwm_pedge <= '1';
            else
                pwm_pedge <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;