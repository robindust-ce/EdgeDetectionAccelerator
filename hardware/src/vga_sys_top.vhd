----------------------------------------------------------------------------------
-- Module Name:    vga_sys_top
-- Project Name:   Edge Detection Accelerator
-- Target Devices: Digilent NexysA7
-- Description:
-- This is the toplevel module for the NexysA7 VGA Edge Detection example project.
-- It includes block memory holding a 640x480 (RGB444) image. The sys_top module
-- that detects edges and the VGAControl module which displays the resulting image
-- via the VGA connector.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity vga_sys_top is
  port (
    clk100mhz : in    std_logic;
    rst       : in    std_logic;
    sw        : in    std_logic_vector(10 downto 0);
    vga_r     : out   std_logic_vector(3 downto 0);
    vga_g     : out   std_logic_vector(3 downto 0);
    vga_b     : out   std_logic_vector(3 downto 0);
    vga_hs    : out   std_logic;
    vga_vs    : out   std_logic
  );
end entity vga_sys_top;

architecture behavioral of vga_sys_top is

  component blk_mem_gen_1 is
    port (
      addra : in    std_logic_vector(18 downto 0);
      clka  : in    std_logic;
      douta : out   std_logic_vector(11 downto 0)
    );
  end component;

  component clk_wiz_0 is
    port (
      clk_in1  : in    std_logic;
      clk_out1 : out   std_logic;
      resetn   : in    std_logic
    );
  end component;

  component vgacontrol is
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
  end component;

  component edgedetect_top is
    generic (
      tot_lines : integer := 525;
      tot_cols  : integer := 800;
      im_lines  : integer := 480;
      im_cols   : integer := 640
    );
    port (
      clk      : in    std_logic;
      rst      : in    std_logic;
      valid_i  : in    std_logic;
      red_i    : in    std_logic_vector(7 downto 0);
      green_i  : in    std_logic_vector(7 downto 0);
      blue_i   : in    std_logic_vector(7 downto 0);
      th_i     : in    std_logic_vector(10 downto 0);
      hcount_o : out   unsigned(9 downto 0);
      vcount_o : out   unsigned(9 downto 0);
      data_o   : out   std_logic_vector(7 downto 0)
    );
  end component;

  component vga_in_sim is
    generic (
      total_row_nr  : integer := 525;
      active_row_nr : integer := 480;
      total_col_nr  : integer := 800;
      active_col_nr : integer := 640
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
  end component;

  signal clk      : std_logic;
  signal mem_out  : std_logic_vector(11 downto 0);
  signal mem_addr : std_logic_vector(18 downto 0);

  signal valid_vga_in  : std_logic;
  signal valid_sys_top : std_logic;
  signal red_vga_in    : std_logic_vector(7 downto 0);
  signal green_vga_in  : std_logic_vector(7 downto 0);
  signal blue_vga_in   : std_logic_vector(7 downto 0);
  signal data_sys_top  : std_logic_vector(7 downto 0);

  signal hcount : unsigned(9 downto 0);
  signal vcount : unsigned(9 downto 0);

  type count_ff is array(3 downto 0) of unsigned(9 downto 0);

  signal hcount_ff : count_ff;
  signal vcount_ff : count_ff;

begin

  i_blk_mem : component blk_mem_gen_1
    port map (
      addra => mem_addr,
      clka  => clk,
      douta => mem_out
    );

  i_clk_wiz : component clk_wiz_0
    port map (
      clk_in1  => clk100mhz,
      clk_out1 => clk,
      resetn   => rst
    );

  i_vga_in_sim : component vga_in_sim
    port map (
      clk     => clk,
      rst     => rst,
      data_i  => mem_out,
      addr_o  => mem_addr,
      valid_o => valid_vga_in,
      red_o   => red_vga_in,
      green_o => green_vga_in,
      blue_o  => blue_vga_in
    );

  i_edgedetect_top : component edgedetect_top
    port map (
      clk      => clk,
      rst      => rst,
      valid_i  => valid_vga_in,
      red_i    => red_vga_in,
      green_i  => green_vga_in,
      blue_i   => blue_vga_in,
      th_i     => sw,
      hcount_o => hcount,
      vcount_o => vcount,
      data_o   => data_sys_top
    );

  i_vga_out : component vgacontrol
    port map (
      clk      => clk,
      dat_i    => data_sys_top,
      vcount_i => vcount_ff(1),
      hcount_i => hcount_ff(2),
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b,
      vga_hs   => vga_hs,
      vga_vs   => vga_vs
    );

  ff : process (clk) is
  begin

    if rising_edge(clk) then
      hcount_ff <= hcount_ff(2 downto 0) & hcount;
      vcount_ff <= vcount_ff(2 downto 0) & to_unsigned(to_integer(vcount) - 1, 10);
    end if;

  end process ff;

end architecture behavioral;
