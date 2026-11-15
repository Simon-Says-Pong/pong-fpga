----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2026 16:48:56
-- Design Name: 
-- Module Name: design_package - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package design_pkg is
-- suffix t for types!
type state_t    is (start, game_init, game_update, game_rst, final); -- gamestate enum
type pos_y_t    is array (1 downto 0) of unsigned(9 downto 0); -- y(10) and y(10)
type miss_t     is (none, left, right); -- miss type enum
subtype score_t is natural; -- score subtype
subtype rgb_t   is unsigned(3 downto 0); -- one colour channel of the Pmod VGA (4 bit)

-- screen coordinate of one object (ball): 10 bits cover 0..1023 (640 x 480)
type pos_t is record
    x : unsigned(9 downto 0);
    y : unsigned(9 downto 0);
end record;



-- y coordinate of both paddles: index 0 = left, 1 = right (x is fixed)
type paddles_t is array (0 to 1) of unsigned(9 downto 0);

-- VGA Timing constants 640x480 60Hz
constant HPIX   : INTEGER := 640;  -- Horizontal Display
constant HFP    : INTEGER := 16;   -- Horizontal Front porch
constant HBP    : INTEGER := 48;   -- Horizontal Back porch
constant HR     : INTEGER := 96;   -- Horizontal Retrace
constant HTOTAL : INTEGER := HPIX + HFP + HBP + HR;
constant VPIX   : INTEGER := 480;  -- Vertical Display
constant VFP    : INTEGER := 10;   -- Vertical Front porch
constant VBP    : INTEGER := 33;   -- Vertical Back porch
constant VR     : INTEGER := 2;    -- Vertical Retrace
constant VTOTAL : INTEGER := VPIX + VFP + VBP + VR; 
constant MID    : INTEGER := HPIX / 2;

type digit_table is array (9 downto 0) of unsigned(9 downto 0); 
-- when writing stepping from position to position 6x in x, 8x in y 
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



end package;