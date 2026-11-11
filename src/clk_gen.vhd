--------------------------------------------------------------------------------
-- clk_gen
--
-- Pixel clock and system reset for the whole design.
--
-- * clk_wiz_0 (Clocking Wizard IP, MMCM) turns the 100 MHz board clock into the
--   VGA pixel clock: 100 MHz / 4 * 36.375 / 36.125 = 25.173 MHz
--   (640x480 @ 60 Hz nominal: 25.175 MHz).
-- * The red RESET button (ck_rst, active low) resets the MMCM. While the MMCM is
--   resetting or not yet locked, rst stays '1'.
-- * rst is asserted immediately when locked drops (asynchronously) and released
--   synchronously to clk_pix after two clock edges, so every flip-flop leaves
--   reset in the same clock cycle.
--
-- Everything else in the design runs on clk_pix and uses rst as its reset.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity clk_gen is
    port (
        clk_100 : in  std_logic;  -- 100 MHz board oscillator (pin E3)
        rst_n   : in  std_logic;  -- RESET button, active low (pin C2)
        clk_pix : out std_logic;  -- 25.173 MHz pixel / system clock
        rst     : out std_logic   -- active-high reset, synchronous to clk_pix
    );
end entity clk_gen;

architecture rtl of clk_gen is
    component clk_wiz_0
        port (
            clk_out1 : out std_logic;
            resetn   : in  std_logic;
            locked   : out std_logic;
            clk_in1  : in  std_logic
        );
    end component;

    signal clk_pix_i : std_logic;
    signal locked    : std_logic;

    -- reset synchroniser: two flip-flops, start in reset after configuration
    signal rst_ff    : std_logic_vector(1 downto 0) := (others => '1');

begin

    u_clk_wiz : clk_wiz_0
        port map (
            clk_out1 => clk_pix_i,
            resetn   => rst_n,
            locked   => locked,
            clk_in1  => clk_100
        );

    -- Asynchronous assert, synchronous release
    process (clk_pix_i, locked)
    begin
        if locked = '0' then
            rst_ff <= (others => '1');
        elsif rising_edge(clk_pix_i) then
            rst_ff <= rst_ff(0) & '0';
        end if;
    end process;

    clk_pix <= clk_pix_i;
    rst     <= rst_ff(1);

end architecture rtl;
