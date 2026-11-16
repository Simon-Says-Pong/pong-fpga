----------------------------------------------------------------------------------
-- Create Date: 11.11.2026 16:07:49
-- Module Name: game_fsm - Behavioral
-- Description: Game state machine and score counters (docs/graphs/01_game_fsm.mmd).
--
--   start ──btn──> game_init ──btn──> game_update ──miss──> game_rst
--     ^                ^                                       │
--     │                └────────── game not over ──────────────┤
--     └──── btn ──── final <──────── game over ────────────────┘
--
--   start       welcome screen. Always clear scores to 0:0
--   game_init   ball and paddles centred (See ball_paddle). Waits for a button = serve. 
--               Also handles the pause after a miss.
--   game_update Check movement behavior in ball_paddle (omitted for brevity here)
--   game_rst    lasts exactly 1 clock: checks the end rule on the new scores
--               and goes to final or back to game_init
--   final       end screen; the renderer shows the winner (scores stay visible).
--               A button goes back to the start screen.
--   rst         from anywhere back to start.
--
--   End rule (this is a requirement, though badly worded. Kept as generics for easy change):
--     game over when one player reaches WIN_SCORE points,
--     or when MAX_BALLS balls have been played (balls = score_l + score_r).
--
--   btn_press is a 1-clock pulse (any button), so one press moves exactly one
--   state forward. miss is a 1-clock pulse from ball_paddle.
--   No frame_tick needed: every transition comes from a button, a miss or rst.
--
-- Dependencies: design_pkg
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - State machine, scoring and end rule
-- Additional Comments:
-- @Simon how would you like to do the animations between states? Leave entirely since deadline is close?
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.design_pkg.all;

entity game_fsm is
    generic (
        WIN_SCORE : natural := 3;   -- points needed to win
        MAX_BALLS : natural := 6    -- balls per game at most
    );
    port (
            --general inputs
            clk_pix     : in std_logic;
            rst         : in std_logic;

            -- Game specific
            miss        : in miss_t;        -- 1-clock pulse from ball_paddle
            btn_press   : in std_logic;     -- 1-clock pulse, any button
            state       : out state_t;
            score_l     : out score_t;
            score_r     : out score_t
            );
end game_fsm;

architecture Behavioral of game_fsm is
    signal state_i  : state_t := start;
    signal points_l : score_t := (others => '0');
    signal points_r : score_t := (others => '0');
begin

process(clk_pix)
begin
    if rising_edge(clk_pix) then
        if rst = '1' then
            state_i  <= start;
            points_l <= (others => '0');
            points_r <= (others => '0');
        else
            case state_i is -- ugly switch but what can you do

                when start =>
                    points_l <= (others => '0');
                    points_r <= (others => '0');
                    if btn_press = '1' then
                        state_i <= game_init;
                    end if;

                when game_init =>
                    if btn_press = '1' then
                        state_i <= game_update;
                    end if;

                when game_update =>
                    if miss = left then             -- left player missed
                        points_r <= points_r + 1;
                        state_i  <= game_rst;
                    elsif miss = right then         -- right player missed
                        points_l <= points_l + 1;
                        state_i  <= game_rst;
                    end if;

                when game_rst =>
                    -- the new score is already in points_l / points_r here (FIXME keep like this?)
                    if points_l >= WIN_SCORE or points_r >= WIN_SCORE
                        or points_l + points_r >= MAX_BALLS then
                        state_i <= final;
                    else
                        state_i <= game_init;
                    end if;

                when final =>
                    if btn_press = '1' then
                        state_i <= start;
                    end if;

            end case;
        end if;
    end if;
end process;

state   <= state_i;
score_l <= points_l;
score_r <= points_r;

end Behavioral;
