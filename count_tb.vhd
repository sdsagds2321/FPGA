library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity count_tb is
end count_tb;

architecture sim of count_tb is

    -- DUT interface signals
    signal i_clk    : std_logic := '0';
    signal i_rst    : std_logic := '0';
    signal o_count1 : std_logic_vector(7 downto 0);
    signal o_count2 : std_logic_vector(7 downto 0);
    signal o_count3 : std_logic_vector(7 downto 0);

begin
    -- DUT instantiation
    uut: entity work.counter
        port map (
            i_clk    => i_clk,
            i_rst    => i_rst,
            o_count1 => o_count1,
            o_count2 => o_count2,
            o_count3 => o_count3
        );

    -- Clock process (10ns period)
    clk_process: process
    begin
        while true loop
            i_clk <= '0';
            wait for 5 ns;
            i_clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initial reset
        i_rst <= '0';
        wait for 20 ns;
        i_rst <= '1';   -- release reset

        -- Observe counters running
        wait for 300 ns;

        -- Apply reset again
        --i_rst <= '0';
        wait for 20 ns;
        i_rst <= '1';

        -- Run more cycles
        wait for 300 ns;

        -- Stop simulation
        wait;
    end process;

end sim;
