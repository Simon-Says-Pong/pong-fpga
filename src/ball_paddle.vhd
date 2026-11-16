----------------------------------------------------------------------------------
-- Create Date: 11.11.2026 16:14:23
-- Module Name: ball_paddle - Behavioral
-- Description: Positions of the ball and both paddles, ball movement, bounces and
--              miss detection. Updates once per frame (frame_tick, 60 Hz) while
--              state = game_update; game_init (or rst) puts everything back in the
--              centre; all other states freeze the objects. Currently only flipping
--              pall movement into dx/dy for 45 deg diagonals.
--
-- Coordinate norm:
--   Every position is the TOP-LEFT CORNER of the object.
--   An object is corner .. corner + size - 1 since we only work with rects:
--     ball          x  bx  .. bx+11      y  by    .. by+11       (12 x 12)
--     left paddle   x   8  .. 17         y  pad_l .. pad_l+59    (10 x 60)
--     right paddle  x 622  .. 631        y  pad_r .. pad_r+59
--   Sizes, x positions, speeds and start positions are constants in design_pkg.
--
-- Ball movement (per frame):
--   Direction is one bit per axis: dir_x '1' = right, dir_y '1' = down.
--   Each frame the ball moves BALL_SPEED px in x AND y -> always 45 degrees.
--   Each frame runs these steps in order, using variables (bx, by, dx, dy) so
--   every step sees the result of the previous one:
--     1. walls   - flip dy at the top / bottom
--     2. paddles - flip dx when the ball reaches a paddle
--     3. miss    - ball would leave the screen left / right -> miss pulse
--     4. move    - add / subtract BALL_SPEED (skipped on a miss, the ball stays
--                  put until game_init recentres it)
--   Paddles are checked before the miss, so touching a paddle is always a hit.
--
-- Serve:
--   After a miss the next ball starts towards the player who missed (the one
--   who was scored on): miss left -> serve left, miss right -> serve right.
--   A new game (rst or start) always serves to the right.
--
-- Outputs:
--   ball_pos, paddle_l_pos, paddle_r_pos : top-left corners for the renderer
--   miss : 'left' / 'right' for exactly one clock when that player missed,
--          'none' otherwise (game_fsm scores and switches state on it)
--
-- Dependencies: design_pkg
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Paddle and ball movement, wall/paddle bounces, miss output,
--                 top-left corner outputs for the renderer
-- Revision 0.03 - Serve towards the player who was scored on
-- Additional Comments: Rev 0.03 with accelarating ball/paddles + non 45 deg angles possible
--
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.design_pkg.all;

entity ball_paddle is
    Port ( clk_pix    : in  std_logic;
           rst        : in  std_logic;                      -- from clk_gen, active high
           frame_tick : in  std_logic;                      -- 1-cycle pulse per frame (enable)
           btn_level  : in  std_logic_vector (3 downto 0);  -- debounced, '1' while held
           state      : in  state_t;
           miss       : out miss_t;                         -- 1-clock pulse: left / right player missed, else none

           
           -- positions for the renderer: top-left corner (x, y) of each object
           ball_pos     : out pos_t;
           paddle_l_pos : out pos_t;                        -- x is fixed (PADDLE_L_X1)
           paddle_r_pos : out pos_t);                       -- x is fixed (PADDLE_R_X1)
end ball_paddle;

architecture Behavioral of ball_paddle is
signal ball_x, ball_y : unsigned(9 downto 0); -- internal position of the ball
signal dir_x, dir_y : std_logic; -- directional bit is more efficient than signed vectors for movement. 1 = moving right/down
signal pad_l, pad_r : unsigned(9 downto 0); -- internal positions of the paddle
signal serve_dir : std_logic := '1'; -- dir_x for the next serve: towards the player who missed last

-- map buttons directly using alias to not create extra hardware
alias paddle_l_up   : std_logic is btn_level(0);
alias paddle_l_down : std_logic is btn_level(1);
alias paddle_r_up   : std_logic is btn_level(2);
alias paddle_r_down : std_logic is btn_level(3);


