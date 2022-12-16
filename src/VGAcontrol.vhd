----------------------------------------------------------------------------------
-- Module Name:    VGAcontrol
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module creates all VGA output signals from the horizontal and vertical
-- counters. Horizontal sync and vertical sync are generated based on the image
-- dimensions and VGA timings set via the generics.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity vgacontrol is
  generic (
    total_row_nr     : integer := 525;
    active_row_nr    : integer := 480;
    total_col_nr     : integer := 800;
    active_col_nr    : integer := 640;
    vert_front_porch : integer := 10;
    vert_back_porch  : integer := 33;
    hor_front_porch  : integer := 16;
    hor_back_porch   : integer := 48
  );
  port (
    clk      : in    std_logic;
    dat_i    : in    std_logic_vector(7 downto 0);
    vcount_i : in    unsigned(9 downto 0);
    hcount_i : in    unsigned(9 downto 0);
    vga_r    : out   std_logic_vector(3 downto 0);
    vga_g    : out   std_logic_vector(3 downto 0);
    vga_b    : out   std_logic_vector(3 downto 0);
    vga_hs   : out   std_logic;
    vga_vs   : out   std_logic
  );
end entity vgacontrol;

architecture behavioral of vgacontrol is

  signal vcount : integer range 0 to total_row_nr - 1 := 0;
  signal hcount : integer range 0 to total_col_nr - 1 := 0;

begin

  vcount <= to_integer(vcount_i);
  hcount <= to_integer(hcount_i);

  vga_hs <= '1' when ((hcount < (active_col_nr + hor_front_porch)) or (hcount >= (total_col_nr - hor_back_porch))) else
            '0';
  vga_vs <= '1' when (vcount < (active_row_nr + vert_front_porch)) or (vcount >= (total_row_nr - vert_back_porch)) else
            '0';

  vga_r <= dat_i(7 downto 4) when ((hcount < active_col_nr) and (vcount < active_row_nr)) else
           (others => '0');
  vga_g <= dat_i(7 downto 4) when ((hcount < active_col_nr) and (vcount < active_row_nr)) else
           (others => '0');
  vga_b <= dat_i(7 downto 4) when ((hcount < active_col_nr) and (vcount < active_row_nr)) else
           (others => '0');

end architecture behavioral;

