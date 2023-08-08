----------------------------------------------------------------------------------
-- Module Name:    sobel
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module implements a sobel filter in xy-direction. It takes 3x3 grayscale
-- pixels and outputs the sum of the absoulte sobel filter results in x- and y-
-- direction. The module implements a 3-stage pipeline version for frequency
-- optimization, as well as a single cycle version. The version can be chosen via
-- the PIPELINE generic. A threshold can be set via th_i. If th_i is zero, no
-- threshold is applied.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.types_lib.all;

entity sobel_kernel is
  generic (
    data_width : integer := 8;
    pipeline   : integer := 1
  );
  port (
    lb0_i   : in    t_LINEBUFFER_OUT;
    lb1_i   : in    t_LINEBUFFER_OUT;
    lb2_i   : in    t_LINEBUFFER_OUT;
    th_i    : in    std_logic_vector(10 downto 0);
    clk     : in    std_logic;
    rst     : in    std_logic;
    valid_i : in    std_logic;

    valid_o    : out   std_logic;
    sobel_xy_o : out   std_logic_vector(data_width - 1 downto 0)
  );
end entity sobel_kernel;

architecture behavioral of sobel_kernel is

  signal sobel_x_o : std_logic_vector(data_width - 1 downto 0);
  signal sobel_y_o : std_logic_vector(data_width - 1 downto 0);

  signal s_valid_t0     : std_logic := '0';
  signal s_valid_t1     : std_logic := '0';
  signal s_valid_t2     : std_logic := '0';
  signal s_res_sobel_x  : signed(11 downto 0);
  signal s_res_sobel_y  : signed(11 downto 0);
  signal s_res_sobel_xy : signed(11 downto 0);

  signal   s_mul_internal_x : t_SIGNED_PXL_ARRAY;
  signal   s_mul_internal_y : t_SIGNED_PXL_ARRAY;
  signal   s_line_concat    : t_SIGNED_PXL_ARRAY;
  constant c_sobel_x        : t_INT_KERNEL := (1, 0, -1, 2, 0, -2, 1, 0, -1);
  constant c_sobel_y        : t_INT_KERNEL := (1, 2, 1, 0, 0, 0, -1, -2, -1);

