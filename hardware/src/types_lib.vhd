library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package types_lib is

  type t_linebuffer_out is array (0 to 2) of unsigned(7 downto 0);

  type t_kernel is array (0 to 8) of unsigned (3 downto 0);

  type t_int_kernel is array (0 to 8) of integer range -2 to 2;

  type t_pxl_array is array (0 to 8) of unsigned (7 downto 0);

  type t_long_pxl_array is array (0 to 8) of unsigned (11 downto 0);

  type t_signed_pxl_array is array (0 to 8) of signed (11 downto 0);

end package types_lib;
