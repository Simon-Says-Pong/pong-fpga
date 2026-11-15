----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2026 16:07:49
-- Design Name: 
-- Module Name: game_fsm - Behavioral
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
use IEEE.numeric_std.all;
library work;
use work.design_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity game_fsm is
    port (  
            --general inputs
            clk_pix     : in std_logic;
            rst         : in std_logic;
            
            --60Hz bild ende Signal 
            frame_tick  : in std_logic;
            
            -- Game specific 
            miss        : in miss_t;
            btn_press   : in std_logic;
            state       : out state_t;
            score_l     : out score_t;
            score_r     : out score_t
            );
end game_fsm;

architecture Behavioral of game_fsm is

begin



----------------------------------------------------------------------



----------------------------------------------------------------------
process(clk_pix)
begin 
    if rising_edge(clk_pix) then
        if frame_tick = '1' then 
            
        end if;
    end if;
end process;  
  
end Behavioral;
