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
    generic (
        STAGES : positive := 2  -- = latency of the slowest hit check (digit_check)
    );
    Port (
            clk_pix         : in std_logic;

            pixel_pos       : in pos_t;
            video_enable    : in std_logic;
            hsync           : in std_logic;
            vsync           : in std_logic;

            pixel_pos_d     : out pos_t;
            video_enable_d  : out std_logic;
            hsync_d         : out std_logic;
            vsync_d         : out std_logic
    );
end signal_delay;

architecture Behavioral of signal_delay is
    type pos_pipe_t is array (1 to STAGES) of pos_t;

    signal pos_pipe : pos_pipe_t := (others => (others => (others => '0')));
    signal en_pipe  : std_logic_vector(1 to STAGES) := (others => '0');
    signal hs_pipe  : std_logic_vector(1 to STAGES) := (others => '1');  -- syncs idle high
    signal vs_pipe  : std_logic_vector(1 to STAGES) := (others => '1');
begin

-- shift register: stage 1 takes the input, every further stage takes the previous one
process(clk_pix)
begin
    if rising_edge(clk_pix) then
        pos_pipe(1) <= pixel_pos;
        en_pipe(1)  <= video_enable;
        hs_pipe(1)  <= hsync;
        vs_pipe(1)  <= vsync;

        for i in 2 to STAGES loop
            pos_pipe(i) <= pos_pipe(i-1);
            en_pipe(i)  <= en_pipe(i-1);
            hs_pipe(i)  <= hs_pipe(i-1);
            vs_pipe(i)  <= vs_pipe(i-1);
        end loop;
    end if;
end process;

pixel_pos_d     <= pos_pipe(STAGES);
video_enable_d  <= en_pipe(STAGES);
hsync_d         <= hs_pipe(STAGES);
vsync_d         <= vs_pipe(STAGES);

end Behavioral;
