----------------------------------------------------------------------------------
-- Description: Decides per pixel whether it belongs to a score digit or to the start / end screen text (+2 clk).
--
-- The data in bitmap_pkg.DIGITS are three nested arrays, every index
-- narrows the selection down:
--      DIGITS                  all 10 digits              (10 x 10 x 10 bits)
--      DIGITS(n)               one single digit n (also called picture) (10 rows)
--      DIGITS(n)(row)          one row, e.g. "0000000111" (unsigned(9 downto 0))
--      DIGITS(n)(row)(bit)     one pixel, '0' or '1'
--      Example when using DIGITS(2):
--                     col ->  0 1 2 3 4 5 6 7 8 9
--                     bit ->  9 8 7 6 5 4 3 2 1 0
--      row 0  "0111111110"    . # # # # # # # # .
--      row 1  "1111111111"    # # # # # # # # # #
--      row 2  "1100000111"    # # . . . . . # # #
--      row 3  "0000000111"    . . . . . . . # # #
--      ...
--    
--    Watch the MSB / LSB order: the bits start at 9 instead of 0,
--    which is why the column is (9 - col). Reading it directly mirrors the digit
--    (the first version of this module did exactly that).
--
--    Screen layout, why 80x80?
--      x:      220      299        340      419
--      y=10    +--------+          +--------+
--              |  left  |  <-40->  | right  |   each box 80 x 80 px
--              | score  |  (mid    | score  |   = 10 x 10 cells of 8 x 8 px
--      y=89    +--------+  x=320)  +--------+
--    
--    The advantage is that every bit of a bitmap is simply 2**SHIFT x 2**SHIFT pixels.
--    So in our case, for 8x8, SHIFT = 3 (2^3). To find the bitmap bit of a pixel
--    we only divide its offset inside the box by 8 (bit shift right, SHIFT = 3). shift_right(dy, 3)
--    needs no extra hardware, it is only wiring - unlike a divider.
--    This approach was standard in almost all early games, including the original
--    Pong, because a /10 or /6 is very expensive in hardware.
--
-- Dependencies: design_pkg (pos_t, score_t), bitmap_pkg (DIGITS)
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Single DIGITS table, x8 scaling by shift, fixed mirrored digits
--                 and out-of-range row/column reads
-- Revision 0.03 - Explanatory comments
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.design_pkg.all;    -- pos_t (pixel_pos), score_t (scores)
use work.bitmap_pkg.all;    -- DIGITS (the 10 digit bitmaps)

entity digit_check is
    generic (
        -- Scale factor = 2**SHIFT. Digit size = 10 bitmap cells * 2**SHIFT pixels.
        -- SHIFT = 3 -> every bitmap bit is 8 x 8 pixels -> a digit is 80 x 80 pixels.
        -- SHIFT = 2 would give 40 x 40 digits.
        SHIFT_BIG   : natural := 3;
        SHIFT_SMALL : natural := 2;

        
        -- Top-left corner Positions for Digits - Score
        DB_Y1       : natural := 10;   
        DLB_X1      : natural := 220;  
        DRB_X1      : natural := 340; 
        
        -- Start position for Text
        PONG_X1         : natural  := 152;
        FINAL_X1        : natural  := 15;
        PRESSBUTT_X1    : natural  := 74
    );
    Port (
        clk_pix     : in std_logic;  
        score_l     : in score_t;    
        score_r     : in score_t;     
        pixel_pos   : in pos_t;  
        state       : in state_t;     

        digit_hit   : out std_logic );
end digit_check;

architecture Behavioral of digit_check is
    -- Side length of one box: 10 cells * 8 px = 80 px (2^3 * 10)
    constant D_SIZE : natural := 10 * 2**SHIFT_BIG;
    
    
    signal box_hit      : std_logic := '0';               
    signal sel_digit    : natural range 0 to 9 := 0;   
    signal sel_letter   : char_t := NONE;  
    signal row          : natural range 0 to 9 := 0;      -- bitmap row, 0 = top
    signal col          : natural range 0 to 9 := 0;      -- bitmap column, 0 = left
