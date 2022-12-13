----------------------------------------------------------------------------------
-- Module Name:    vga_in_sim
-- Project Name:   Edge Detection Accelerator
-- Target Devices: Digilent NexysA7
-- Description:
-- This module reads RGB444 pixel values in 12-bit blocks from bram and outputs
-- them separately in a VGA fashion as RGB888
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity vga_in_sim is
  generic (
    total_row_nr  : integer := 525;
    active_row_nr : integer := 480;
    total_col_nr  : integer := 800;
    active_col_nr : integer := 640;
    left_bound    : integer := 0;
    right_bound   : integer := 640;
    upper_bound   : integer := 0;
    lower_bound   : integer := 480
  );
  port (
    clk     : in    std_logic;
    rst     : in    std_logic;
    data_i  : in    std_logic_vector(11 downto 0);
    addr_o  : out   std_logic_vector(18 downto 0);
    valid_o : out   std_logic;
    red_o   : out   std_logic_vector(7 downto 0);
    green_o : out   std_logic_vector(7 downto 0);
    blue_o  : out   std_logic_vector(7 downto 0)
  );
end entity vga_in_sim;

architecture behavioral of vga_in_sim is

  signal vcount     : integer range 0 to total_row_nr - 1 := 0;
  signal hcount     : integer range 0 to total_col_nr - 1 := 0;
  signal addr_count : unsigned (18 downto 0) := (others => '0');

begin

  sync : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (rst = '0') then
        hcount <= 0;
        vcount <= 0;
      else
        if (hcount = (total_col_nr - 1)) then
          if (vcount = (total_row_nr - 1)) then
            vcount <= 0;
          else
            vcount <= vcount + 1;
          end if;
          hcount <= 0;
        else
          hcount <= hcount + 1;
        end if;
      end if;
    end if;

  end process sync;

  addr_proc : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (rst = '0') then
        addr_count <= (others => '0');
      else
        if ((hcount >= left_bound) and (hcount < right_bound)) then
          if ((vcount >= upper_bound) and (vcount < lower_bound)) then
            addr_count <= addr_count + 1;
          end if;
        else
          if ((vcount < upper_bound) or (vcount >= lower_bound)) then
            addr_count <= (others => '0');
          end if;
        end if;
      end if;
    end if;

  end process addr_proc;

  addr_o <= std_logic_vector(addr_count);

  valid_o <= '1' when ((hcount < active_col_nr) and (vcount < active_row_nr)) else
             '0';

  red_o   <= data_i(3 downto 0) & "0000" when (hcount >= left_bound) and (hcount < right_bound) and (vcount >= upper_bound) and (vcount < lower_bound) else
             (others => '0');
  green_o <= data_i(7 downto 4) & "0000" when (hcount >= left_bound) and (hcount < right_bound) and (vcount >= upper_bound) and (vcount < lower_bound) else
             (others => '0');
  blue_o  <= data_i(11 downto 8) & "0000" when (hcount >= left_bound) and (hcount < right_bound) and (vcount >= upper_bound) and (vcount < lower_bound) else
             (others => '0');

end architecture behavioral;
