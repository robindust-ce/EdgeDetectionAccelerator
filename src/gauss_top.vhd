----------------------------------------------------------------------------------
-- Module Name:    gauss_top
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This module connects the kernel_top module responsible for writing and reading
-- linebuffers with the incoming (VGA-like) stream of grayscale pixels to the
-- gauss_kernel module.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.types_lib.all;

entity gauss_top is
  generic (
    pipeline  : integer := 1;
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
    data_o  : out   std_logic_vector(7 downto 0);
    valid_o : out   std_logic
  );
end entity gauss_top;

architecture behavioral of gauss_top is

  component kernel_top is
    generic (
      tot_lines : integer := tot_lines;
      tot_cols  : integer := tot_cols;
      im_lines  : integer := im_lines;
      im_cols   : integer := im_cols
    );
    port (
      clk      : in    std_logic;
      rst      : in    std_logic;
      data_i   : in    std_logic_vector(7 downto 0);
      valid_i  : in    std_logic;
      hcount_o : out   unsigned(9 downto 0);
      vcount_o : out   unsigned(9 downto 0);
      valid_o  : out   std_logic;
      line0_o  : out   t_LINEBUFFER_OUT;
      line1_o  : out   t_LINEBUFFER_OUT;
      line2_o  : out   t_LINEBUFFER_OUT
    );
  end component;

  component gauss_kernel is
    generic (
      pipeline : integer := 0
    );
    port (
      line0_i : in    t_LINEBUFFER_OUT;
      line1_i : in    t_LINEBUFFER_OUT;
      line2_i : in    t_LINEBUFFER_OUT;
      pixel_o : out   std_logic_vector(7 downto 0);
      valid_i : in    std_logic;
      valid_o : out   std_logic;
      clk     : in    std_logic;
      rst     : in    std_logic
    );
  end component;

  signal valid_internal : std_logic;
  signal s_kernel_din0  : t_LINEBUFFER_OUT;
  signal s_kernel_din1  : t_LINEBUFFER_OUT;
  signal s_kernel_din2  : t_LINEBUFFER_OUT;

begin

  i_kernel_top : component kernel_top
    port map (
      data_i   => data_i,
      valid_i  => valid_i,
      clk      => clk,
      rst      => rst,
      hcount_o => open,
      vcount_o => open,
      valid_o  => valid_internal,
      line0_o  => s_kernel_din0,
      line1_o  => s_kernel_din1,
      line2_o  => s_kernel_din2
    );

  i_gauss : component gauss_kernel
    generic map (
      pipeline => pipeline
    )
    port map (
      line0_i => s_kernel_din0,
      line1_i => s_kernel_din1,
      line2_i => s_kernel_din2,
      clk     => clk,
      rst     => rst,
      pixel_o => data_o,
      valid_i => valid_internal,
      valid_o => valid_o
    );

end architecture behavioral;
