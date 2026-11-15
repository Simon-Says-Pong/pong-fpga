library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.design_pkg.all;
use work.bitmap_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity digit_check is
    generic (
        -- General Digit Config DLB - > Digit Left Border 
        D_WIDTH : NATURAL := 60;
        D_HIGHT : NATURAL := 80;
        
        --Konstant Number Template Multiplier 10x10
        DMULTI_X : NATURAL := D_WIDTH / 10; --6x
        -- FIXME: uses D_WIDTH instead of D_HIGHT -> 6 instead of 8. row_index then
        --        reaches 13 for y up to DB_Y2, outside its range 0..9. Should be D_HIGHT / 10.
        DMULTI_Y : NATURAL := D_WIDTH / 10; --8x
        
        --general
        DB_Y1 : NATURAL := 10;
        DB_Y2 : NATURAL := DB_Y1 + D_HIGHT;
        
        --Left Digit
        DLB_X1 : NATURAL := 250;
        DLB_X2 : NATURAL := DLB_X1 + D_WIDTH;
        
        --Right Digit
        DRB_X1 : NATURAL := 330;
        DRB_X2 : NATURAL := DRB_X1 + D_WIDTH

    );
    Port ( 
        clk_pix     : in std_logic;
        score_l     : in score_t;
        score_r     : in score_t;
        pixel_pos   : in pos_t;
        
        digit_hit   : out std_logic
    );
end digit_check;

architecture Behavioral of digit_check is
    signal TempDigitPos : pos_t := (others => (others => '0'));
    signal digit_hit_left   : std_logic  := '0';
    signal digit_hit_right  : std_logic  := '0';
    signal data_DL          : unsigned(9 downto 0) := (others => '0');
    signal data_DR          : unsigned(9 downto 0) := (others => '0');
    signal pixel_pos_d      : pos_t := (others => (others => '0'));
begin
    
    --Zahlenabruf
    ram_a : process(clk_pix)
        variable row_index : natural range 0 to 9;
    begin 
        if rising_edge(clk_pix) then --kopplebar an H sync
            data_DL <= (others => '0');
            data_DR <= (others => '0');
            
            if pixel_pos.y >= DB_Y1 and pixel_pos.y < DB_Y2 then
                row_index := (to_integer(pixel_pos.y) - DB_Y1) / DMULTI_Y;
    
                --Left Digit
                case to_integer(score_l) is
                    when 0 => data_DL <= digit_0(row_index);
                    when 1 => data_DL <= digit_1(row_index);
                    when 2 => data_DL <= digit_2(row_index);
                    when 3 => data_DL <= digit_3(row_index);
                    when 4 => data_DL <= digit_4(row_index);
                    when 5 => data_DL <= digit_5(row_index);
                    when 6 => data_DL <= digit_6(row_index);
                    when 7 => data_DL <= digit_7(row_index);
                    when 8 => data_DL <= digit_8(row_index);
                    when 9 => data_DL <= digit_9(row_index);
                    when others => null; -- Default bleibt wirksam
                end case;
                
                --Right Digit
                case to_integer(score_r) is
                    when 0 => data_DR <= digit_0(row_index);
                    when 1 => data_DR <= digit_1(row_index);
                    when 2 => data_DR <= digit_2(row_index);
                    when 3 => data_DR <= digit_3(row_index);
                    when 4 => data_DR <= digit_4(row_index);
                    when 5 => data_DR <= digit_5(row_index);
                    when 6 => data_DR <= digit_6(row_index);
                    when 7 => data_DR <= digit_7(row_index);
                    when 8 => data_DR <= digit_8(row_index);
                    when 9 => data_DR <= digit_9(row_index);
                    when others => null; -- Default bleibt wirksam
                end case;
            end if;
        end if;
    end process;
    
    --Check if Pixel = Number
    checkHit : process(clk_pix)
    begin 
        if rising_edge(clk_pix) then
            pixel_pos_d <= pixel_pos;
            digit_hit_left <= '0';
            -- FIXME: duplicate line, should be digit_hit_right <= '0'. digit_hit_right is
            --        never reset, so after the first right-digit pixel it stays '1' forever
            --        and checkDigitVisual reads data_DR for every later pixel.
            digit_hit_left <= '0';

            --Overall horrible in efficency and needed storage
            -- FIXME: '<= DB_Y2' is one row too many (ram_a uses '< DB_Y2'), should be '<'.
            if pixel_pos.y >= DB_Y1 and pixel_pos.y <= DB_Y2 then
                -- FIXME: TempDigitPos is never used? Where do you read this?
                TempDigitPos.y <= (pixel_pos.y - DB_Y1) / 10; --Horrible in efficiency and Timing

                --left digit
                -- FIXME: '<= DLB_X2' / '<= DRB_X2' lets read_pos reach 10 (x - X1 = 60, / 6),
                --        but data_DL/data_DR only have bits 0..9. Overflow.
                if pixel_pos.x >= DLB_X1 and pixel_pos.x <= DLB_X2 then
                    TempDigitPos.x <= (pixel_pos.x - DLB_X1) / 10; --Horrible in efficiency and Timing
                    digit_hit_left <= '1';
                    
                --right digit    
                elsif pixel_pos.x >= DRB_X1 and pixel_pos.x <= DRB_X2 then 
                    TempDigitPos.x <= (pixel_pos.x - DRB_X1) / 10; --Horrible in efficiency and Timing
                    digit_hit_right <= '1';
                    
                end if;
            end if;
        end if;
    end process;
    
    --2.Tick Check if Number ON  --> delayed by 1 clk_pix
    checkDigitVisual : process(clk_pix)
        variable read_pos : unsigned(3 downto 0) := (others => '0');
    begin
        if rising_edge(clk_pix) then 
            digit_hit <= '0';
            
            -- FIXME: read_pos is 4 bits, but this is a 10 bit result. 
            -- FIXME: I believe this makes it so digits are mirrored?
            if digit_hit_left = '1' then
                read_pos := (pixel_pos_d.x - DLB_X1) / DMULTI_X;
                digit_hit <= '1' when data_DL(to_integer(read_pos)) = '1' else '0';
                
            elsif digit_hit_right = '1' then 
                read_pos := (pixel_pos_d.x - DRB_X1) / DMULTI_X;
                digit_hit <= '1' when data_DR(to_integer(read_pos)) = '1' else '0';
                
            end if;
        end if;
    end process;

end Behavioral;
