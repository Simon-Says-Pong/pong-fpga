----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2026 16:41:16
-- Design Name: 
-- Module Name: renderer - Behavioral
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
--rendert das bild 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.design_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity renderer is
    port(
        clk_pix     : in std_logic;
        rst         : in std_logic;
        
        --output controlls
        video_enable    : in std_logic;
        pixel_pos       : in pos_t;
        
        --output select
        state_game  : in state_t;
        
        --score sign 
        score_l     : in score_t;
        score_r     : in score_t;
        
        --Object position
        ball_pos    : in pos_t;
        paddle_pos  : in pos_y_t;
       
        --colour output 
        red         : out rgb_t;
        green       : out rgb_t;
        blue        : out rgb_t
    );
end renderer;

architecture Behavioral of renderer is
    signal ball_pos_d : pos_t       := (others => (others => '0'));
    signal paddle_pos_d : pos_y_t   := (others => (others => '0'));
begin

    ball_pos_d      <= ball_pos;
    paddle_pos_d    <= paddle_pos;
    --prio building     paddle  ->    ball    --> digits

print : process(clk_pix)
begin 
    if rising_edge(clk_pix) then 
    
        if rst = '1' then 
            ball_pos_d      <= (others => (others => '0'));
            paddle_pos_d    <= (others => (others => '0'));
        end if;
        

        
        if pixel_pos.x = MID then
            red     <= (others => '1');
            green   <= (others => '1');
            blue    <= (others => '1');
        -- midle bar
        
        else
        
            if pixel_pos.x < MID then 
            --Check if there is a paddle or digit at the pixel
            --red side
            
            elsif pixel_pos.x > MID then 
            --Check if there is a paddle or digit at the pixel
            --blue side
            
            end if;
            
            --ball check positioning 
            
            
        end if;
    
    end if;
    




end process;

end Behavioral;
