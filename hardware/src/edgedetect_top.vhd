----------------------------------------------------------------------------------
-- Module Name:    edgedetect_top
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This is the toplevel module of the Edge Detection Accelerator. It takes a
-- VGA-like input stream of RGB888 pixels and outputs the stream of the grayscale
-- image after edge detection. Therefore, it instantiates the rgb2gray module
-- for the grayscale conversion, the gauss_top module for the gaussian smoothing
-- filter and the sobel_top module for the sobel filter. Using th_i a threshold
-- for the output of the sobel filter can be set.
-- If th_i is zero, no threshold is applied.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity edgedetect_top is
  generic (
    tot_lines : integer := 525;
    tot_cols  : integer := 800;
    im_lines  : integer := 480;
    im_cols   : integer := 640
  );
  port (
    clk     : in    std_logic;
    rst     : in    std_logic;
    valid_i : in    std_logic;
    red_i   : in    std_logic_vector(7 downto 0);
    green_i : in    std_logic_vector(7 downto 0);
    blue_i  : in    std_logic_vector(7 downto 0);
    th_i    : in    std_logic_vector(10 downto 0);

    hcount_o : out   unsigned(9 downto 0);
    vcount_o : out   unsigned(9 downto 0);
    data_o   : out   std_logic_vector(7 downto 0)
  );
end entity edgedetect_top;

architecture behavioral of edgedetect_top is

  component gauss_top is
    generic (
      tot_lines : integer := tot_lines;
      tot_cols  : integer := tot_cols;
      im_lines  : integer := im_lines;
      im_cols   : integer := im_cols
    );
    port (
      clk     : in    std_logic;
      rst     : in    std_logic;
      data_i  : in    std_logic_vector(7 downto 0);
      valid_i : in    std_logic;
      data_o  : out   std_logic_vector(7 downto 0);
      valid_o : out   std_logic
    );
  end component;

  component sobel_top is
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
      th_i     : in    std_logic_vector(10 downto 0);
      hcount_o : out   unsigned(9 downto 0);
      vcount_o : out   unsigned(9 downto 0);
      data_o   : out   std_logic_vector(7 downto 0);
      valid_o  : out   std_logic
    );
  end component;

  component rgb2gray is
    port (
      red     : in    std_logic_vector(7 downto 0);
      green   : in    std_logic_vector(7 downto 0);
      blue    : in    std_logic_vector(7 downto 0);
      clk     : in    std_logic;
      valid_i : in    std_logic;
      valid_o : out   std_logic;
      gray    : out   unsigned (7 downto 0)
    );
  end component;

  signal valid_int1 : std_logic;
  signal valid_int2 : std_logic;

  signal data_int1 : unsigned(7 downto 0);
  signal data_int2 : std_logic_vector(7 downto 0);
  signal data_int3 : std_logic_vector(7 downto 0);

  signal vcount     : unsigned(9 downto 0);
  signal vcount_int : unsigned(9 downto 0);
  signal hcount_int : unsigned(9 downto 0);

begin

  i_rgb2gray : component rgb2gray
    port map (
      red     => red_i,
      green   => green_i,
      blue    => blue_i,
      clk     => clk,
      valid_i => valid_i,
      valid_o => valid_int1,
      gray    => data_int1
    );

  i_gauss : component gauss_top
    port map (
      clk     => clk,
      rst     => rst,
      data_i  => std_logic_vector(data_int1),
      valid_i => valid_int1,
      data_o  => data_int2,
      valid_o => valid_int2
    );

  i_sobel : component sobel_top
    port map (
      clk      => clk,
      rst      => rst,
      data_i   => data_int2,
      valid_i  => valid_int2,
      th_i     => th_i,
      hcount_o => hcount_o,
      vcount_o => vcount,
      data_o   => data_o,
      valid_o  => open
    );

  process (clk) is
  begin

    if rising_edge(clk) then
      vcount_o <= vcount;
    end if;

  end process;

end architecture behavioral;
