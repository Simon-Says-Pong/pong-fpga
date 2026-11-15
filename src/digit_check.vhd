----------------------------------------------------------------------------------
-- Description: Decides per pixel whether it belongs to one of the two score digits.
--              Each digit is a 10x10 bitmap from bitmap_pkg.DIGITS, scaled by
--              2**SHIFT (default 8x -> 80x80 pixels). Scaling is a bit shift, so
--              there are no dividers.
--
--              Latency: 2 clk_pix (same as object_check, matched by signal_delay)
--                clk 1: box check, bitmap row/column, select score
--                clk 2: one ROM read, AND with the box flag
--
-- Dependencies: design_pkg, bitmap_pkg
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Single DIGITS table, x8 scaling by shift, fixed mirrored digits
--                 and out-of-range row/column reads
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.design_pkg.all;
use work.bitmap_pkg.all;

entity digit_check is
    generic (
        -- scale factor = 2**SHIFT, digit size = 10 * 2**SHIFT (3 -> 8x -> 80x80)
        SHIFT  : natural := 3;

        -- top left corner of the digit boxes
        DB_Y1  : natural := 10;   -- both digits
        DLB_X1 : natural := 220;  -- left digit:  220..299
        DRB_X1 : natural := 340   -- right digit: 340..419
    );
    Port (
        clk_pix     : in std_logic;
        score_l     : in score_t;
        score_r     : in score_t;
        pixel_pos   : in pos_t;

        digit_hit   : out std_logic
    );
end digit_check;

architecture Behavioral of digit_check is
    constant D_SIZE : natural := 10 * 2**SHIFT;

    -- clk 1 results
    signal box_hit : std_logic := '0';
    signal sel     : natural range 0 to 9 := 0;  -- digit value to draw
    signal row     : natural range 0 to 9 := 0;  -- bitmap row, 0 = top
    signal col     : natural range 0 to 9 := 0;  -- bitmap column, 0 = left
begin

    -- clk 1: is the pixel inside a digit box, and which bitmap cell is it?
    locate : process(clk_pix)
        variable dx, dy : unsigned(9 downto 0);
    begin
        if rising_edge(clk_pix) then
            box_hit <= '0';

            if pixel_pos.y >= DB_Y1 and pixel_pos.y < DB_Y1 + D_SIZE then
                dy  := pixel_pos.y - DB_Y1;
                row <= to_integer(shift_right(dy, SHIFT));

                if pixel_pos.x >= DLB_X1 and pixel_pos.x < DLB_X1 + D_SIZE then
                    dx  := pixel_pos.x - DLB_X1;
                    col <= to_integer(shift_right(dx, SHIFT));
                    if score_l <= 9 then          -- only 0..9 have a bitmap
                        sel     <= to_integer(score_l);
                        box_hit <= '1';
                    end if;

                elsif pixel_pos.x >= DRB_X1 and pixel_pos.x < DRB_X1 + D_SIZE then
                    dx  := pixel_pos.x - DRB_X1;
                    col <= to_integer(shift_right(dx, SHIFT));
                    if score_r <= 9 then
                        sel     <= to_integer(score_r);
                        box_hit <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- clk 2: read the bit; bit 9 is the leftmost column of the bitmap strings
    lookup : process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            digit_hit <= box_hit and DIGITS(sel)(row)(9 - col);
        end if;
    end process;

end Behavioral;
