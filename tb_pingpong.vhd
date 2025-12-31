library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_pingpong is
end tb_pingpong;

architecture Behavioral of tb_pingpong is
    component pingpong is
        port(
            i_clk            : in STD_LOGIC;
            i_rst            : in STD_LOGIC;
            i_left_button    : in STD_LOGIC; 
            i_right_button   : in STD_LOGIC;
            i_speed_switch   : in STD_LOGIC;
            o_count          : out STD_LOGIC_VECTOR(7 downto 0)     
        );   
    end component;
    
    signal i_clk            : STD_LOGIC := '0';
    signal i_rst            : STD_LOGIC := '1';
    signal i_left_button    : STD_LOGIC := '0';
    signal i_right_button   : STD_LOGIC := '0';
    signal i_speed_switch   : STD_LOGIC := '0';
    signal o_count          : STD_LOGIC_VECTOR(7 downto 0);
    
    constant clk_period     : time := 10 ns;
    signal test_done        : boolean := false;
    
begin
    uut: pingpong
        port map (
            i_clk          => i_clk,
            i_rst          => i_rst,
            i_left_button  => i_left_button,
            i_right_button => i_right_button,
            i_speed_switch => i_speed_switch,
            o_count        => o_count
        );
    
    -- 時鐘生成
    clk_process: process
    begin
        while not test_done loop
            i_clk <= '0';
            wait for clk_period/2;
            i_clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;
    
    -- 測試刺激
    stim_proc: process
    begin
        -- Reset
        i_rst <= '0';
        wait for 100 ns;
        i_rst <= '1';
        wait for 100 ns;
        
        -- Test 1: 右發球，左失誤（右得分）
        report "Test 1: Right serves, Left misses";
        i_right_button <= '1';
        wait for 100 ns;
        i_right_button <= '0';
        wait for 2000 ns;  -- 等待球移動，左邊失誤
        
        -- Test 2: 左發球，右失誤（左得分）
        report "Test 2: Left serves, Right misses";
        i_left_button <= '1';
        wait for 100 ns;
        i_left_button <= '0';
        wait for 2000 ns;
        
        -- Test 3: 完整對打 - 右發球，來回幾次後左失誤
        report "Test 3: Rally with multiple hits";
        
        -- 右邊發球
        report "Right serves";
        i_right_button <= '1';
        wait for 50 ns;
        i_right_button <= '0';
        
        -- 等待球移動到最左邊（10000000）
        wait until o_count = "10000000";
        wait for 10 ns;  -- 小延遲確保穩定
        report "Ball reached left side";
        
        -- 左邊擊球
        i_left_button <= '1';
        wait for 50 ns;
        i_left_button <= '0';
        
        -- 等待球移動到最右邊（00000001）
        wait until o_count = "00000001";
        wait for 10 ns;
        report "Ball reached right side";
        
        -- 右邊擊球
        i_right_button <= '1';
        wait for 50 ns;
        i_right_button <= '0';
        
        -- 等待球移動到最左邊（10000000）
        wait until o_count = "10000000";
        wait for 10 ns;
        report "Ball reached left side again";
        
        -- 左邊擊球
        i_left_button <= '1';
        wait for 50 ns;
        i_left_button <= '0';
        
        -- 等待球移動到最右邊（00000001）
        wait until o_count = "00000001";
        wait for 10 ns;
        report "Ball reached right side again";
        
        -- 右邊不擊球，失誤
        report "Right misses - Left scores!";
        wait for 2000 ns;
        
        -- Test 4: 隨機速度模式
        report "Test 4: Random speed";
        i_speed_switch <= '1';
        i_right_button <= '1';
        wait for 100 ns;
        i_right_button <= '0';
        wait for 2000 ns;
        
        report "Tests done";
        test_done <= true;
        wait;
    end process;

end Behavioral;