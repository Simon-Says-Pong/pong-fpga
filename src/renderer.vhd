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
library work;
use work.design_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

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
        pixel_pos       : in position;
        
        --output select
        state_game  : in state_g;
        
        --score sign 
        score_l     : in score;
        score_r     : in score;
        
        --Object position
        ball_pos    : in position;
        paddle_pos  : in position;
       
        --colour output 
        red_o       : out rgb_out;
        green_o     : out rgb_out;
        blue_o      : out rgb_out
    );
end renderer;

architecture Behavioral of renderer is

begin


end Behavioral;
