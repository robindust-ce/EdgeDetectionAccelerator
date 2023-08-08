## Edge Detection Accelerator

- [Description](#description)
- [Area usage and maximum frequency](#area-usage-and-maximum-frequency)
- [Simulation](#simulation)
- [Reference design](#reference-design)

![VUNIT Tests](https://github.com/robindust-ce/EdgeDetectionAccelerator/actions/workflows/tests.yaml/badge.svg)

## Description

The Edge Detection Accelerator consists of three main stages: RGB to Grayscale conversion, a Gaussian Smoothing Filter and a Sobel Filter. The two filter stages operate on 3 by 3 pixel matrices. Therefore, linebuffers are used to buffer incoming lines of pixels. This accelerator operates directly on the pixel stream and therefore does not require buffering entire frames, which results in low memory usage.

![Block Diagram](assets/blockdiagram.png?raw=true "")

The grayscale conversion is implemented as the sum of multiple bitshifts according to this formula:

```C
gray = red >> 3 + red >> 5 + red >> 6 + green >> 1 + green >> 4 + green >> 5 + blue >> 3
```
The gaussian smoothing is implemented via a multiply-accumulate operation using an integer filter kernel and shifting the result by 4 bits to the right:

        [ 1 2 1 ]
    K = [ 2 4 2 ]
        [ 1 2 1 ]

The sobel operator is applied in the x- and y-direction of the image, which results in two different filter kernels X and Y. Both are applied simultaneously using multiply-accumulate operations. The directional results are added and optionally compared against a threshold to exclude weak edges.


        [ 1  0 -1 ]       [ 1  2  1 ]
    X = [ 2  0 -2 ]   Y = [ 0  0  0 ]
        [ 1  0 -1 ]       [-1 -2 -1 ]

The sobel kernel module is the most complex part of the design and forms a critical path for timing. It therefore implements a pipelined version in addition to the non-pipelined version, which can be selected using a VHDL generic. The pipelined version allows higher clock speeds and therefore higher image resolutions and refresh rates, while the non-pipelined variant uses less resources.

The following images show the accelerator output at it's different stages captured in simulation:

Original Image             |  Gauss Smoothing
:-------------------------:|:-------------------------:
![original](assets/leo.jpg?raw=true "")  |  ![gauss](assets/gauss.jpg?raw=true "")
Sobel Filter             |  Sobel Filter with threshold
![sobel](assets/sobel.jpg?raw=true "")  |  ![sobel threshold](assets/sobel_th.jpg?raw=true "")

## Area usage and maximum frequency
Two different design variants were built for this project. The build results are summarized in the following table.

| | Min. Utilization Design | Max. Performance Design |
| ----- | ----- | ----- |
| Pixel Clock (MHz) | 25.175 | 148.5 |
| Pixel Latency (clock cycles) | 2885 (~56 µs) | 2889 (~28 µs)|
| Slices | 695 | 750 |
| LUTs (total) | 2214 | 2363 |
| LUTs as Distributed RAM | 1440 | 1440 |
| Registers | 330 | 574 |

(last updated: 06.08.2023, commit f23d32e)

The min. utilization design is not pipelined, while the max. performance design uses pipelining on critical paths resulting in a significantly higher Fmax and moderately increased resource utilization. The min. utilization device was compiled with the appropriate pixel clock frequency for the standard VGA 640x480 resolution at 60 Hz. The max. performance design can support a pixel clock frequency for 1080p (1920x1080) at 60 Hz.


The two designs were also built using different Vivado compilation strategies (see core_build_flow.tcl).

Min. Utilization Design: AreaOptimized_high / Area_ExploreWithRemap

Max. Performance Design: AlternateRoutability / RunPhysOpt

```console
vivado -mode batch -nolog -nojournal -source core_build_flow.tcl
```

## Simulation

Requirements:

The simulation uses the ![VUNIT framework](https://vunit.github.io/) in combination with ![GHDL](https://ghdl.github.io/ghdl/).
![Other simulators](https://vunit.github.io/cli.html#simulator-selection) might work but were not tested.

```sh
# Python
sudo apt-get install python3.8

# Python packages
pip install pillow numpy pathlib scikit-image argparse vunit_hdl

# Simulator (see VUNIT supported simulators)
sudo apt-get install ghdl
```

The verification is done using a reference implementation in Python. The simulation converts the "leo.jpg" file to a text format and feeds it to the VHDL and Python implementations. Results are compared and differences reported. Example usage:

```console
usr:~$ python3 scripts/run.py -l
lib.edgedetect_tb.gray=False,gauss=False,sobel=True.Test
lib.edgedetect_tb.gray=False,gauss=True,sobel=False.Test
lib.edgedetect_tb.gray=False,gauss=True,sobel=True.Test
lib.edgedetect_tb.gray=True,gauss=False,sobel=False.Test
lib.edgedetect_tb.gray=True,gauss=False,sobel=True.Test
lib.edgedetect_tb.gray=True,gauss=True,sobel=False.Test
lib.edgedetect_tb.gray=True,gauss=True,sobel=True.Test
Listed 7 tests

usr:~$ python3 scripts/run.py -v "lib.edgedetect_tb.gray=True,gauss=False,sobel=False.Test"
...
pass (P=1 S=0 F=0 T=1) lib.edgedetect_tb.gray=True,gauss=False,sobel=False.Test (10.3 seconds)

==== Summary ====================================================================
pass lib.edgedetect_tb.gray=True,gauss=False,sobel=False.Test (10.3 seconds)
=================================================================================
pass 1 of 1
=================================================================================
Total time was 10.3 seconds
Elapsed time was 10.3 seconds
=================================================================================
All passed!

```
The different test cases define, which stages of the algorithm should be recorded and compared with the reference implementation to reduce runtime. Results are stored under repo_dir/scripts/vunit_out. In addition all scripts can be called independently (e.g. for converting txt to img and vice versa).
The "gray=True,gauss=True,sobel=True.Test" testcase is also run as a ![GitHub Action](https://github.com/robindust-ce/EdgeDetectionAccelerator/actions) on pull requests and the vunit_out folder is stored as an artifact.

## Reference Design

The reference design uses the Digilent Nexys A7. As the board does not have any video input ports the incoming pixel stream is simulated. The image is stored in BRAMs and continuously read and provided to the Edge Detection Accelerator in a VGA-like fashion. The pixel stream of the accelerator output is displayed using the VGA output at a resolution of 640 by 480 pixels at 60 Hz. Using the slide switches of the Nexys A7 the threshold of the sobel stage can be adjusted. If all switches are switched off no threshold is applied.
The VGA_build_flow.tcl script can be used to create a vivado project with the reference design.

```console
vivado -mode batch -nolog -nojournal -source VGA_build_flow.tcl
```

![](assets/vga_demo.jpg?raw=true "")


Future Work (in progress): Add ![Nexys Video](https://digilent.com/reference/programmable-logic/nexys-video/reference-manual) reference design with HDMI sink and source.