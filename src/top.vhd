----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2026 16:14:23
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
    Port ( CLK100MHZ : in STD_LOGIC;
           ck_rst : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (3 downto 0));
end top;

architecture Behavioral of top is
signal clk_pix   : std_logic;
signal rst       : std_logic;
signal btn_level : std_logic_vector(3 downto 0);
signal btn_press : std_logic_vector(3 downto 0);  
signal sample_tick : std_logic;

begin
u_tick : entity work.tick_gen
    generic map (DIVIDER => 302_000)          -- 12 ms at 25.173 MHz
    port map (clk_pix => clk_pix, tick => sample_tick);

gen_btn : for i in btn'range generate
    u_dbn : entity work.btn_dbn
        port map (
            clk         => clk_pix,
            sample_tick => sample_tick,       -- same tick for all four
            btn_in      => btn(i),
            level       => btn_level(i),
            press       => btn_press(i)
        );
end generate gen_btn;
u_clk_gen : entity work.clk_gen
    port map (
        clk_100 => CLK100MHZ,   -- top port
        rst_n   => ck_rst,      -- top port, red RESET button
        clk_pix => clk_pix,     -- internal signal of top
        rst     => rst          -- internal signal of top
    );

end Behavioral;
