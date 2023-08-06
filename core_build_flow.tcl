#run with: vivado -mode batch -nolog -nojournal -source core_build_flow.tcl

set outputDir ./build_core/slow
file mkdir $outputDir

set_param general.maxThreads 4

read_vhdl src/rgb2gray.vhd
read_vhdl src/gauss_top.vhd
read_vhdl src/sobel_top.vhd
read_vhdl src/sobel_kernel.vhd
read_vhdl src/gauss_kernel.vhd
read_vhdl src/types_lib.vhd
read_vhdl src/linebuffer.vhd
read_vhdl src/kernel_top.vhd
read_vhdl src/sys_top.vhd
read_vhdl src/edgedetect_top.vhd
read_vhdl src/VGAcontrol.vhd
# read_vhdl src/vga_in_sim.vhd

read_xdc NexysA7_Core.xdc



set_property generic {pipeline=0} [current_fileset]

synth_design -top sys_top -part xc7a100tcsg324-1 -directive AreaOptimized_high

create_clock -add -name sys_clk_pin -period 39.722 -waveform {0 5} [get_ports { clk }]; # 25.175 MHz (VGA 640x480 60 Hz)
write_checkpoint -force $outputDir/post_synth.dcp
# report_utilization -file $outputDir/post_synth_util.rpt
report_clocks

opt_design -directive ExploreWithRemap
place_design
write_checkpoint -force $outputDir/post_place.dcp
route_design
write_checkpoint -force $outputDir/post_route.dcp
# write_bitstream -force $outputDir/sys_top.bit
check_timing
report_utilization -file $outputDir/post_pr_util.rpt
report_timing_summary -file $outputDir/post_pr_timing.rpt




# set outputDir ./build_core/fast
# file mkdir $outputDir
#
# set_property generic {pipeline=1} [current_fileset]
#
# synth_design -top sys_top -part xc7a100tcsg324-1 -directive AlternateRoutability
#
# # create_clock -add -name sys_clk_pin -period 9.804 -waveform {0 5} [get_ports { clk }]; # 148.5 MHz (1080p 60Hz)
# create_clock -add -name sys_clk_pin -period 6.734 -waveform {0 5} [get_ports { clk }];
# write_checkpoint -force $outputDir/post_synth.dcp
# # report_utilization -file $outputDir/post_synth_util.rpt
# report_clocks
#
# opt_design
# place_design
# phys_opt_design
# write_checkpoint -force $outputDir/post_place.dcp
# route_design
# write_checkpoint -force $outputDir/post_route.dcp
# # write_bitstream -force $outputDir/sys_top.bit
# check_timing
# report_utilization -file $outputDir/post_pr_util.rpt
# report_timing_summary -file $outputDir/post_pr_timing.rpt