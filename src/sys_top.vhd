----------------------------------------------------------------------------------
-- Module Name:    sys_top
-- Project Name:   Edge Detection Accelerator
-- Target Devices:
-- Description:
-- This is the toplevel module of the Edge Detection Accelerator. It takes a
-- VGA-like input stream of RGB888 pixels and outputs the stream of the grayscale
-- image after edge detection. Therefore, it instantiates the rgb2gray module
-- for the grayscale conversion, the gauss_top module for the gaussian smoothing
-- filter, the sobel_top module for the sobel filter and the VGAControl module
-- for the VGA output. Using th_i a threshold for the output of the sobel filter
-- can be set. If th_i is zero, no threshold is applied.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity sys_top is
  generic (
    pipeline : integer := 1;
    im_lines : integer := 480;
    im_cols  : integer := 640
  );
  port (
    clk     : in    std_logic;
    rst     : in    std_logic;
    valid_i : in    std_logic;
    red_i   : in    std_logic_vector(7 downto 0);
    green_i : in    std_logic_vector(7 downto 0);
    blue_i  : in    std_logic_vector(7 downto 0);
    th_i    : in    std_logic_vector(10 downto 0);

--     hcount_o : out   unsigned(9 downto 0);
--     vcount_o : out   unsigned(9 downto 0);
--     data_o   : out   std_logic_vector(7 downto 0)
    VGA_R   : out   std_logic_vector(3 downto 0);
    VGA_G   : out   std_logic_vector(3 downto 0);
    VGA_B   : out   std_logic_vector(3 downto 0);
    VGA_HS  : out   std_logic;
    VGA_VS  : out   std_logic
  );
end entity sys_top;

architecture behavioral of sys_top is

  component gauss_top is
    generic (
      im_lines : integer := 480;
      im_cols  : integer := 640
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
      pipeline : integer := 1;
      im_lines : integer := 480;
      im_cols  : integer := 640
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

     component VGAcontrol
         generic(
             TOTAL_ROW_NR        : integer := 525;
             ACTIVE_ROW_NR       : integer := 480;
             TOTAL_COL_NR        : integer := 800;
             ACTIVE_COL_NR       : integer := 640;
             VERT_FRONT_PORCH    : integer := 10;
             VERT_BACK_PORCH     : integer := 33;
             HOR_FRONT_PORCH     : integer := 16;
             HOR_BACK_PORCH      : integer := 48
         );
         port(
             CLK             : in    std_logic;
             DAT_i           : in    std_logic_vector(7 downto 0);
             vcount_i        : in unsigned(9 downto 0);
             hcount_i        : in unsigned(9 downto 0);
             VGA_R           : out   std_logic_vector(3 downto 0);
             VGA_G           : out   std_logic_vector(3 downto 0);
             VGA_B           : out   std_logic_vector(3 downto 0);
             VGA_HS          : out   std_logic;
             VGA_VS          : out   std_logic
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
    generic map (
      pipeline => pipeline
    )
    port map (
      clk      => clk,
      rst      => rst,
      data_i   => data_int2,
      valid_i  => valid_int2,
      th_i     => th_i,
      hcount_o => hcount_int,
      vcount_o => vcount,
      data_o   => data_int3,
      valid_o  => open
    );

     i_vga_out : VGAControl
         port map (
             CLK => clk,
             DAT_i => data_int3,
             vcount_i => vcount_int,
             hcount_i => hcount_int,
             VGA_R => VGA_R,
             VGA_G => VGA_G,
             VGA_B => VGA_B,
             VGA_HS => VGA_HS,
             VGA_VS => VGA_VS
             );

  process (clk) is
  begin

    if rising_edge(clk) then
      vcount_int <= vcount;
    end if;

  end process;

end architecture behavioral;
