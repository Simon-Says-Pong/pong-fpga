----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2026 16:14:23
-- Design Name: 
-- Module Name: ball_paddle - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.design_pkg.all;

entity ball_paddle is
    Port ( clk_pix    : in  STD_LOGIC;
           rst        : in  STD_LOGIC;                      -- from clk_gen, active high
           frame_tick : in  STD_LOGIC;                      -- 1-cycle pulse per frame (enable)
           btn_level  : in  STD_LOGIC_VECTOR (3 downto 0);  -- debounced, '1' while held
           state      : in  state_t;
           miss       : out miss_t;
           paddles_y  : out paddles_t;                      -- 0 = left, 1 = right
           ball_pos   : out pos_t);
end ball_paddle;

architecture Behavioral of ball_paddle is
signal ball_pos_d : pos_t := (x => (others => '0'), y => (others => '0')); -- TODO pass center position here as soon as screen is hooked!


begin
    process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            if rst = '1' then
                ball_pos_d <= (x => (others => '0'), y => (others => '0')); -- TODO centre
            elsif frame_tick = '1' then
                null; -- TODO once per frame: move paddles and ball
            end if;
        end if;
    end process;

    ball_pos <= ball_pos_d;
end Behavioral;
