library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_PingPong_VGA is
    port (
        CLK_100MHZ : in  STD_LOGIC;              -- System Clock
        RESET      : in  STD_LOGIC;              -- System Reset (Active Low: 0 = Reset)
        BTN_L      : in  STD_LOGIC;              -- Left Button
        BTN_R      : in  STD_LOGIC;              -- Right Button
        SW_SPEED   : in  STD_LOGIC;              -- Speed Switch
        
        -- VGA Interface
        VGA_HS     : out STD_LOGIC;
        VGA_VS     : out STD_LOGIC;
        VGA_R      : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G      : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B      : out STD_LOGIC_VECTOR(3 downto 0);
        
        -- LED Output (Optional, for debugging)
        LED_OUT    : out STD_LOGIC_VECTOR(7 downto 0) 
    );
end Top_PingPong_VGA;

architecture Behavioral of Top_PingPong_VGA is

    -- Internal Signals
    signal led_state : STD_LOGIC_VECTOR(7 downto 0); -- LED status from pingpong game
    
    -- VGA Coordinate Signals
    signal h_pos     : INTEGER range 0 to 2000;
    signal v_pos     : INTEGER range 0 to 2000;
    signal video_on  : STD_LOGIC;
    -- RGB Color Signal
    signal rgb_out   : STD_LOGIC_VECTOR(11 downto 0);
    -- Reset Signal for VGA (Inverted because VGA uses Active High reset)
    signal vga_reset : STD_LOGIC;

    -- Drawing Constants (Modified for Circle)
    constant BOX_W   : integer := 50;  -- [修改] 寬度改為 50
    constant BOX_H   : integer := 50;  -- [修改] 高度改為 50 (正方形)
    constant GAP     : integer := 20;  -- Gap between boxes
    constant START_X : integer := 100; -- Starting X coordinate
    constant START_Y : integer := 280; -- Starting Y coordinate
    
    -- [新增] 圓形半徑平方 (半徑約 22，22^2 = 484)
    constant R_SQ    : integer := 484; 

begin

    -- Reset Logic Fix:
    -- Pingpong uses '0' for reset (Active Low).
    -- VGA uses '1' for reset (Active High).
    -- We assume input RESET is Active Low (like pingpong).
    vga_reset <= not RESET; 

    -- 1. Instantiate PingPong Game Logic
    inst_pingpong: entity work.pingpong
        port map (
            i_clk          => CLK_100MHZ,
            i_rst          => RESET,       -- Active Low
            i_left_button  => BTN_L,
            i_right_button => BTN_R,
            i_speed_switch => SW_SPEED,
            o_count        => led_state
        );
    LED_OUT <= led_state;

    -- 2. Instantiate VGA Controller
    inst_vga: entity work.VGA
        port map (
            i_clk        => CLK_100MHZ,
            i_rst        => vga_reset,   -- Active High (Inverted)
            
            -- Pixel Data & Coordinates
            i_pixel_data => rgb_out,     -- Color input from Top
            o_h_pos      => h_pos,       -- Current X position
            o_v_pos      => v_pos,       -- Current Y position
            o_video_on   => video_on,    -- Visible area flag
            
            -- Hardware Outputs
            o_red        => VGA_R,
            o_green      => VGA_G,
            o_blue       => VGA_B,
            o_h_sync     => VGA_HS,
            o_v_sync     => VGA_VS
        );

    -- 3. Graphics Generation Logic (Modified for Circle & No Line)
    process(h_pos, v_pos, video_on, led_state)
        variable box_idx : integer;
        variable rel_x   : integer;
        variable rel_y   : integer;
        variable center  : integer := BOX_W / 2; -- 中心點 (25)
        variable dist_sq : integer;
    begin
        -- Default Background Color (Black)
        rgb_out <= "000000000000";
        
        if video_on = '1' then
            
            -- Check Y range for the row of boxes
            if (v_pos >= START_Y) and (v_pos < START_Y + BOX_H) then
                -- Check X range for the whole group of boxes
                if (h_pos >= START_X) and (h_pos < START_X + (BOX_W + GAP) * 8) then
                    
                    -- Calculate relative coordinates inside the "Box + Gap" period
                    rel_x := (h_pos - START_X) mod (BOX_W + GAP);
                    rel_y := v_pos - START_Y;
                    
                    -- Only draw if within the box width (skip the gap)
                    if rel_x < BOX_W then
                        
                        -- Calculate which box we are currently drawing (Index 0 to 7)
                        box_idx := 7 - ((h_pos - START_X) / (BOX_W + GAP));
                        
                        -- [圓形邏輯] 計算距離中心的平方
                        dist_sq := (rel_x - center) * (rel_x - center) + (rel_y - center) * (rel_y - center);
                        
                        -- 如果距離小於半徑平方，則上色
                        if dist_sq < R_SQ then
                            -- Safety check for index bounds
                            if box_idx >= 0 and box_idx <= 7 then
                                -- Default Circle Color (Dim Gray Frame)
                                rgb_out <= "001100110011"; 
                                
                                -- If the LED bit is '1', light it up!
                                if led_state(box_idx) = '1' then
                                    if box_idx >= 4 then
                                        rgb_out <= "111100000000"; -- Red for Left side
                                    else
                                        rgb_out <= "000011110000"; -- Green for Right side
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
            
            -- [已刪除] 原本的白色地板線條程式碼已移除
            
        else
            rgb_out <= (others => '0'); -- Blanking interval
        end if;
    end process;

end Behavioral;