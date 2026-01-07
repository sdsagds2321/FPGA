library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity vga_shapes is
    Port ( clk       : in  STD_LOGIC;       -- FPGA時鐘
           rst_n     : in  STD_LOGIC;       -- 重置信號
           hsync     : out STD_LOGIC;       -- 水平同步信號
           vsync     : out STD_LOGIC;       -- 垂直同步信號
           red       : out STD_LOGIC_VECTOR (3 downto 0);  -- 紅色顏色分量
           green     : out STD_LOGIC_VECTOR (3 downto 0);  -- 綠色顏色分量
           blue      : out STD_LOGIC_VECTOR (3 downto 0)   -- 藍色顏色分量
           );
end vga_shapes;

architecture Behavioral of vga_shapes is
    -- VGA參數定義 (640x480解析度，60Hz刷新率)
    constant H_SYNC_CYCLES : integer := 96;  -- 水平同步脈寬
    constant H_BACK_PORCH : integer := 48;   -- 水平後座標
    constant H_ACTIVE_VIDEO : integer := 640; -- 顯示區寬度
    constant H_FRONT_PORCH : integer := 16;  -- 水平前座標
    constant V_SYNC_CYCLES : integer := 2;   -- 垂直同步脈寬
    constant V_BACK_PORCH : integer := 33;   -- 垂直後座標
    constant V_ACTIVE_VIDEO : integer := 480; -- 顯示區高度
    constant V_FRONT_PORCH : integer := 10;  -- 垂直前座標

    signal divclk: STD_LOGIC_VECTOR(1 downto 0);  -- 分頻時鐘
    signal fclk: STD_LOGIC;  -- 像素時鐘 (分頻後的時鐘)
    signal h_count : integer range 0 to 799 := 0;  -- 水平計數器
    signal v_count : integer range 0 to 524 := 0;  -- 垂直計數器
    
    -- 顯示區域信號
    signal pixel_x : integer range 0 to 639 := 0;
    signal pixel_y : integer range 0 to 479 := 0;
    signal display_active : STD_LOGIC := '0';
    
    -- 圖形參數定義
    -- 圓形1（左上角，綠色）
    constant CIRCLE1_X : integer := 150;
    constant CIRCLE1_Y : integer := 120;
    constant CIRCLE1_R : integer := 60;
    
    -- 矩形（中央偏上，藍色）
    constant RECT_LEFT   : integer := 250;
    constant RECT_RIGHT  : integer := 390;
    constant RECT_TOP    : integer := 80;
    constant RECT_BOTTOM : integer := 180;
    
    -- 三角形（右下角，紅色）
    -- 三個頂點座標
    constant TRI_X1 : integer := 500;  -- 頂點1 (頂部)
    constant TRI_Y1 : integer := 250;
    constant TRI_X2 : integer := 420;  -- 頂點2 (左下)
    constant TRI_Y2 : integer := 400;
    constant TRI_X3 : integer := 580;  -- 頂點3 (右下)
    constant TRI_Y3 : integer := 400;
    
begin
    -- ===========================================
    -- 水平和垂直計數器
    -- ===========================================
    process(fclk, rst_n)
    begin
        if rst_n = '0' then
            h_count <= 0;
            v_count <= 0;
        elsif rising_edge(fclk) then
            if h_count = 799 then
                h_count <= 0;
                if v_count = 524 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;
    
    -- 同步信號生成
    hsync <= '0' when (h_count < H_SYNC_CYCLES) else '1';
    vsync <= '0' when (v_count < V_SYNC_CYCLES) else '1';
    
    -- ===========================================
    -- 顯示區域檢測
    -- ===========================================
    display_active <= '1' when (h_count >= H_SYNC_CYCLES + H_BACK_PORCH and 
                                h_count < H_SYNC_CYCLES + H_BACK_PORCH + H_ACTIVE_VIDEO and
                                v_count >= V_SYNC_CYCLES + V_BACK_PORCH and 
                                v_count < V_SYNC_CYCLES + V_BACK_PORCH + V_ACTIVE_VIDEO)
                          else '0';
    
    -- 計算顯示區域內的像素座標
    pixel_x <= h_count - (H_SYNC_CYCLES + H_BACK_PORCH) when display_active = '1' else 0;
    pixel_y <= v_count - (V_SYNC_CYCLES + V_BACK_PORCH) when display_active = '1' else 0;
    
    -- ===========================================
    -- 顏色輸出邏輯（三種圖形）
    -- ===========================================
    process(fclk, rst_n)
        variable dx, dy : integer;
        variable dist_sq : integer;
        -- 三角形判斷用的變數
        variable sign1, sign2, sign3 : integer;
        variable has_neg, has_pos : boolean;
    begin
        if rst_n = '0' then
            red   <= "0000";
            green <= "0000";
            blue  <= "0000";
        elsif rising_edge(fclk) then
            if display_active = '1' then
                -- 預設背景為黑色
                red   <= "0000";
                green <= "0000";
                blue  <= "0000";

                -- ========================================
                -- 圖形 1: 圓形（左上，綠色）
                -- ========================================
                dx := pixel_x - CIRCLE1_X;
                dy := pixel_y - CIRCLE1_Y;
                dist_sq := dx*dx + dy*dy;
                
                if dist_sq <= CIRCLE1_R*CIRCLE1_R then
                    red   <= "0000";
                    green <= "1111";  -- 綠色
                    blue  <= "0000";
                end if;
                
                -- ========================================
                -- 圖形 2: 矩形（中央偏上，藍色）
                -- ========================================
                if (pixel_x >= RECT_LEFT and pixel_x <= RECT_RIGHT and 
                    pixel_y >= RECT_TOP and pixel_y <= RECT_BOTTOM) then
                    red   <= "0000";
                    green <= "0000";
                    blue  <= "1111";  -- 藍色
                end if;
                
                -- ========================================
                -- 圖形 3: 三角形（右下，紅色）
                -- 使用重心座標法判斷點是否在三角形內
                -- ========================================
                -- 計算三個邊的符號
                sign1 := (pixel_x - TRI_X2) * (TRI_Y1 - TRI_Y2) - (TRI_X1 - TRI_X2) * (pixel_y - TRI_Y2);
                sign2 := (pixel_x - TRI_X3) * (TRI_Y2 - TRI_Y3) - (TRI_X2 - TRI_X3) * (pixel_y - TRI_Y3);
                sign3 := (pixel_x - TRI_X1) * (TRI_Y3 - TRI_Y1) - (TRI_X3 - TRI_X1) * (pixel_y - TRI_Y1);
                
                -- 判斷是否所有符號相同（點在三角形內）
                has_neg := (sign1 < 0) or (sign2 < 0) or (sign3 < 0);
                has_pos := (sign1 > 0) or (sign2 > 0) or (sign3 > 0);
                
                if not (has_neg and has_pos) then
                    red   <= "1111";  -- 紅色
                    green <= "0000";
                    blue  <= "0000";
                end if;
                
            else
                -- 非顯示區域輸出黑色
                red   <= "0000";
                green <= "0000";
                blue  <= "0000";
            end if;
        end if;
    end process;

    -- ===========================================
    -- 時鐘分頻: 100 MHz → 25 MHz
    -- ===========================================
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            divclk <= (others => '0');
        elsif rising_edge(clk) then
            divclk <= divclk + 1;
        end if;
    end process;
    
    fclk <= divclk(1);  -- 使用分頻後的時鐘作為像素時鐘
    
end Behavioral;
