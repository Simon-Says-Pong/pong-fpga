----------------------------------------------------------------------------------
-- tick_gen
--
-- Produces a one-clock-cycle pulse on tick every DIVIDER cycles of clk_pix.
-- Used as an enable (never as a clock), e.g. the shared 12 ms sample tick for
-- all btn_dbn instances: DIVIDER = 302_000 at 25.173 MHz.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity tick_gen is
    generic (DIVIDER : positive := 20);
    port ( clk_pix : in  std_logic;
           tick    : out std_logic := '0');
end tick_gen;

architecture Behavioral of tick_gen is
    signal counter : integer range 0 to DIVIDER - 1 := 0;
begin

process (clk_pix)
begin
    if rising_edge(clk_pix) then
        if counter = DIVIDER - 1 then
            counter <= 0;
            tick    <= '1';
        else
            counter <= counter + 1;
            tick    <= '0';
        end if;
    end if;
end process;

end Behavioral;
