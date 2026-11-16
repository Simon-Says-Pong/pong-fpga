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
--bestimmt und controlled welcher pixel generiert wird 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
library WORK;
use WORK.design_pkg.all;

entity vga_sync is
    Port ( clk_pix          : in STD_LOGIC;
           rst              : in std_logic;
    
           frame_tick       : out STD_LOGIC;
           pixel_pos        : out pos_t;
           video_enable     : out std_logic;
           vsync            : out std_logic;  --verticale synchronisierung
           hsync            : out std_logic); --horizontale synchronisierung 
end vga_sync;

------------------------------------
--Sychnonization of the pixel output for VGA by horizontal end and vertical end.
------------------------------------
architecture Behavioral of vga_sync is
signal pixel_x : unsigned(9 downto 0) := (others => '0');
signal pixel_y : unsigned(9 downto 0) := (others => '0');

begin
    --Pixel Counter --> where we write next
    pixUpdate : process(clk_pix)
    begin 
        if rising_edge(clk_pix) then 
            if rst = '1' then 
                pixel_x <= (others => '0');
                pixel_y <= (others => '0');
            else 
                --Horizontal
                if pixel_x < HTOTAL-1 then 
                    pixel_x <= pixel_x + 1;
                elsif pixel_x = HTOTAL-1 then  
                    pixel_x <= (others => '0');
                end if;
                
                --Vertical
                if pixel_x = HTOTAL-1 then 
                    if pixel_y < VTOTAL-1 then 
                        pixel_y <= pixel_y + 1;
                    elsif pixel_y = VTOTAL-1 then  
                        pixel_y <= (others => '0');
                    end if;
                end if;
            end if;
            
            pixel_pos.x <= pixel_x;
            pixel_pos.y <= pixel_y;
        end if;
    end process;
    
    
    -- ~60Hz frame Tick & Sync
    SyncV : process(clk_pix)
    begin 
        if rising_edge(clk_pix) then 
            -- defaults
            hsync <= '1';
            vsync <= '1';
            
            if rst = '1' then 
                video_enable <= '0';
            else
                video_enable    <= '1' when (pixel_x < HPIX and pixel_y < VPIX)         else '0';
                frame_tick      <= '1' when (pixel_x = HTOTAL-1 and pixel_y = VTOTAL-1) else '0';
                
                -- Sync pulses: START <= counter < END (END exclusive).
                -- hsync/vsync are registered from pixel_x/pixel_y in the same clock as
                -- pixel_pos, so no -1 correction is needed. The old bounds
                -- (START-1 .. END-1 / START-1 .. END) gave 97 clk hsync and 4-line vsync,
                -- the standard is 96 clk (HR) and 2 lines (VR).

                --Check for Horizontal x-Area Sync-Signal
                if pixel_x >= START_HSYNC and pixel_x < END_HSYNC then
                    hsync <= '0';
                end if;

                --Check for Vertical y-Area Sync-Signal
                if pixel_y >= START_VSYNC and pixel_y < END_VSYNC then
                    vsync <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