begin

    ------------------------------------------------------------------------------
    -- Clock 1: inside a digit box, and where exactly?
    ------------------------------------------------------------------------------
    locate : process(clk_pix)
        -- Offset of the pixel inside the box (0..79). 
        variable dx, dy : unsigned(9 downto 0);
    begin
        if rising_edge(clk_pix) then
            -- defaults
            box_hit     <= '0';
            sel_letter  <= NONE;
            row     <= 0;
            col     <= 0; 
            dx      := (others => '0');
            dy      := (others => '0');

            
            -- start screen
            if state = start then 
            
                ----------------------------------
                --Title : PONG                  --
                ----------------------------------
                if pixel_pos.y >= TITEL_Y AND pixel_pos.y < TITEL_Y + DIGIT_BIG_PX then 
                    dy  := pixel_pos.y - TITEL_Y;
                    -- Divide by 8 with a shift: 0..79 -> bitmap row 0..9
                    row <= to_integer(shift_right(dy, SHIFT_BIG));
                    
                    sel_letter <= P when (pixel_pos.x >= PONG_X1 and pixel_pos.x < PONG_X1 + DIGIT_BIG_PX);
                    sel_letter <= O when (pixel_pos.x >= PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 1) and pixel_pos.x < (PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 1)) + DIGIT_BIG_PX);
                    sel_letter <= N when (pixel_pos.x >= PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 2) and pixel_pos.x < (PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 2)) + DIGIT_BIG_PX);
                    sel_letter <= G when (pixel_pos.x >= PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 3) and pixel_pos.x < (PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 3)) + DIGIT_BIG_PX);
                    
                    -- Find the exact bit of the bitmap from the fixed letter position
                    for i in 0 to 4 loop 
                        dx := (pixel_pos.x - (PONG_X1 + (((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i)))) when 
                        (pixel_pos.x >= PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i) 
                        and pixel_pos.x < (PONG_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i)) + DIGIT_BIG_PX);
                    end loop;
                    
                    col <= to_integer(shift_right(dx, SHIFT_BIG));
                    box_hit <= '1';
                    
                ----------------------------------
                --Subtitle : PRESS START        --
                ----------------------------------
                elsif pixel_pos.y >= SUBTITEL_Y AND pixel_pos.y < SUBTITEL_Y + DIGIT_SMALL_PX then
                    dy  := pixel_pos.y - SUBTITEL_Y;
                    -- Divide by 4 with a shift: 0..39 -> bitmap row 0..9
                    row <= to_integer(shift_right(dy, SHIFT_SMALL));
                    
                    -- Select the letter from its fixed position
                    sel_letter <= P     when (pixel_pos.x >= PRESSBUTT_X1 and pixel_pos.x < PRESSBUTT_X1 + DIGIT_SMALL_PX);
                    sel_letter <= R     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 1) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 1)) + DIGIT_SMALL_PX);
                    sel_letter <= E     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 2) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 2)) + DIGIT_SMALL_PX);
                    sel_letter <= S     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 3) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 3)) + DIGIT_SMALL_PX);
                    sel_letter <= S     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 4) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 4)) + DIGIT_SMALL_PX);
                    sel_letter <= NONE  when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 5) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 5)) + DIGIT_SMALL_PX);
                    sel_letter <= S     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 6) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 6)) + DIGIT_SMALL_PX);
                    sel_letter <= T     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 7) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 7)) + DIGIT_SMALL_PX);
                    sel_letter <= A     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 8) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 8)) + DIGIT_SMALL_PX);
                    sel_letter <= R     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 9) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 9)) + DIGIT_SMALL_PX);
                    sel_letter <= T     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 10) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 10)) + DIGIT_SMALL_PX);
                    
                    -- Find the exact bit of the bitmap from the fixed letter position
                    for i in 0 to 10 loop 
                        dx := (pixel_pos.x - (PRESSBUTT_X1 + (((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * i)))) when 
                                (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * i) 
                                and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * i)) + DIGIT_SMALL_PX);
                    end loop;
                    
                    col <= to_integer(shift_right(dx, SHIFT_SMALL));
                    box_hit <= '1';
                end if;
                
                
                
            -- game screen
            elsif state = game_init OR state = game_update OR state = game_rst then 
    
                -- Are we at the right height? ("<" instead of "<=", otherwise row overflows)
                if pixel_pos.y >= DB_Y1 and pixel_pos.y < DB_Y1 + D_SIZE then
                    -- Offset from the top edge of the box: 0..79
                    dy  := pixel_pos.y - DB_Y1;
                    -- Divide by 8 with a shift: 0..79 -> bitmap row 0..9
                    row <= to_integer(shift_right(dy, SHIFT_BIG));
    
                    -- Left score box - DLB -> DIGIT LEFT BORDER
                    if pixel_pos.x >= DLB_X1 and pixel_pos.x < DLB_X1 + D_SIZE then
                        -- Offset from the left edge of the box: 0..79 -> column 0..9
                        dx  := pixel_pos.x - DLB_X1;
                        col <= to_integer(shift_right(dx, SHIFT_BIG));
                        
                        -- DIGITS only has 0..9.
                        if score_l <= 9 then
                            sel_digit     <= to_integer(score_l);   -- left score
                            box_hit <= '1';
                        end if;
    
                    -- Right score box -> DRB -> DIGIT RIGHT BORDER
                    elsif pixel_pos.x >= DRB_X1 and pixel_pos.x < DRB_X1 + D_SIZE then
                        dx  := pixel_pos.x - DRB_X1;
                        col <= to_integer(shift_right(dx, SHIFT_BIG));
                        if score_r <= 9 then
                            sel_digit     <= to_integer(score_r);   -- right score
                            box_hit <= '1';
                        end if;
                    end if;
                end if;
                
                
                
            -- final screen
            elsif state = final then 
                ----------------------------------
                --TITLE : BLUE WON              --
                ----------------------------------
                if pixel_pos.y >= TITEL_Y AND pixel_pos.y < TITEL_Y + DIGIT_BIG_PX then 
                    dy  := pixel_pos.y - TITEL_Y;
                    -- Divide by 8 with a shift: 0..79 -> bitmap row 0..9
                    row <= to_integer(shift_right(dy, SHIFT_BIG));
                    
                    if score_r >= 3 then 
                        sel_letter <= B when (pixel_pos.x >= FINAL_X1 and pixel_pos.x < FINAL_X1 + DIGIT_BIG_PX);
                        sel_letter <= L when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 1) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 1)) + DIGIT_BIG_PX);
                        sel_letter <= U when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 2) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 2)) + DIGIT_BIG_PX);
                        sel_letter <= E when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 3) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 3)) + DIGIT_BIG_PX);
                        sel_letter <= W when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 4) + (5 * DIGIT_SPACE_PX) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 4)) + DIGIT_BIG_PX + (5 * DIGIT_SPACE_PX));
                        sel_letter <= O when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 5) + (5 * DIGIT_SPACE_PX) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 5)) + DIGIT_BIG_PX + (5 * DIGIT_SPACE_PX));
                        sel_letter <= N when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 6) + (5 * DIGIT_SPACE_PX) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 6)) + DIGIT_BIG_PX + (5 * DIGIT_SPACE_PX));
                        
                        -- Find the exact bit of the bitmap from the fixed letter position
                        for i in 0 to 3 loop 
                            dx := (pixel_pos.x - (FINAL_X1 + (((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i)))) when 
                                    (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i) 
                                    and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i)) + DIGIT_BIG_PX);
                        end loop;
                        
                        -- Find the exact bit of the bitmap from the fixed letter position + gap
                        for i in 4 to 6 loop 
                            dx := (pixel_pos.x - (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i) + (5 * DIGIT_SPACE_PX))) when 
                                    (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i) + (5 * DIGIT_SPACE_PX) 
                                    and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i)) + DIGIT_BIG_PX + (5 * DIGIT_SPACE_PX));
                        end loop;
                        
                        
                    ----------------------------------
                    --TITLE : RED WON               --
                    ----------------------------------
                    elsif score_l >= 3 then
                        sel_letter <= R     when (pixel_pos.x >= FINAL_X1 and pixel_pos.x < FINAL_X1 + DIGIT_BIG_PX);
                        sel_letter <= E     when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 1) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 1)) + DIGIT_BIG_PX);
                        sel_letter <= D     when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 2) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 2)) + DIGIT_BIG_PX);
                        sel_letter <= NONE  when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 3) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 3)) + DIGIT_BIG_PX);
                        sel_letter <= W     when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 4) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 4)) + DIGIT_BIG_PX);
                        sel_letter <= O     when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 5) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 5)) + DIGIT_BIG_PX);
                        sel_letter <= N     when (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 6) and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * 6)) + DIGIT_BIG_PX);
                        
                        for i in 0 to 6 loop 
                            dx := (pixel_pos.x - (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i))) when 
                            (pixel_pos.x >= FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i) 
                            and pixel_pos.x < (FINAL_X1 + ((DIGIT_BIG_PX + DIGIT_SPACE_PX) * i)) + DIGIT_BIG_PX);
                        end loop;
                    end if;
                    
                    col <= to_integer(shift_right(dx, SHIFT_BIG)); 
                    box_hit <= '1';
                
                ----------------------------------
                --Subtitle : PRESS START        --
                ----------------------------------
                elsif pixel_pos.y >= SUBTITEL_Y AND pixel_pos.y < SUBTITEL_Y + DIGIT_SMALL_PX then
                    dy  := pixel_pos.y - SUBTITEL_Y;
                    -- Divide by 4 with a shift: 0..39 -> bitmap row 0..9
                    row <= to_integer(shift_right(dy, SHIFT_SMALL));
                    
                    sel_letter <= P     when (pixel_pos.x >= PRESSBUTT_X1 and pixel_pos.x < PRESSBUTT_X1 + DIGIT_SMALL_PX);
                    sel_letter <= R     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 1) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 1)) + DIGIT_SMALL_PX);
                    sel_letter <= E     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 2) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 2)) + DIGIT_SMALL_PX);
                    sel_letter <= S     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 3) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 3)) + DIGIT_SMALL_PX);
                    sel_letter <= S     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 4) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 4)) + DIGIT_SMALL_PX);
                    sel_letter <= NONE  when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 5) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 5)) + DIGIT_SMALL_PX);
                    sel_letter <= S     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 6) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 6)) + DIGIT_SMALL_PX);
                    sel_letter <= T     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 7) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 7)) + DIGIT_SMALL_PX);
                    sel_letter <= A     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 8) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 8)) + DIGIT_SMALL_PX);
                    sel_letter <= R     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 9) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 9)) + DIGIT_SMALL_PX);
                    sel_letter <= T     when (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 10) and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * 10)) + DIGIT_SMALL_PX);
                    
                    -- Find the exact bit of the bitmap from the fixed letter position
                    for i in 0 to 10 loop 
                        dx := (pixel_pos.x - (PRESSBUTT_X1 + (((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * i)))) when 
                                (pixel_pos.x >= PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * i) 
                                and pixel_pos.x < (PRESSBUTT_X1 + ((DIGIT_SMALL_PX + DIGIT_SPACE_PX) * i)) + DIGIT_SMALL_PX);
                    end loop;
                    col <= to_integer(shift_right(dx, SHIFT_SMALL));
                    box_hit <= '1';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- Clock 2: read the ROM and AND it with the box flag of the pixel
    ------------------------------------------------------------------------------
    lookup : process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            -- DIGITS(sel_digit)      -> picture of the digit
            --       (row)      -> one row
            --       (9 - col)  -> one pixel, MSB first
            -- AND box_hit      -> always 0 outside the boxes

            -- Show the score - digits
            if state = game_init OR state = game_update OR state = game_rst then 
                digit_hit <= box_hit and DIGITS(sel_digit)(row)(9 - col);
                
            -- Show the text - letters
            elsif state = final OR state = start then 
                digit_hit <= box_hit and LETTERS(sel_letter)(row)(9 - col);
            end if;

        end if;
    end process;

end Behavioral;
