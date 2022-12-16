#run with: vivado -source build_flow.tcl

set outputDir ./build_vga
set ProjName EdgeDetection
file mkdir $outputDir

set_param general.maxThreads 4

create_project EdgeDetection ./$outputDir -part xc7a100tcsg324-1 -force

add_files src/rgb2gray.vhd
add_files src/gauss_top.vhd
add_files src/sobel_top.vhd
add_files src/sobel_kernel.vhd
add_files src/gauss_kernel.vhd
add_files src/types_lib.vhd
add_files src/linebuffer.vhd
add_files src/kernel_top.vhd
add_files src/vga_sys_top.vhd
add_files src/edgedetect_top.vhd
add_files src/VGAcontrol.vhd
add_files src/vga_in_sim.vhd

# add_files large_img.coe
import_ip src/blk_mem_gen_1.xci
file copy -force assets/large_img.coe $outputDir/$ProjName.srcs/sources_1/ip/blk_mem_gen_1/
import_ip src/clk_wiz_0.xci

add_files -fileset constrs_1 NexysA7_VGA.xdc
add_files -fileset sim_1 sim/toplevel_testbench.sv
# set_property file_type {VHDL 2008} [get_files *_tb.vhd]
# import_files -force -norecurse
set_property top vga_sys_top [current_fileset]


update_compile_order -fileset sources_1

# launch_runs synth_1
# wait_on_run synth_1
# puts "Synthesis done!"

# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# puts "Implementation done!"

