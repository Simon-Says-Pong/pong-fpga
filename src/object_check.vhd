----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.11.2026 16:30:50
-- Design Name: 
-- Module Name: object_check - Behavioral
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
library work;
use work.design_pkg.all;


entity object_check is
    Port ( 
        clk_pix     : in std_logic;
        frame_tick  : in std_logic;
        
        pixel_pos   : in pos_t;
        ball_pos    : in pos_t;
        paddle_pos  : in posY_t;
        
        ball_hit    : out std_logic;
        paddle_hit  : out std_logic
    );
end object_check;

architecture Behavioral of object_check is
    signal pixel_pos_d  : pos_t := (others => (others => '0'));
    
    -- TLC -> Top Left Corner ---- BRC --> Bottom Right Corner (exclusive: first pixel after the ball)
    signal ball_TLC     : pos_t := (others => (others => '0'));
    signal ball_BRC     : pos_t := (others => (others => '0')); 
    signal paddle_BY    : posY_t := (others => (others => '0')); --BY -> bottom y
    signal paddle_TY    : posY_t := (others => (others => '0'));
begin

--calculate new positiona --> possible sync with frame_tick / vsync --> be carefull with synchronisation
calcBorders : process(clk_pix)
begin 
    if rising_edge(clk_pix) then 
        pixel_pos_d <= pixel_pos;
        --if frame_tick = '1' then
            --Ball area
            ball_TLC        <= ball_pos;
            ball_BRC.x      <= ball_pos.x + BALL_WIDTH;
            ball_BRC.y      <= ball_pos.y + BALL_HIGHT;
            
            --Paddle left area
            paddle_TY       <= paddle_pos;
            paddle_BY.yL    <= paddle_pos.yL + PADDLE_HIGHT;
            paddle_BY.yR    <= paddle_pos.yR + PADDLE_HIGHT;
        --end if;
    end if;
end process;

--Checking if pixel hits Paddle or Ball Area --> delayed by 2 clk_pix (pixel_pos_d + output register),
--same latency as digit_check, so both hit signals reach the renderer in the same cycle
checkHit : process(clk_pix)
begin
    if rising_edge(clk_pix) then
    
        --Default Values
        ball_hit    <= '0';
        paddle_hit  <= '0';

        -- Ball hit check - Is there a Ball at this position?
        if pixel_pos_d.x >= ball_TLC.x and pixel_pos_d.x < ball_BRC.x
            and pixel_pos_d.y >= ball_TLC.y and pixel_pos_d.y < ball_BRC.y then
           ball_hit <= '1';
        end if;

        -- Paddle Left Hit Check - Is there a Paddle at this position?
        if pixel_pos_d.x >= PADDLE_L_X1 and pixel_pos_d.x < PADDLE_L_X2
            and pixel_pos_d.y >= paddle_TY.yL and pixel_pos_d.y < paddle_BY.yL then
           paddle_hit <= '1';
        end if;

        -- Paddle Right Hit Check- Is there a Paddle at this position?
        if pixel_pos_d.x >= PADDLE_R_X1 and pixel_pos_d.x < PADDLE_R_X2
            and pixel_pos_d.y >= paddle_TY.yR and pixel_pos_d.y < paddle_BY.yR then
           paddle_hit <= '1';
        end if;
    end if; 
end process;

end Behavioral;