begin
    process(clk_pix)
        -- working copies for the ball update: first decide bounces/miss on these,
        -- then write the result to the signals once at the end
        variable bx, by   : unsigned(9 downto 0);
        variable dx, dy   : std_logic;
        variable hit_miss : miss_t;
    begin
        if rising_edge(clk_pix) then
            miss <= none;

            -- new game (reset or start screen): first serve goes to the right
            if rst = '1' OR state = start then
                serve_dir <= '1';
            end if;

            if rst = '1' OR state = game_init then -- center on init/reset
                ball_x <= to_unsigned(BALL_X0, 10);
                ball_y <= to_unsigned(BALL_Y0, 10);
                pad_l <= to_unsigned(PADDLE_Y0, 10);
                pad_r <= to_unsigned(PADDLE_Y0, 10);
                dir_x <= serve_dir;             -- towards the player who missed last
                dir_y <= '1';
                
            elsif frame_tick = '1' AND state = game_update then

                --------------------------------------------------
                -- Paddle Movement. 
                -- Moving up clamps to 0, moving 
                -- down clamps to VPIX - PADDLE_HIGHT
                --------------------------------------------------
                if paddle_l_up = '1' AND paddle_l_down = '0' then
                    if pad_l >= PADDLE_SPEED then 
                        pad_l <= pad_l - PADDLE_SPEED;
                    else                          
                        pad_l <= (others => '0');
                    end if;
                end if;    
                if paddle_l_down = '1' AND paddle_l_up = '0' then
                    if pad_l + PADDLE_HIGHT + PADDLE_SPEED <= VPIX then 
                        pad_l <= pad_l + PADDLE_SPEED;
                    else                          
                        pad_l <= to_unsigned(VPIX - PADDLE_HIGHT, 10);
                    end if;    
                end if;
                if paddle_r_up = '1' AND paddle_r_down = '0' then
                    if pad_r >= PADDLE_SPEED then 
                        pad_r <= pad_r - PADDLE_SPEED;
                    else                          
                        pad_r <= (others => '0');
                    end if;     
                end if;
                if paddle_r_down = '1' AND paddle_r_up = '0' then
                 if pad_r + PADDLE_HIGHT + PADDLE_SPEED <= VPIX then 
                        pad_r <= pad_r + PADDLE_SPEED;
                    else                          
                        pad_r <= to_unsigned(VPIX - PADDLE_HIGHT, 10);
                    end if;   
                end if;  
                
                --------------------------------------------------
                -- Ball Movement (diagonal movement: BALL_SPEED in x and y, currently only 45 deg)
                -- Order of the checks: walls -> paddles -> miss -> move.
                -- All checks look one step ahead ("would the next
                -- step cross it?"), so unsigned values never wrap.
                -- Bounds are exclusive: an object covers
                -- pos .. pos + size - 1.
                --------------------------------------------------
                bx := ball_x;
                by := ball_y;
                dx := dir_x;
                dy := dir_y;
                hit_miss := none;

                -- First check top / bottom 
                if dy = '0' and by < BALL_SPEED then
                    dy := '1';
                elsif dy = '1' and by + BALL_HIGHT + BALL_SPEED > VPIX then
                    dy := '0';
                end if;

                -- Second check paddles: next step would overlap the paddle in x,
                --    and ball and paddle overlap in y -> flip horizontal direction.
                --    Checked before the miss, so touching a paddle always counts as a hit.
                if dx = '0'
                    and bx >= PADDLE_L_X1 and bx < PADDLE_L_X2 + BALL_SPEED
                    and by + BALL_HIGHT > pad_l and by < pad_l + PADDLE_HIGHT then
                    dx := '1';
                elsif dx = '1'
                    and bx + BALL_WIDTH + BALL_SPEED > PADDLE_R_X1 and bx + BALL_WIDTH <= PADDLE_R_X2
                    and by + BALL_HIGHT > pad_r and by < pad_r + PADDLE_HIGHT then
                    dx := '0';

                -- Third check miss: next step would leave the screen on the left / right
                elsif dx = '0' and bx < BALL_SPEED then
                    hit_miss := left;    -- left player missed -> right player scores
                elsif dx = '1' and bx + BALL_WIDTH + BALL_SPEED > HPIX then
                    hit_miss := right;   -- right player missed -> left player scores
                end if;

                -- remember who missed: the next serve goes towards them
                if hit_miss = left then
                    serve_dir <= '0';
                elsif hit_miss = right then
                    serve_dir <= '1';
                end if;

                -- Normal move (not on a miss: the ball stays put until game_init recentres it)
                if hit_miss = none then
                    if dx = '1' then bx := bx + BALL_SPEED; else bx := bx - BALL_SPEED; end if;
                    if dy = '1' then by := by + BALL_SPEED; else by := by - BALL_SPEED; end if;
                end if;

                ball_x <= bx;
                ball_y <= by;
                dir_x  <= dx;
                dir_y  <= dy;
                miss   <= hit_miss;     -- 1-clock pulse, default 'none' at the top
            end if;
        end if;
    end process;

    -- outputs: top-left corners
    ball_pos     <= (x => ball_x,                          y => ball_y);
    paddle_l_pos <= (x => to_unsigned(PADDLE_L_X1, 10),    y => pad_l);
    paddle_r_pos <= (x => to_unsigned(PADDLE_R_X1, 10),    y => pad_r);
end Behavioral;
