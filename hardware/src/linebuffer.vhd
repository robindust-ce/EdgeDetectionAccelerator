 ----------------------------------------------------------------------------------
-- Module Name:    linebuffer
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module implements a simple linebuffer. When valid_i is HIGH the linebuffer
-- outputs the pixel at current index and it's two adjacent pixels. 
-- data_i is stored at the same index With a delay of one clock cycle. Missing
-- adjacent pixels at the first and last index of the buffer are replaced by 0's.data_i 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

library work;
  use work.types_lib.all;

entity linebuffer is
  generic (
    linebuffer_size : integer := 640;
    data_width      : integer := 8
  );
  port (
    data_i  : in    std_logic_vector(7 downto 0);
    valid_i : in    std_logic;
    clk_i   : in    std_logic;
    rst_i   : in    std_logic;
    valid_o : out   std_logic;
    data_o  : out   t_LINEBUFFER_OUT
  );
end entity linebuffer;

architecture behavioral of linebuffer is

  type t_chunked_array is array (0 to linebuffer_size - 1) of std_logic_vector(data_width - 1 downto 0);

  signal s_linebuffer_mem : t_chunked_array := (others => (others => '0'));
  signal s_index          : integer := 0;
  signal s_index_ff       : integer := 0;
  signal s_within_frame   : std_logic := '0';
  signal s_valid_ff       : std_logic := '0';
  signal s_data_ff        : std_logic_vector(7 downto 0);

begin

  cnt_proc : process (clk_i) is
  begin

    if rising_edge(clk_i) then
      if (rst_i = '0') then
        s_index        <= 0;
        s_within_frame <= '0';
      else
        if (valid_i = '1') then
          if (s_index = (linebuffer_size - 1)) then
            s_index        <= 0;
            s_within_frame <= '1';
          else
            s_index <= s_index + 1;
          end if;
        end if;
      end if;
    end if;

  end process cnt_proc;

  write_proc : process (clk_i) is
  begin

    if rising_edge(clk_i) then
      if (s_valid_ff = '1') then
        s_linebuffer_mem(s_index_ff) <= s_data_ff;
      end if;
    end if;

  end process write_proc;

  ff : process (clk_i) is
  begin

    if rising_edge(clk_i) then
      s_valid_ff <= valid_i;
      s_data_ff  <= data_i;
      s_index_ff <= s_index;
    end if;

  end process ff;

  data_o(0) <= (others => '0') when (s_index = 0) else
               unsigned(s_linebuffer_mem(s_index - 1));

  data_o(1) <= unsigned(s_linebuffer_mem(s_index));

  data_o(2) <= (others => '0') when (s_index = (linebuffer_size - 1)) else
               unsigned(s_linebuffer_mem(s_index + 1));

  valid_o <= valid_i and s_within_frame;

end architecture behavioral;

