----------------------------------------------------------------------------------
-- Create Date: 11.11.2026 16:41:16
-- Module Name: renderer - Behavioral
-- Description: Chooses the colour of every pixel from the game state and the hit signals (+1 clk).
--
-- Revision:
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
-- renders the picture 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.design_pkg.all;



------------------------------------------------------
------------------------------------------------------
-- needs adapting -> was planned as the top level of the output processing 
------------------------------------------------------
------------------------------------------------------
entity renderer is
    port(
        clk_pix     : in std_logic;
        rst         : in std_logic;
        
        --video controlls, all delayed by signal_delay to match the hit signals (+2 clk)
        video_enable    : in std_logic;
        pixel_pos       : in pos_t;
        hsync_in        : in std_logic;
        vsync_in        : in std_logic;
        
        --Gane state
        state_game  : in state_t;
        ball_hit    : in std_logic;
        paddle_hit  : in std_logic;
        digit_hit   : in std_logic;
        score_l     : in score_t;
        score_r     : in score_t;
        
        --colour and sync output, registered together so they leave in the same cycle
        red         : out rgb_t;
        green       : out rgb_t;
        blue        : out rgb_t;
        hsync       : out std_logic;
        vsync       : out std_logic
    );
end renderer;

architecture Behavioral of renderer is
begin

    
print : process(clk_pix)
begin 
    if rising_edge(clk_pix) then
        -- syncs pass through the same register stage as the colours
        hsync   <= hsync_in;
        vsync   <= vsync_in;

        red     <= (others => '0');
        green   <= (others => '0');
        blue    <= (others => '0');
        
        if rst = '1' OR video_enable = '0' then 
            red     <= (others => '0');
            green   <= (others => '0');
            blue    <= (others => '0');
        else
            --Start Screen
            if state_game = start then 
                if digit_hit = '1' then 
                    if pixel_pos.y >= TITEL_Y and pixel_pos.y < TITEL_Y + DIGIT_BIG_PX then
                        if pixel_pos.x < MID then 
                            red     <= (others => '1');
                            green   <= (others => '0');
                            blue    <= (others => '0');
                        elsif pixel_pos.x > MID then
                            red     <= (others => '0');
                            green   <= (others => '0');
                            blue    <= (others => '1');
                        end if;
                    elsif pixel_pos.y >= SUBTITEL_Y and pixel_pos.y < SUBTITEL_Y + DIGIT_SMALL_PX then 
                            red     <= (others => '1');
                            green   <= (others => '1');
                            blue    <= (others => '1');
                    end if;
                else 
                    red     <= (others => '0');
                    green   <= (others => '0');
                    blue    <= (others => '0');
                end if;
            
            
            
            --Game Screen
            elsif state_game = game_init OR state_game = game_update OR state_game = game_rst then 
                if pixel_pos.x = MID then 
                    red     <= (others => '1');
                    green   <= (others => '1');
                    blue    <= (others => '1');
                    
                elsif digit_hit = '1' OR paddle_hit = '1' then 
                    if pixel_pos.x < MID then 
                        red     <= (others => '1');
                        green   <= (others => '0');
                        blue    <= (others => '0');
                    elsif pixel_pos.x > MID then
                        red     <= (others => '0');
                        green   <= (others => '0');
                        blue    <= (others => '1');
                    end if;
                    
                elsif ball_hit = '1' then 
                    red     <= (others => '1');
                    green   <= (others => '1');
                    blue    <= (others => '1');
                end if;
            
            --Final Screen 
            elsif state_game = final then 
                if digit_hit = '1' then
                    --if pixel_pos.y  --> height-dependent colour change
                        if score_l >= 3 then 
                            red     <= (others => '1');
                            green   <= (others => '0');
                            blue    <= (others => '0');
                        elsif score_r >= 3 then
                            red     <= (others => '0');
                            green   <= (others => '0');
                            blue    <= (others => '1');
                        end if;
                end if;
            end if;
        end if;
    end if;
end process;


end Behavioral;
