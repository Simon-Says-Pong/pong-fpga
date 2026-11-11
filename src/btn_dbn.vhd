--------------------------------------------------------------------------------
-- btn_dbn
--
-- Synchroniser + debouncer for one push button (one instance per button).
--
-- 1. Two flip-flops bring the asynchronous button into the clk domain.
-- 2. The synchronised value is sampled only every DEBOUNCE_CYCLES clocks
--    (default 250_000 at 25.173 MHz = about 10 ms). Contact bounce is shorter
--    than that, so it can change the sample at most once.
-- 3. Outputs:
--      level : debounced button state, '1' while held  -> paddle movement
--      press : one-clock pulse when the button goes down -> start / serve
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity btn_dbn is
    generic (
        DEBOUNCE_CYCLES : positive := 250_000  -- sample period in clk cycles
    );
    port (
        clk    : in  std_logic;
        btn_in : in  std_logic;  -- raw button pin, active high
        level  : out std_logic;
        press  : out std_logic
    );
end entity btn_dbn;

architecture rtl of btn_dbn is

    signal sync1, sync2 : std_logic := '0';
    signal cnt          : integer range 0 to DEBOUNCE_CYCLES - 1 := 0;
    signal level_i      : std_logic := '0';
    signal level_prev   : std_logic := '0';

begin

    process (clk)
    begin
        if rising_edge(clk) then
            -- 1. synchroniser (every clock)
            sync1 <= btn_in;
            sync2 <= sync1;

            -- 2. sample the synchronised input once per debounce period
            if cnt = DEBOUNCE_CYCLES - 1 then
                cnt     <= 0;
                level_i <= sync2;
            else
                cnt <= cnt + 1;
            end if;

            -- 3. edge detection on the debounced level
            level_prev <= level_i;
        end if;
    end process;

    level <= level_i;
    press <= level_i and not level_prev;

end architecture rtl;
