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
type state_t is (start, game_init, game_update, game_rst, final); -- gamestate enum
type position_t is array (1 downto 0) of unsigned(9 downto 0); -- x(10) and y(10)
type miss_t is (none, left, right); -- miss type enum
subtype score_t is unsigned(1 downto 0); -- score subtype
subtype rgb_t is unsigned(3 downto 0); -- one colour channel of the Pmod VGA (4 bit)

-- screen coordinate of one object (ball): 10 bits cover 0..1023 (640 x 480)
type pos_t is record
    x : unsigned(9 downto 0);
    y : unsigned(9 downto 0);
end record;

-- y coordinate of both paddles: index 0 = left, 1 = right (x is fixed)
type paddles_t is array (0 to 1) of unsigned(9 downto 0);

end package;