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
library WORK;
use WORK.design_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_sync is
    Port ( clk_pix          : in STD_LOGIC;
           rst              : in std_logic;
    
           frame_tick       : out STD_LOGIC;
           pixel_pos        : out pos_t;
           video_enable     : out std_logic;
           vsync            : out std_logic;  --verticale synchronisierung
           hsync            : out std_logic); --horizontale synchronisierung 
end vga_sync;

architecture Behavioral of vga_sync is
signal pixel_x : unsigned(9 downto 0) := (others => '0');
signal pixel_y : unsigned(9 downto 0) := (others => '0');

begin
    --Pixel Counter 
    pixUpdate : process(clk_pix)
    begin 
        if rising_edge(clk_pix) then 
            --Horizontal
            if pixel_x < HTOTAL-1 then 
                pixel_x <= pixel_x + 1;
            elsif pixel_x = HTOTAL-1 then  
                pixel_x <= "0";
            end if;
            
            --Vertical
            if pixel_y < VTOTAL-1 then 
                pixel_y <= pixel_y + 1;
            elsif pixel_y = VTOTAL-1 then  
                pixel_y <= "0";
            end if;
            pixel_pos.x <= pixel_x;
            pixel_pos.y <= pixel_y;
        end if;
    end process;
    
    
    -- ~60Hz frame Tick & Sync
    SyncV : process(clk_pix)
    variable vsync_i : std_logic := '0';
    begin 
        if rising_edge(clk_pix) then 
            video_enable <= '1' when (pixel_x < HPIX and pixel_y < VPIX) else '0';
            hsync       <= '1' when (pixel_x = HTOTAL-1) else '0';
            vsync_i     := '1' when (pixel_x = HTOTAL-1 and pixel_y = VTOTAL-1) else '0';
            vsync       <= vsync_i;
            frame_tick  <= vsync_i;
        end if;
    end process;

end Behavioral;
