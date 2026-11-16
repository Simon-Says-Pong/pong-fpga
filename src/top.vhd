----------------------------------------------------------------------------------
-- Create Date: 11.11.2026 16:14:23
-- Module Name: top - Behavioral
-- Project Name: Pong on FPGA (Arty A7-35T + Pmod VGA)
-- Target Devices: xc7a35ticsg324-1L
-- Tool Versions: Vivado 2026.1
-- Description: Top level, only wiring (docs/graphs/02_module_wiring.mmd).
--
--   clk_gen      100 MHz -> clk_pix (25.173 MHz), synchronous reset
--   tick_gen     ~12 ms sample tick for the button debouncers
--   btn_dbn x4   btn_level ('1' while held) -> ball_paddle
--                btn_press (1-clock pulse)  -> OR of all four -> game_fsm
--   vga_sync     pixel counter, hsync/vsync, video_enable, frame_tick
--   game_fsm     state, score_l, score_r
--   ball_paddle  ball and paddle positions, miss
--   render path  object_check + digit_check (both +2 clk), signal_delay
--                delays pixel_pos/video_enable/hsync/vsync by the same 2 clk,
--                renderer registers colour and syncs together (+1 clk)
--
--   Pmod VGA: J1 (red, blue) in Pmod JB, J2 (green, hsync, vsync) in Pmod JC,
--   pins in constraints/arty_a7_35.xdc.
--
-- Dependencies: all modules in src/, clk_wiz_0 IP
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - All modules wired, VGA outputs
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.design_pkg.all;

entity top is
    Port ( CLK100MHZ : in  std_logic;
           ck_rst    : in  std_logic;                       -- red RESET button, active low
           btn       : in  std_logic_vector (3 downto 0);   -- BTN0..BTN3

           -- Pmod VGA
           vga_r     : out std_logic_vector (3 downto 0);
           vga_g     : out std_logic_vector (3 downto 0);
           vga_b     : out std_logic_vector (3 downto 0);
           vga_hs    : out std_logic;
           vga_vs    : out std_logic);
end top;

architecture Behavioral of top is
    -- clock, reset, buttons
    signal clk_pix     : std_logic;
    signal rst         : std_logic;
    signal sample_tick : std_logic;
    signal btn_level   : std_logic_vector(3 downto 0);
    signal btn_press   : std_logic_vector(3 downto 0);
    signal any_press   : std_logic;

    -- video timing (vga_sync)
    signal frame_tick   : std_logic;
    signal pixel_pos    : pos_t;
    signal video_enable : std_logic;
    signal hsync        : std_logic;
    signal vsync        : std_logic;

    -- video timing delayed by 2 clk (signal_delay)
    signal pixel_pos_d    : pos_t;
    signal video_enable_d : std_logic;
    signal hsync_d        : std_logic;
    signal vsync_d        : std_logic;

    -- game
    signal state        : state_t;
    signal score_l      : score_t;
    signal score_r      : score_t;
    signal miss         : miss_t;
    signal ball_pos     : pos_t;
    signal paddle_l_pos : pos_t;
    signal paddle_r_pos : pos_t;
    signal paddle_y     : posY_t;   -- object_check takes only the two y values

    -- hit signals (+2 clk)
    signal ball_hit   : std_logic;
    signal paddle_hit : std_logic;
    signal digit_hit  : std_logic;

    -- colours
    signal red, green, blue : rgb_t;
begin

    ------------------------------------------------------------------------------
    -- Clock and reset
    ------------------------------------------------------------------------------
    u_clk_gen : entity work.clk_gen
        port map (
            clk_100 => CLK100MHZ,
            rst_n   => ck_rst,
            clk_pix => clk_pix,
            rst     => rst
        );

    ------------------------------------------------------------------------------
    -- Buttons: one shared sample tick, one debouncer per button
    ------------------------------------------------------------------------------
    u_tick : entity work.tick_gen
        generic map (DIVIDER => 302_000)          -- 12 ms at 25.173 MHz
        port map (clk_pix => clk_pix, tick => sample_tick);

    gen_btn : for i in btn'range generate
        u_dbn : entity work.btn_dbn
            port map (
                clk         => clk_pix,
                sample_tick => sample_tick,
                btn_in      => btn(i),
                level       => btn_level(i),
                press       => btn_press(i)
            );
    end generate gen_btn;

    -- game_fsm reacts to any button
    any_press <= btn_press(0) or btn_press(1) or btn_press(2) or btn_press(3);

    ------------------------------------------------------------------------------
    -- Video timing
    ------------------------------------------------------------------------------
    u_vga_sync : entity work.vga_sync
        port map (
            clk_pix      => clk_pix,
            rst          => rst,
            frame_tick   => frame_tick,
            pixel_pos    => pixel_pos,
            video_enable => video_enable,
            vsync        => vsync,
            hsync        => hsync
        );

    ------------------------------------------------------------------------------
    -- Game logic
    ------------------------------------------------------------------------------
    u_game_fsm : entity work.game_fsm
        port map (
            clk_pix    => clk_pix,
            rst        => rst,
            miss       => miss,
            btn_press  => any_press,
            state      => state,
            score_l    => score_l,
            score_r    => score_r
        );

    u_ball_paddle : entity work.ball_paddle
        port map (
            clk_pix      => clk_pix,
            rst          => rst,
            frame_tick   => frame_tick,
            btn_level    => btn_level,
            state        => state,
            miss         => miss,
            ball_pos     => ball_pos,
            paddle_l_pos => paddle_l_pos,
            paddle_r_pos => paddle_r_pos
        );

    paddle_y <= (yL => paddle_l_pos.y, yR => paddle_r_pos.y);

    ------------------------------------------------------------------------------
    -- Render path: hit checks (+2 clk), matching delay, renderer (+1 clk)
    ------------------------------------------------------------------------------
    u_object_check : entity work.object_check
        port map (
            clk_pix    => clk_pix,
            pixel_pos  => pixel_pos,
            ball_pos   => ball_pos,
            paddle_pos => paddle_y,
            ball_hit   => ball_hit,
            paddle_hit => paddle_hit
        );

    u_digit_check : entity work.digit_check
        port map (
            clk_pix   => clk_pix,
            score_l   => score_l,
            score_r   => score_r,
            pixel_pos => pixel_pos,
            state     => state,
            digit_hit => digit_hit
        );

    u_signal_delay : entity work.signal_delay
        port map (
            clk_pix        => clk_pix,
            pixel_pos      => pixel_pos,
            video_enable   => video_enable,
            hsync          => hsync,
            vsync          => vsync,
            pixel_pos_o    => pixel_pos_d,
            video_enable_o => video_enable_d,
            hsync_o        => hsync_d,
            vsync_o        => vsync_d
        );

    u_renderer : entity work.renderer
        port map (
            clk_pix      => clk_pix,
            rst          => rst,
            video_enable => video_enable_d,
            pixel_pos    => pixel_pos_d,
            hsync_in     => hsync_d,
            vsync_in     => vsync_d,
            state_game   => state,
            ball_hit     => ball_hit,
            paddle_hit   => paddle_hit,
            digit_hit    => digit_hit,
            score_l      => score_l,
            score_r      => score_r,
            red          => red,
            green        => green,
            blue         => blue,
            hsync        => vga_hs,
            vsync        => vga_vs
        );

    vga_r <= std_logic_vector(red);
    vga_g <= std_logic_vector(green);
    vga_b <= std_logic_vector(blue);

end Behavioral;
