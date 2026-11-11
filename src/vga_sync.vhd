----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2026 16:11:57
-- Design Name: 
-- Module Name: vga_sync - Behavioral
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
--bestimmt und controlled welcher pixel generirtz wird 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
library work;
use work.design_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_sync is
    Port ( clk_pix          : in STD_LOGIC;
           rst              : in std_logic;
    
           frame_tick       : out STD_LOGIC;
           pixel_pos        : out position;
           video_enable     : out std_logic;
           vsync            : out std_logic;  --verticale synchronisierung
           hsync            : out std_logic); --horizontale synchronisierung 
end vga_sync;

architecture Behavioral of vga_sync is
signal pixel_x : unsigned(9 downto 0) := "0";
signal pixel_y : unsigned(9 downto 0) := "0";
signal frame_tick_o : std_logic := '0';
begin

printPicture : process(clk_pix) is
begin
    if rising_edge(clk_pix) then 
        if rst = '1' then
            pixel_x <= "0";
            pixel_y <= "0";
        
        end if;
    end if;

pixel_pos(0) <= pixel_x;
pixel_pos(1) <= pixel_y;
end process printPicture;

frame_tick : process(clk_pix) is
begin
    if rising_edge(clk_pix) then 
        if rst = '1' then
            pixel_x <= "0";
            pixel_y <= "0";
        
        end if;


pixel_pos(0) <= pixel_x;
pixel_pos(1) <= pixel_y;
end process printPicture;

end Behavioral;
