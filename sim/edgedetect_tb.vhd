library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity edgedetect_tb is
  generic (
    runner_cfg  : string;
    output_path : string;
    threshold   : integer;
    gen_gray    : boolean;
    gen_gauss   : boolean;
    gen_sobel   : boolean;
    input_file  : string
  );
end entity edgedetect_tb;

architecture tb of edgedetect_tb is

  component sobel_top is
    generic (
      tot_lines : integer;
      tot_cols  : integer;
      im_lines  : integer;
      im_cols   : integer
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

  component gauss_top is
    generic (
      tot_lines : integer;
      tot_cols  : integer;
      im_lines  : integer;
      im_cols   : integer
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

  -- Constants
  constant clk_period : time := 5 ns;
  constant tot_lines  : integer := 525;
  constant tot_cols   : integer := 800;
  constant im_lines   : integer := 480;
  constant im_cols    : integer := 640;

  -- rgb2gray
  signal clk              : std_logic;
  signal rst              : std_logic;
  signal input_red        : std_logic_vector(7 downto 0);
  signal input_green      : std_logic_vector(7 downto 0);
  signal input_blue       : std_logic_vector(7 downto 0);
  signal rgb2gray_valid_i : std_logic;
  signal rgb2gray_valid_o : std_logic;
  signal rgb2gray_gray    : unsigned (7 downto 0);

  -- gauss_top
  signal gauss_data_o  : std_logic_vector(7 downto 0);
  signal gauss_valid_o : std_logic;

  -- sobel_top
  signal sobel_data_o  : std_logic_vector(7 downto 0);
  signal sobel_valid_o : std_logic;

  -- Inter-process signals
  signal gray_complete  : std_logic := '0';
  signal gauss_complete : std_logic := '0';
  signal sobel_complete : std_logic := '0';
  signal gray_recv      : std_logic := '0';
  signal gauss_recv     : std_logic := '0';
  signal sobel_recv     : std_logic := '0';

begin

  rgb2gray_inst : component rgb2gray
    port map (
      red     => input_red,
      green   => input_green,
      blue    => input_blue,
      clk     => clk,
      valid_i => rgb2gray_valid_i,
      valid_o => rgb2gray_valid_o,
      gray    => rgb2gray_gray
    );

  main : process is

    procedure send_img is

      file     fread                  : text;
      variable l                      : line;
      variable i                      : integer := 0;
      variable v_red, v_green, v_blue : integer;
      variable semicolon              : character;

    begin

      file_open(fread, input_file, read_mode);

      while not endfile(fread) loop

        wait until rising_edge(clk);

        if (i < 640) then
          readline(fread, l);
          read(l, v_red);
          read(l, semicolon);
          read(l, v_green);
          read(l, semicolon);
          read(l, v_blue);

          rgb2gray_valid_i <= '1';
          input_red        <= std_logic_vector(to_unsigned(v_red, 8));
          input_green      <= std_logic_vector(to_unsigned(v_green, 8));
          input_blue       <= std_logic_vector(to_unsigned(v_blue, 8));
        else
          rgb2gray_valid_i <= '0';
        end if;

        i := (i + 1) mod 800;

      end loop;

      wait until rising_edge(clk);
      rgb2gray_valid_i <= '0';

      file_close(fread);

    end procedure;

  begin

    test_runner_setup(runner, runner_cfg);
    rst <= '0';
    wait for 5 * clk_period;
    rst <= '1';
    wait for 5 * clk_period;

    while test_suite loop

      if run("Test") then

        info(input_file);
        rgb2gray_valid_i <= '0';
        wait for 3 * clk_period;

        gray_recv <= '1' when gen_gray else '0';
        gauss_recv <= '1' when gen_gauss else '0';
        sobel_recv <= '1' when gen_sobel else '0';

        info("start sending image");
        send_img;
        info("done sending image");

        if (gen_sobel) then
          info("wait for sobel");
          wait until sobel_complete = '1';
        elsif (gen_gauss) then
          info("wait for gauss");
          wait until gauss_complete = '1';
        else
          info("wait for gray");
          wait until gray_complete = '1';
        end if;
      end if;

    end loop;

    test_runner_cleanup(runner);
    wait;

  end process main;

  test_runner_watchdog(runner, 10 ms);

  proc_gray : if gen_gray generate

    recv_gray : process is

      file     fwrite : text;
      variable l      : line;
      variable j      : integer := 0;

    begin

      file_open(fwrite, output_path & "/" & "gray_out.txt", write_mode);

      wait until gray_recv = '1';
      wait until rgb2gray_valid_o = '1';
      wait until rising_edge(clk);
      info("receiving gray");

      while j < (480 * 640) loop

        if (rgb2gray_valid_o = '1') then
          write(l, to_string(to_integer(rgb2gray_gray)));
          writeline(fwrite, l);
          j := j + 1;
        --         info("pix " & to_string(to_integer(gray)));
        else
          wait until rgb2gray_valid_o = '1';
        end if;

        wait until rising_edge(clk);

      end loop;

      info("Received grayscale img");
      gray_complete <= '1';
      file_close(fwrite);
      wait;

    end process recv_gray;

  end generate proc_gray;

  g_gauss : if gen_gauss or gen_sobel generate

    gauss_top_inst : component gauss_top
      generic map (
        tot_lines => tot_lines,
        tot_cols  => tot_cols,
        im_lines  => im_lines,
        im_cols   => im_cols
      )
      port map (
        clk     => clk,
        rst     => rst,
        data_i  => std_logic_vector(rgb2gray_gray),
        valid_i => rgb2gray_valid_o,
        data_o  => gauss_data_o,
        valid_o => gauss_valid_o
      );

  end generate g_gauss;

  proc_gauss : if gen_gauss generate

    recv_gauss : process is

      file     fwrite : text;
      variable l      : line;
      variable j      : integer := 0;

    begin

      file_open(fwrite, output_path & "/" & "gauss_out.txt", write_mode);

      wait until gauss_recv = '1';
      wait until gauss_valid_o = '1';
      wait until rising_edge(clk);
      info("receiving gauss");

      while j < (480 * 640) loop

        if (gauss_valid_o = '1') then
          write(l, to_string(to_integer(unsigned(gauss_data_o))));
          writeline(fwrite, l);
          j := j + 1;
        else
          wait until gauss_valid_o = '1';
        end if;

        wait until rising_edge(clk);

      end loop;

      info("Received gauss img");
      gauss_complete <= '1';
      file_close(fwrite);
      wait;

    end process recv_gauss;

  end generate proc_gauss;

  g_sobel : if gen_sobel generate

    sobel_top_inst : component sobel_top
      generic map (
        tot_lines => tot_lines,
        tot_cols  => tot_cols,
        im_lines  => im_lines,
        im_cols   => im_cols
      )
      port map (
        clk      => clk,
        rst      => rst,
        data_i   => gauss_data_o,
        valid_i  => gauss_valid_o,
        th_i     => std_logic_vector(to_unsigned(threshold, 11)),
        hcount_o => open,
        vcount_o => open,
        data_o   => sobel_data_o,
        valid_o  => sobel_valid_o
      );

    recv_sobel : process is

      file     fwrite : text;
      variable l      : line;
      variable j      : integer := 0;

    begin

      file_open(fwrite, output_path & "/" & "sobel_out.txt", write_mode);

      wait until sobel_recv = '1';
      wait until sobel_valid_o = '1';
      wait until rising_edge(clk);

      info("receiving sobel");

      while j < (480 * 640) loop

        if (sobel_valid_o = '1') then
          write(l, to_string(to_integer(unsigned(sobel_data_o))));
          writeline(fwrite, l);
          j := j + 1;
        --         info("pix " & to_string(to_integer(gray)));
        else
          wait until sobel_valid_o = '1';
        end if;

        wait until rising_edge(clk);

      end loop;

      info("Received sobel img");
      sobel_complete <= '1';
      file_close(fwrite);
      wait;

    end process recv_sobel;

  end generate g_sobel;

  clk_process : process is
  begin

    clk <= '1';
    wait for clk_period / 2;
    clk <= '0';
    wait for clk_period / 2;

  end process clk_process;

end architecture tb;
