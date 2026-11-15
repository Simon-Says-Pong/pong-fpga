
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package design_pkg is
    -- suffix t for types!
    type state_t    is (start, game_init, game_update, game_rst, final); -- gamestate enum
    type miss_t     is (none, left, right); -- miss type enum
    subtype score_t is unsigned(5 downto 0); -- score subtype
    subtype rgb_t   is unsigned(3 downto 0); -- one colour channel of the Pmod VGA (4 bit)
    
    -- screen coordinate of one object (ball): 10 bits cover 0..1023 (640 x 480)
    type pos_t is record
        x : unsigned(9 downto 0);
        y : unsigned(9 downto 0);
    end record;
    
    type posY_t is record
        yL : unsigned(9 downto 0);
        yR : unsigned(9 downto 0);
    end record;
    
    -- y coordinate of both paddles: index 0 = left, 1 = right (x is fixed)
    type paddles_t is array (0 to 1) of unsigned(9 downto 0);
    
    --Paddle AND Ball definition
    constant BALL_WIDTH     : NATURAL := 12;
    constant BALL_HIGHT     : NATURAL := 12;
    
    constant PADDLE_WIDTH   : NATURAL := 10;
    constant PADDLE_HIGHT   : NATURAL := 60;
    -- X1 = first pixel of the paddle, X2 = first pixel AFTER it (exclusive),
    -- so a paddle covers X1 .. X2-1 = exactly PADDLE_WIDTH pixels -> compare with '<' X2
    constant PADDLE_L_X1    : NATURAL := 8;
    constant PADDLE_L_X2    : NATURAL := PADDLE_L_X1 + PADDLE_WIDTH;
    constant PADDLE_R_X1    : NATURAL := 622;  -- 640 - 8 - 10: same 8 px gap to the edge as the left paddle
    constant PADDLE_R_X2    : NATURAL := PADDLE_R_X1 + PADDLE_WIDTH;


    -- VGA Timing constants 640x480 60Hz
    constant HPIX   : NATURAL := 640;  -- Horizontal Display
    constant HFP    : NATURAL := 16;   -- Horizontal Front porch
    constant HR     : NATURAL := 96;   -- Horizontal Retrace
    constant HBP    : NATURAL := 48;   -- Horizontal Back porch
    constant HTOTAL : NATURAL := HPIX + HFP + HBP + HR;
    
    constant VPIX   : NATURAL := 480;  -- Vertical Display
    constant VFP    : NATURAL := 10;   -- Vertical Front porch
    constant VR     : NATURAL := 2;    -- Vertical Retrace
    constant VBP    : NATURAL := 33;   -- Vertical Back porch
    constant VTOTAL : NATURAL := VPIX + VFP + VBP + VR; 
    
    constant MID            : NATURAL := HPIX / 2;
    constant START_HSYNC    : NATURAL := HPIX + HFP;
    constant END_HSYNC      : NATURAL := HPIX + HFP + HR;
    constant START_VSYNC    : NATURAL := VPIX + VFP;
    constant END_VSYNC      : NATURAL := VPIX + VFP + VR;

    -- Game movement (per frame, i.e. 60 times per second)
    -- keep BALL_SPEED <= PADDLE_WIDTH, otherwise the ball can jump over a paddle in one frame
    constant BALL_SPEED     : NATURAL := 3;   -- px per frame in x AND y -> 45 degree path
    constant PADDLE_SPEED   : NATURAL := 4;   -- px per frame while the button is held

    -- Start positions for game_init (top-left corners, so the objects appear centred)
    constant BALL_X0        : NATURAL := (HPIX - BALL_WIDTH) / 2;    -- 314
    constant BALL_Y0        : NATURAL := (VPIX - BALL_HIGHT) / 2;    -- 234
    constant PADDLE_Y0      : NATURAL := (VPIX - PADDLE_HIGHT) / 2;  -- 210

