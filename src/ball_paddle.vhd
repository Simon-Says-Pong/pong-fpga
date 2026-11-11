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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ball_paddle is
    Port ( frame_tick : in STD_LOGIC;
           button_presses : in STD_LOGIC_VECTOR (3 downto 0);
           state : in STD_LOGIC_VECTOR (2 downto 0);
           miss : out STD_LOGIC;
           paddles_y : out STD_LOGIC_VECTOR (2 downto 0);
           ball_pos : out STD_LOGIC_VECTOR (2 downto 0));
end ball_paddle;

architecture Behavioral of ball_paddle is

begin


end Behavioral;
