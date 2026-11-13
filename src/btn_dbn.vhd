--------------------------------------------------------------------------------
-- btn_dbn
--
-- Synchroniser + debouncer for one push button (one instance per button).
--
-- 1. Two flip-flops bring the asynchronous button into the clk domain.
-- 2. The synchronised value is sampled only when sample_tick = '1'. The tick
--    comes from one shared tick_gen in top (every ~12 ms). Contact bounce is
--    shorter than that, so it can change the sample at most once.
-- 3. Outputs:
--      level : debounced button state, '1' while held  -> paddle movement
--      press : one-clock pulse when the button goes down -> start / serve
--
-- clk is the only clock; sample_tick is an enable, never a clock.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity btn_dbn is
    port (
        clk         : in  std_logic;  -- clk_pix
        sample_tick : in  std_logic;  -- 1-cycle pulse every ~12 ms from tick_gen
        btn_in      : in  std_logic;  -- raw button pin, active high
        level       : out std_logic;
        press       : out std_logic
    );
end entity btn_dbn;

architecture rtl of btn_dbn is

    signal sync1, sync2 : std_logic := '0';
    signal level_i      : std_logic := '0';
    signal level_d      : std_logic := '0';

begin

    process (clk)
    begin
        if rising_edge(clk) then
            -- 1. synchroniser (every clock)
            sync1 <= btn_in;
            sync2 <= sync1;

            -- 2. debounce: take a new sample only on the shared tick
            if sample_tick = '1' then
                level_i <= sync2;
            end if;

            -- 3. edge detection (every clock, so press lasts one cycle)
            level_d <= level_i;
        end if;
    end process;

    level <= level_i;
    press <= level_i and not level_d;

end architecture rtl;
