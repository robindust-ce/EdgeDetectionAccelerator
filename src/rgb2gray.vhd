----------------------------------------------------------------------------------
-- Module Name:    rgb2gray
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module implements the conversion of RGB888 pixels to 8-bit grayscale
-- pixels using bitshifts.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rgb2gray is
  port (
    red     : in    std_logic_vector(7 downto 0);
    green   : in    std_logic_vector(7 downto 0);
    blue    : in    std_logic_vector(7 downto 0);
    clk     : in    std_logic;
    valid_i : in    std_logic;
    valid_o : out   std_logic;
    gray    : out   unsigned (7 downto 0)
  );
end entity rgb2gray;

architecture behavioral of rgb2gray is

begin

  process (clk) is
  begin

    if rising_edge(clk) then
      valid_o <= valid_i;
      -- roughly equates g = red*0.299+green*0.587+blue*0.114
      gray <= shift_right(unsigned(red), 3) + shift_right(unsigned(red), 5) + shift_right(unsigned(red), 6) + shift_right(unsigned(green), 1) + shift_right(unsigned(green), 4) + shift_right(unsigned(green), 5) + shift_right(unsigned(blue), 3);
    end if;

  end process;

end architecture behavioral;
