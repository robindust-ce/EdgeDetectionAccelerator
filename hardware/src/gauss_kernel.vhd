----------------------------------------------------------------------------------
-- Module Name:    gauss_kernel
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module implements a gaussian smoothing filter in three pipeline steps for
-- frequency optimization.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.types_lib.all;

entity gauss_kernel is
  port (
    clk     : in    std_logic;
    rst     : in    std_logic;
    line0_i : in    t_LINEBUFFER_OUT;
    line1_i : in    t_LINEBUFFER_OUT;
    line2_i : in    t_LINEBUFFER_OUT;
    pixel_o : out   std_logic_vector(7 downto 0);
    valid_i : in    std_logic;
    valid_o : out   std_logic
  );
end entity gauss_kernel;

architecture behavioral of gauss_kernel is

  constant c_gauss_kernel    : t_KERNEL := (x"1", x"2", x"1", x"2", x"4", x"2", x"1", x"2", x"1");
  constant c_neutral_kernel  : t_KERNEL := (x"0", x"0", x"0", x"0", x"1", x"0", x"0", x"0", x"0");
  signal   s_line_concat     : t_PXL_ARRAY := (others => (others => '0'));
  signal   s_mul_internal    : t_LONG_PXL_ARRAY := (others => (others => '0'));
  signal   s_result_internal : std_logic_vector(11 downto 0) := (others => '0');

  signal s_valid_t0 : std_logic := '0';
  signal s_valid_t1 : std_logic := '0';

  signal s_acc_internal : unsigned(11 downto 0) := (others => '0');

begin

  s_line_concat <= (line0_i(0), line0_i(1), line0_i(2), line1_i(0), line1_i(1), line1_i(2), line2_i(0), line2_i(1), line2_i(2));

  process (clk) is

    variable v_acc_internal : unsigned(11 downto 0) := (others => '0');

  begin

    if rising_edge(clk) then
      if (rst = '0') then
        valid_o        <= '0';
        v_acc_internal := (others => '0');
        s_mul_internal <= (others => (others => '0'));
      else

        for I in 0 to 2 loop

          case I is

            when 0 =>

              if (valid_i = '1') then

                mul : for J in 0 to 8 loop

                  s_mul_internal(J) <= (c_gauss_kernel(J)) * (s_line_concat(J));

                end loop mul;

              end if;
              s_valid_t0 <= valid_i;

            when 1 =>

              for J in 0 to 8 loop

                v_acc_internal := v_acc_internal + s_mul_internal(J);

              end loop;

              s_acc_internal <= v_acc_internal;
              v_acc_internal := (others => '0');
              s_valid_t1     <= s_valid_t0;

            when 2 =>

              s_result_internal <= std_logic_vector(shift_right(s_acc_internal, 4));
              valid_o           <= s_valid_t1;

            when others =>

              null;

          end case;

        end loop;

      end if;
    end if;

  end process;

  pixel_o <= s_result_internal(7 downto 0);

end architecture behavioral;
