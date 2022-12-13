----------------------------------------------------------------------------------
-- Module Name:    kernel_top
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module two linebuffers with the incoming (VGA-like) stream of
-- grayscale pixels. Simultaneously, it provides the read values from the filled
-- buffers as a 3x3 matrix to subsequent modules.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- library work;
  use work.types_lib.all;

entity kernel_top is
  generic (
    tot_lines : integer := 525;
    tot_cols  : integer := 800;
    im_lines  : integer := 480;
    im_cols   : integer := 640
  );
  port (
    clk     : in    std_logic;
    rst     : in    std_logic;
    data_i  : in    std_logic_vector(7 downto 0);
    valid_i : in    std_logic;

    hcount_o : out   unsigned(9 downto 0);
    vcount_o : out   unsigned(9 downto 0);
    valid_o  : out   std_logic;
    line0_o  : out   t_LINEBUFFER_OUT;
    line1_o  : out   t_LINEBUFFER_OUT;
    line2_o  : out   t_LINEBUFFER_OUT
  );
end entity kernel_top;

architecture behavioral of kernel_top is

  component linebuffer is
    generic (
      linebuffer_size : integer := im_cols;
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
  end component;

  signal s_l0_data_o     : t_LINEBUFFER_OUT;
  signal s_l1_data_o     : t_LINEBUFFER_OUT;
  signal s_linebuf       : t_LINEBUFFER_OUT;
  signal s_line_internal : t_LINEBUFFER_OUT;

  signal s_rd_linecount : integer range 0 to tot_lines - 1 := 0;
  signal s_rd_colcount  : integer range 0 to tot_cols - 1 := 0;

  signal s_valid_internal : std_logic := '0';
  signal s_l0_valid       : std_logic := '0';
  signal s_l1_valid       : std_logic := '0';
  signal s_valid_ff       : std_logic_vector(3 downto 0) := (others => '0');
  signal s_active_frame   : std_logic := '0';

  signal s_sync : boolean := false;

  signal s_linebuf_rst : std_logic := '0';
  signal s_comb_rst    : std_logic := '0';

begin

  i_linebuffer0 : component linebuffer
    port map (
      data_i  => std_logic_vector(s_linebuf(1)),
      valid_i => s_valid_internal,
      clk_i   => clk,
      rst_i   => s_comb_rst,
      valid_o => s_l0_valid,
      data_o  => s_l0_data_o
    );

  i_linebuffer1 : component linebuffer
    port map (
      data_i  => std_logic_vector(s_l0_data_o(1)),
      valid_i => s_l0_valid,
      clk_i   => clk,
      rst_i   => s_comb_rst,
      valid_o => s_l1_valid,
      data_o  => s_l1_data_o
    );

  rd_count_proc : process (clk, rst) is

    variable v_sync : boolean := false;

  begin

    if rising_edge(clk) then
      if (rst = '0') then
        s_rd_colcount  <= 0;
        s_rd_linecount <= 0;
        s_sync         <= false;
      else
        s_linebuf_rst <= '1';

        if (s_valid_ff(0) = '1') then
          s_sync <= true;
        end if;

        if (s_sync) then
          if (s_rd_colcount = tot_cols - 1) then
            s_rd_colcount <= 0;
          else
            s_rd_colcount <= s_rd_colcount + 1;
          end if;
          if (s_rd_colcount = tot_cols - 1) then
            if (s_rd_linecount = tot_lines - 1) then
              s_rd_linecount <= 0;
            else
              s_rd_linecount <= s_rd_linecount + 1;
              if (s_rd_linecount = im_lines) then
                s_linebuf_rst <= '0';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;

  end process rd_count_proc;

  -- FF stage
  ff_proc : process (clk) is
  begin

    if rising_edge(clk) then
      s_linebuf(0) <= s_linebuf(1);
      s_linebuf(1) <= s_linebuf(2);
      s_linebuf(2) <= unsigned(data_i);
    end if;

  end process ff_proc;

  -- FF stage
  ff_proc2 : process (clk) is
  begin

    if rising_edge(clk) then
      s_valid_ff <= s_valid_ff(2 downto 0) & valid_i;
    end if;

  end process ff_proc2;

  s_comb_rst <= s_linebuf_rst and rst;

  s_valid_internal <= '1' when (s_rd_linecount < im_lines + 1) and (s_rd_colcount < im_cols) and s_sync else
                      '0';

  s_line_internal(0) <= (others => '0') when (s_rd_colcount = 0) else
                        s_linebuf(0);
  s_line_internal(1) <= s_linebuf(1);
  s_line_internal(2) <= (others => '0') when (s_rd_colcount = im_cols - 1) else
                        s_linebuf(2);
  -- OUTPUTS
  valid_o <= s_l0_valid or s_l1_valid;

  line0_o <= (others => (others => '0')) when (s_rd_linecount = 0) else
             s_l1_data_o;

  line1_o <= s_l0_data_o;

  line2_o <= (others => (others => '0')) when (s_rd_linecount = im_lines - 1) else
             s_line_internal;

  hcount_o <= to_unsigned(s_rd_colcount, 10);
  vcount_o <= to_unsigned(s_rd_linecount, 10);

end architecture behavioral;