begin

  g_pipeline : if pipeline = 1 generate

    -- s_line_concat <= ("0000" & signed(lb0_i(0)), "0000" & signed(lb0_i(1)), "0000" & signed(lb0_i(2)), "0000" & signed(lb1_i(0)), "0000" & signed(lb1_i(1)), "0000" & signed(lb1_i(2)), "0000" & signed(lb2_i(0)), "0000" & signed(lb2_i(1)), "0000" & signed(lb2_i(2)));

    gen_line_concat : for i in 0 to 2 generate
      s_line_concat(i)     <= "0000" & signed(lb0_i(i));
      s_line_concat(i + 3) <= "0000" & signed(lb1_i(i));
      s_line_concat(i + 6) <= "0000" & signed(lb2_i(i));
    end generate gen_line_concat;

    process (clk, rst) is

      variable v_acc_int_x : signed(11 downto 0);
      variable v_acc_int_y : signed(11 downto 0);

    begin

      if rising_edge(clk) then
        if (rst = '0') then
          s_res_sobel_x  <= (others => '0');
          s_res_sobel_y  <= (others => '0');
          s_res_sobel_xy <= (others => '0');
        else

          for I in 0 to 3 loop

            case I is

              when 0 =>

                mul : for J in 0 to 8 loop

                  s_mul_internal_x(J) <= resize((c_sobel_x(J)) * (s_line_concat(J)), 12);
                  s_mul_internal_y(J) <= resize((c_sobel_y(J)) * (s_line_concat(J)), 12);

                end loop mul;

                s_valid_t0 <= valid_i;

              when 1 =>

                for J in 0 to 8 loop

                  v_acc_int_x := v_acc_int_x + s_mul_internal_x(J);
                  v_acc_int_y := v_acc_int_y + s_mul_internal_y(J);

                end loop;

                s_res_sobel_x <= v_acc_int_x;
                s_res_sobel_y <= v_acc_int_y;
                v_acc_int_x   := (others => '0');
                v_acc_int_y   := (others => '0');
                s_valid_t1    <= s_valid_t0;

              when 2 =>

                s_res_sobel_xy <= abs(s_res_sobel_x) + abs(s_res_sobel_y);
                s_valid_t2     <= s_valid_t1;

              when 3 =>

                if (th_i /= "00000000000") then
                  if (s_res_sobel_xy > signed("0" & th_i)) then
                    sobel_xy_o <= (others => '1');
                  else
                    sobel_xy_o <= (others => '0');
                  end if;
                else
                  if (s_res_sobel_xy > 255) then
                    sobel_xy_o <= (others => '1');
                  else
                    sobel_xy_o <= std_logic_vector(s_res_sobel_xy(7 downto 0));
                  end if;
                end if;
                valid_o <= s_valid_t2;

              when others =>

                null;

            end case;

          end loop;

        end if;
      end if;

    end process;

  end generate g_pipeline;

  g_nopipeline : if pipeline = 0 generate

    process (clk, rst) is

      constant max_value         : signed(11 downto 0) := to_signed(255, 12); --( data_width - 1 downto 0 => '1', others => '0'); -- max = 255 (000011111111)
      variable s_result_sobel_x  : signed(11 downto 0);
      variable s_result_sobel_y  : signed(11 downto 0);
      variable s_result_sobel_xy : signed(11 downto 0);

    begin

      if rising_edge(clk) then
        if (rst = '0') then
          s_result_sobel_x  := (others => '0');
          s_result_sobel_y  := (others => '0');
          s_result_sobel_xy := (others => '0');
        else
          valid_o <= valid_i;

          -- Gx
          s_result_sobel_x := ("0000" & signed(lb0_i(0))) + ("000" & signed(lb1_i(0)) & "0") + ("0000" & signed(lb2_i(0)))
                              - ("0000" & signed(lb0_i(2))) - ("000" & signed(lb1_i(2)) & "0") - ("0000" & signed(lb2_i(2)));
          -- Gy
          s_result_sobel_y := ("0000" & signed(lb0_i(0))) + ("000" & signed(lb0_i(1)) & "0") + ("0000" & signed(lb0_i(2)))
                              - ("0000" & signed(lb2_i(0))) - ("000" & signed(lb2_i(1)) & "0") - ("0000" & signed(lb2_i(2)));

          -- abs(Gx)
          if (s_result_sobel_x(s_result_sobel_x'left) = '1') then
            s_result_sobel_x := (not s_result_sobel_x) + 1;
          end if;
          -- abs(Gy)
          if (s_result_sobel_y(s_result_sobel_y'left) = '1') then
            s_result_sobel_y := (not s_result_sobel_y) + 1;
          end if;

          -- Gxy
          s_result_sobel_xy := s_result_sobel_x + s_result_sobel_y;

          if (s_result_sobel_x > 255) then
            s_result_sobel_x := max_value;
          end if;
          if (s_result_sobel_y > 255) then
            s_result_sobel_y := max_value;
          end if;

          if (unsigned(th_i) > (10 downto 0 => '0')) then
            if (s_result_sobel_xy > signed("0" & th_i)) then
              s_result_sobel_xy := max_value;
            else
              s_result_sobel_xy := (others => '0');
            end if;
          end if;

          sobel_x_o  <= std_logic_vector(resize(unsigned(s_result_sobel_x), sobel_x_o'length));
          sobel_y_o  <= std_logic_vector(resize(unsigned(s_result_sobel_y), sobel_y_o'length));
          sobel_xy_o <= std_logic_vector(resize(unsigned(s_result_sobel_xy), sobel_xy_o'length));
        end if;
      end if;

    end process;

  end generate g_nopipeline;

end architecture behavioral;
