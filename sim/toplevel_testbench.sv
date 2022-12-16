module tb;
  string path = "/insert/path/to/inputfile/here";
  int 	 fd_in, fd_out1, fd_out2, fd_out3; 			// Variable for file descriptor handle
  localparam threshold = 0;
  string line; 			// String value read from the file

  int red, green, blue, gray, data_internal, data_out;
  reg clk, rst, valid_in, valid_out, valid_mid1, valid_mid2;
  int i, j, k, l;

  rgb2gray i_rgb2gray
       (.red(red[7:0]),
        .green(green[7:0]),
        .blue(blue[7:0]),
        .valid_i(valid_in),
        .valid_o(valid_mid1),
        .CLK(clk),
        .gray(gray[7:0]));

  gauss_top i_top
        (.data_i(gray[7:0]),
        .valid_i(valid_mid1),
        .clk(clk),
        .rst(rst),
        .valid_o(valid_mid2),
        .data_o(data_internal[7:0]));

  sobel_top i_stop
        (.data_i(data_internal[7:0]),
        .valid_i(valid_mid2),
        .clk(clk),
        .rst(rst),
        .valid_o(valid_out),
        .th_i(threshold[10:0]),
        .data_o(data_out[7:0]));


  always
  begin
    clk = 1;
    #10;
    clk = 0;
    #10;
  end


  initial begin
    fd_in = $fopen ({path,"input"}, "r");


    @(posedge clk);
    valid_in <= 0;
    rst = 0;

    #100;

    @(posedge clk);
    rst = 1;

    #100;
    i = 0;
    // Get the next line and display
    while (!$feof(fd_in)) begin
        if (i < 640) begin
            $fgets(line, fd_in);
            @(posedge clk);
            valid_in <= 1;
            $sscanf (line, "%d,%d,%d", red, green, blue);
            $display ("Line: %0d, Red: %0d Green: %0d Blue: %0d", i, red, green, blue);
        end else begin

            @(posedge clk);
            valid_in <= 0;
        end

        i = (i+1) % 800;
    end
    @(posedge clk);
    valid_in <= 0;

    // Close this file handle
    $fclose(fd_in);

  end

  //Save image after sobel filter
  initial
  begin
    fd_out1 = $fopen ({path,"sobel_out"}, "w");
    j = 0;
    @(posedge clk);
    while (j < (480*640)) begin
        if (valid_out == 1) begin
            $display ("PXL out: %d", data_out);
            $fdisplay (fd_out1, "%0d", data_out);
            j++;
        end
        @(posedge clk);
    end
    $fclose(fd_out1);
    $display("Testbench done!");
    $stop;
  end

  //Save image after grayscale conversion
  initial
  begin
    fd_out2 = $fopen ({path,"gray_out"}, "w");

    k = 0;
    @(posedge clk);
    while (k < (480*640)) begin
        if (valid_mid1 == 1) begin
            $fdisplay (fd_out2, "%0d", gray);
            k++;
        end
        @(posedge clk);
    end
    $fclose(fd_out2);
  end

  //Save image after gaussian blur
  initial
  begin
    fd_out3 = $fopen ({path,"gauss_out"}, "w");

    l = 0;
    @(posedge clk);
    while (l < (480*640)) begin
        if (valid_mid2 == 1) begin
            $fdisplay (fd_out3, "%0d", data_internal);
            l++;
        end
        @(posedge clk);
    end
    $fclose(fd_out3);
  end

endmodule