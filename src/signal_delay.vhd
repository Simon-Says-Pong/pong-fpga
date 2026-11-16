----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 15.11.2026 03:27:00
-- Design Name:
-- Module Name: signal_delay - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description: Delays the video timing signals of vga_sync (pixel_pos, video_enable,
--              hsync, vsync) by STAGES clk_pix cycles, so they line up with the hit
--              signals of object_check and digit_check (both +2 clk) at the renderer.
--
-- Dependencies: design_pkg
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Generic stage count, also delays video_enable, hsync, vsync
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.design_pkg.all;

entity signal_delay is
    Port (
            clk_pix         : in std_logic;

            pixel_pos       : in pos_t;
            video_enable    : in std_logic;
            hsync           : in std_logic;
            vsync           : in std_logic;

            pixel_pos_o     : out pos_t;
            video_enable_o  : out std_logic;
            hsync_o         : out std_logic;
            vsync_o         : out std_logic
    );
end signal_delay;

architecture Behavioral of signal_delay is
    signal pos_pipe_d : pos_t := (others => (others => '0'));
    signal en_pipe_d  : std_logic := '0';
    
    -- syncs idle high
    signal hs_pipe_d  : std_logic := '1';  
    signal vs_pipe_d  : std_logic := '1';
begin

-- shift register concept
process(clk_pix)
begin
    if rising_edge(clk_pix) then
        -- Input Clock Cyclce - save Read Input
        pos_pipe_d <= pixel_pos;
        en_pipe_d  <= video_enable;
        hs_pipe_d  <= hsync;
        vs_pipe_d  <= vsync;
        
        -- Output Clock Cycle
        pixel_pos_o     <= pos_pipe_d;
        video_enable_o  <= en_pipe_d;
        hsync_o         <= hs_pipe_d;
        vsync_o         <= vs_pipe_d;
    end if;
end process;

end Behavioral;