end package;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package bitmap_pkg is 
    type digit_table is array (9 downto 0) of unsigned(9 downto 0); 
    -- when writing stepping from position to position 6x in x, 8x in y 
    
    -- 0
    constant digit_0 : digit_table := (
        0 => "0011111100",
        1 => "0111111110",
        2 => "1110000111",
        3 => "1100000011",
        4 => "1100000011",
        5 => "1100000011",
        6 => "1100000011",
        7 => "1110000111",
        8 => "0111111110",
        9 => "0011111100"
    );
    -- 1
    constant digit_1 : digit_table := (
        0 => "0000110000",
        1 => "0001110000",
        2 => "0011110000",
        3 => "0000110000",
        4 => "0000110000",
        5 => "0000110000",
        6 => "0000110000",
        7 => "0000110000",
        8 => "0011111100",
        9 => "0011111100"
    );
    -- 2
    constant digit_2 : digit_table := (
        0 => "0111111110",
        1 => "1111111111",
        2 => "1100000111",
        3 => "0000000111",
        4 => "0000011110",
        5 => "0001111000",
        6 => "0111100000",
        7 => "1110000000",
        8 => "1111111111",
        9 => "1111111111"
    );
    -- 3
    constant digit_3 : digit_table := (
        0 => "1111111110",
        1 => "1111111111",
        2 => "0000000111",
        3 => "0000000111",
        4 => "0011111110",
        5 => "0011111110",
        6 => "0000000111",
        7 => "0000000111",
        8 => "1111111111",
        9 => "1111111110"
    );
    -- 4
    constant digit_4 : digit_table := (
        0 => "0000011110",
        1 => "0000111110",
        2 => "0001111110",
        3 => "0011001110",
        4 => "0110001110",
        5 => "1111111111",
        6 => "1111111111",
        7 => "0000001110",
        8 => "0000001110",
        9 => "0000001110"
    );
    -- 5
    constant digit_5 : digit_table := (
        0 => "1111111111",
        1 => "1111111111",
        2 => "1110000000",
        3 => "1110000000",
        4 => "1111111110",
        5 => "1111111111",
        6 => "0000000111",
        7 => "0000000111",
        8 => "1111111111",
        9 => "1111111110"
    );
    -- 6
    constant digit_6 : digit_table := (
        0 => "0011111110",
        1 => "0111111111",
        2 => "1110000000",
        3 => "1110000000",
        4 => "1111111110",
        5 => "1111111111",
        6 => "1110000111",
        7 => "1110000111",
        8 => "0111111111",
        9 => "0011111110"
    );
    -- 7
    constant digit_7 : digit_table := (
        0 => "1111111111",
        1 => "1111111111",
        2 => "0000000111",
        3 => "0000001110",
        4 => "0000011100",
        5 => "0000111000",
        6 => "0001110000",
        7 => "0001110000",
        8 => "0001110000",
        9 => "0001110000"
    );
    -- 8
    constant digit_8 : digit_table := (
        0 => "0111111110",
        1 => "1111111111",
        2 => "1110000111",
        3 => "1110000111",
        4 => "0111111110",
        5 => "0111111110",
        6 => "1110000111",
        7 => "1110000111",
        8 => "1111111111",
        9 => "0111111110"
    );
    -- 9 
    constant digit_9 : digit_table := (
        0 => "0111111110",
        1 => "1111111111",
        2 => "1110000111",
        3 => "1110000111",
        4 => "1111111111",
        5 => "0111111111",
        6 => "0000000111",
        7 => "0000000111",
        8 => "1111111110",
        9 => "0111111100"
    );
    

    -- A
    constant letter_A : digit_table := (
        0 => "0011111100",
        1 => "0111111110",
        2 => "1110000111",
        3 => "1100000011",
        4 => "1100000011",
        5 => "1111111111",
        6 => "1111111111",
        7 => "1100000011",
        8 => "1100000011",
        9 => "1100000011"
    );
    
    -- B
    constant letter_B : digit_table := (
        0 => "1111111100",
        1 => "1111111110",
        2 => "1100000111",
        3 => "1100000111",
        4 => "1111111110",
        5 => "1111111110",
        6 => "1100000111",
        7 => "1100000011",
        8 => "1111111110",
        9 => "1111111100"
    );
    
    -- D
    constant letter_D : digit_table := (
        0 => "1111111000",
        1 => "1111111110",
        2 => "1100000111",
        3 => "1100000011",
        4 => "1100000011",
        5 => "1100000011",
        6 => "1100000011",
        7 => "1100000111",
        8 => "1111111110",
        9 => "1111111000"
    );
    
    -- E
    constant letter_E : digit_table := (
        0 => "1111111111",
        1 => "1111111111",
        2 => "1100000000",
        3 => "1100000000",
        4 => "1111111100",
        5 => "1111111100",
        6 => "1100000000",
        7 => "1100000000",
        8 => "1111111111",
        9 => "1111111111"
    );
    
    -- G
    constant letter_G : digit_table := (
        0 => "0011111100",
        1 => "0111111110",
        2 => "1110000111",
        3 => "1100000000",
        4 => "1100000000",
        5 => "1100011111",
        6 => "1100000011",
        7 => "1110000011",
        8 => "0111111111",
        9 => "0011111110"
    );
    
    -- I
    constant letter_I : digit_table := (
        0 => "1111111111",
        1 => "1111111111",
        2 => "0000110000",
        3 => "0000110000",
        4 => "0000110000",
        5 => "0000110000",
        6 => "0000110000",
        7 => "0000110000",
        8 => "1111111111",
        9 => "1111111111"
    );
    
    -- L
    constant letter_L : digit_table := (
        0 => "1100000000",
        1 => "1100000000",
        2 => "1100000000",
        3 => "1100000000",
        4 => "1100000000",
        5 => "1100000000",
        6 => "1100000000",
        7 => "1100000000",
        8 => "1111111111",
        9 => "1111111111"
    );
    
    -- N
    constant letter_N : digit_table := (
        0 => "1110000011",
        1 => "1111000011",
        2 => "1101100011",
        3 => "1101100011",
        4 => "1100110011",
        5 => "1100110011",
        6 => "1100011011",
        7 => "1100011011",
        8 => "1100001111",
        9 => "1100001111"
    );
    
    -- O (same bitmap as digit_0)
    constant letter_O : digit_table := (
        0 => "0011111100",
        1 => "0111111110",
        2 => "1110000111",
        3 => "1100000011",
        4 => "1100000011",
        5 => "1100000011",
        6 => "1100000011",
        7 => "1110000111",
        8 => "0111111110",
        9 => "0011111100"
    );
    
    -- P
    constant letter_P : digit_table := (
        0 => "1111111100",
        1 => "1111111110",
        2 => "1100000111",
        3 => "1100000011",
        4 => "1100000111",
        5 => "1111111110",
        6 => "1111111100",
        7 => "1100000000",
        8 => "1100000000",
        9 => "1100000000"
    );
    
    -- R
    constant letter_R : digit_table := (
        0 => "1111111100",
        1 => "1111111110",
        2 => "1100000111",
        3 => "1100000011",
        4 => "1100000111",
        5 => "1111111110",
        6 => "1111111100",
        7 => "1100011000",
        8 => "1100001100",
        9 => "1100000111"
    );
    
    -- S
    constant letter_S : digit_table := (
        0 => "0011111110",
        1 => "0111111111",
        2 => "1110000000",
        3 => "1100000000",
        4 => "1111111100",
        5 => "0111111110",
        6 => "0000000111",
        7 => "0000000011",
        8 => "1111111110",
        9 => "0111111100"
    );
    
    -- T
    constant letter_T : digit_table := (
        0 => "1111111111",
        1 => "1111111111",
        2 => "0000110000",
        3 => "0000110000",
        4 => "0000110000",
        5 => "0000110000",
        6 => "0000110000",
        7 => "0000110000",
        8 => "0000110000",
        9 => "0000110000"
    );
    
    -- U
    constant letter_U : digit_table := (
        0 => "1100000011",
        1 => "1100000011",
        2 => "1100000011",
        3 => "1100000011",
        4 => "1100000011",
        5 => "1100000011",
        6 => "1100000011",
        7 => "1110000111",
        8 => "0111111110",
        9 => "0011111100"
    );
    
    -- W
    constant letter_W : digit_table := (
        0 => "1100000011",
        1 => "1100000011",
        2 => "1100000011",
        3 => "1100000011",
        4 => "1100110011",
        5 => "1100110011",
        6 => "1101111011",
        7 => "1111111111",
        8 => "1111111111",
        9 => "0111001110"
    );
    
    -- Exclamation mark (!)
    constant letter_EXCL : digit_table := (
        0 => "0000110000",
        1 => "0000110000",
        2 => "0000110000",
        3 => "0000110000",
        4 => "0000110000",
        5 => "0000110000",
        6 => "0000110000",
        7 => "0000000000",
        8 => "0000110000",
        9 => "0000110000"
    );

-- Space
constant letter_SPACE : digit_table :=
    (others => (others => '0'));

end package;