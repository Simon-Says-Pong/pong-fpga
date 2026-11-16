----------------------------------------------------------------------------------
-- okay proposition für die änderung die ich vorher meinte:
--
-- Daten in bitmap_pkg.DIGITS sind drei genestete arrays, wo jeder index 
-- die auswahl verschmählert:
--      DIGITS                  alle 10 digits             (10 x 10 x 10 bits)
--      DIGITS(n)               Ein einziges digit n (auch picture genannt) (10 rows)
--      DIGITS(n)(row)          eine row, e.g. "0000000111" (unsigned(9 downto 0))
--      DIGITS(n)(row)(bit)     ein pixel, '0' or '1'
--      Beispiel wenn man dann DIGITS(2) verwendet:
--                     col ->  0 1 2 3 4 5 6 7 8 9
--                     bit ->  9 8 7 6 5 4 3 2 1 0
--      row 0  "0111111110"    . # # # # # # # # .
--      row 1  "1111111111"    # # # # # # # # # #
--      row 2  "1100000111"    # # . . . . . # # #
--      row 3  "0000000111"    . . . . . . . # # #
--      ...
--    
--    Hier halt dann der BS mit MSB und LSB noch, wo die bits mit 9 anfangen anstatt null,
--    weswegen das column (9 - col) ist. Wenn man es direkt liest, dann ist es gespiegelt,
--    so wie es jetzt gerade ist glaube sogar.
--
--    Screenlayout, warum 80x80?
--      x:      220      299        340      419
--      y=10    +--------+          +--------+
--              |  left  |  <-40->  | right  |   jede box 80 x 80 px
--              | score  |  (mid    | score  |   = 10 x 10 cells of 8 x 8 px
--      y=89    +--------+  x=320)  +--------+
--    
--    Vorteil daran ist, dass jedes bit einer bitap dan einfach 2**SHIFT x 2**SHIFT ist.
--    Also in unserem fall für 8x8 dann SHIFT  = 3 (2^3). Wenn wir einen Pixel haben wollen,
--    müssen wir nur den Offset in der box mit 8 teilen (bit shift right SHIFT=3). shift_right(dy, 3)
--    wäre tatsächlich keine neue hardware sondern nur wiring. Im Gegensatz zu nem Divider.
--    Dieses vorgehen ist übrigens auch Standard für fast alle Games gewesen, inklusive dem originalem
--    Pong, da auch dort ein /10 oder /6 extrem teuer ist.
--
-- Dependencies: design_pkg (pos_t, score_t), bitmap_pkg (DIGITS)
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Single DIGITS table, x8 scaling by shift, fixed mirrored digits
--                 and out-of-range row/column reads
-- Revision 0.03 - Explanatory comments
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.design_pkg.all;    -- pos_t (pixel_pos), score_t (scores)
use work.bitmap_pkg.all;    -- DIGITS (the 10 digit bitmaps)

entity digit_check is
    generic (
        -- Scale factor = 2**SHIFT. Digit size = 10 bitmap cells * 2**SHIFT pixels.
        -- SHIFT = 3 -> jede bitmap bit is 8 x 8 pixels -> digit ist damit dann 80 x 80 pixels.
        -- SHIFT = 2 würde 40 x 40 digits bedeuten.
        SHIFT  : natural := 3;

        -- Top-left corner wie besprochen
        DB_Y1  : natural := 10;   
        DLB_X1 : natural := 220;  
        DRB_X1 : natural := 340  
    );
    Port (
        clk_pix     : in std_logic;  
        score_l     : in score_t;    
        score_r     : in score_t;     
        pixel_pos   : in pos_t;       

        digit_hit   : out std_logic );
end digit_check;

architecture Behavioral of digit_check is
    -- Seiten lönge einer einzigen Box: 10 cells * 8 px = 80px (2^3*10)
    constant D_SIZE : natural := 10 * 2**SHIFT;

  
    signal box_hit : std_logic := '0';               
    signal sel     : natural range 0 to 9 := 0;   
    signal row     : natural range 0 to 9 := 0;      -- bitmap row, 0 = top
    signal col     : natural range 0 to 9 := 0;      -- bitmap column, 0 = left
begin

    ------------------------------------------------------------------------------
    -- Clock 1: In der digit box und wo genau?
    ------------------------------------------------------------------------------
    locate : process(clk_pix)
        -- Offset des pixels in der box (0..79). 
        variable dx, dy : unsigned(9 downto 0);
    begin
        if rising_edge(clk_pix) then
            -- Default wie vorher auch
            box_hit <= '0';

            -- Sind wir auf der richtigen höhe (diesmal ohne <= weil overflow sonst)
            if pixel_pos.y >= DB_Y1 and pixel_pos.y < DB_Y1 + D_SIZE then
                -- Offset von der oberseite der box mit 0..79
                dy  := pixel_pos.y - DB_Y1;
                -- Teilen durch 8 mit shift: 0..79 -> bitmap row 0..9
                row <= to_integer(shift_right(dy, SHIFT));

                -- Linke box?
                if pixel_pos.x >= DLB_X1 and pixel_pos.x < DLB_X1 + D_SIZE then
                    -- Offset von der linken seite der box: 0..79 -> column 0..9
                    dx  := pixel_pos.x - DLB_X1;
                    col <= to_integer(shift_right(dx, SHIFT));
                    -- DIGITS kann nur 0..9. 
                    if score_l <= 9 then
                        sel     <= to_integer(score_l);   -- Linker score
                        box_hit <= '1';
                    end if;

                -- Rechte box?
                elsif pixel_pos.x >= DRB_X1 and pixel_pos.x < DRB_X1 + D_SIZE then
                    dx  := pixel_pos.x - DRB_X1;
                    col <= to_integer(shift_right(dx, SHIFT));
                    if score_r <= 9 then
                        sel     <= to_integer(score_r);   -- rechter score
                        box_hit <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- Clock 2: Lesen der ROM plus AND mit der flag des pixels
    ------------------------------------------------------------------------------
    lookup : process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            -- DIGITS(sel)      -> picture vom Digit
            --       (row)      -> eine row
            --       (9 - col)  -> ein pixel pixel, MSB format (cringe)
            -- AND box_hit      -> immer 0 wenn nicht in box
            digit_hit <= box_hit and DIGITS(sel)(row)(9 - col);
        end if;
    end process;

end Behavioral;
