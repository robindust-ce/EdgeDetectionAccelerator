from vunit import VUnit

import os.path
from pathlib import Path
from itertools import product

threshold = 0


input_file = Path('.') / "scripts" / "vunit_out" / "input_img.txt"
gray_control = Path('.') / "scripts" / "vunit_out" / "gray_control"
gauss_control = Path('.') / "scripts" / "vunit_out" / "gauss_control"
sobel_control = Path('.') / "scripts" / "vunit_out" / "sobel_control"
input_img = Path('.') / "assets" / "leo.jpg"
python_results = {}

def compare_files(vhdl_out, python_out):
    i = 0
    print("Post check: %s" % str(vhdl_out))
    print("Post check: %s" % str(python_out))
    with vhdl_out.open("r") as foutput:
        with python_out.open("r") as fexpected:
            for expected_line in fexpected:
                got = foutput.readline();
                if not got == expected_line:
                    print("Content mismatch at line %i, got %r expected %r" % (i, got, expected_line))
                    return False
                i += 1
    return True


def make_post_check(gen_gray, gen_gauss, gen_sobel):
    """
    Return a check function to verify test case output
    """

    def post_check(output_path):
        """
        This function recives the output_path of the test
        """

        if gen_gray or gen_gauss or gen_sobel:
            if gen_gray:
                output_file = Path(output_path) / "gray_out.txt"
                if not compare_files(output_file, gray_control):
                    print("Gray error")
                    return False

        if gen_gauss or gen_sobel:
            if gen_gauss:
                output_file = Path(output_path) / "gauss_out.txt"
                if not compare_files(output_file, gauss_control):
                    print("Gauss error")
                    return False

        if gen_sobel:
            output_file = Path(output_path) / "sobel_out.txt"
            if not compare_files(output_file, sobel_control):
                print("Sobel error")
                return False

        return True

    return post_check


def generate_tests(obj):

    for gen_gray, gen_gauss, gen_sobel in product([False, True], [False, True], [False, True]):
        if (not gen_gray) and (not gen_gauss) and (not gen_sobel):
            continue

        ## This configuration name is added as a suffix to the test bench name
        config_name = "gray=%s,gauss=%s,sobel=%s" % (gen_gray, gen_gauss, gen_sobel)

        ## Add the configuration with a post check function to verify the output
        obj.add_config(
            name=config_name,
            generics=dict(gen_gray=gen_gray, gen_gauss=gen_gauss, gen_sobel=gen_sobel),
            post_check=make_post_check(gen_gray, gen_gauss, gen_sobel),
        )


VU = VUnit.from_argv()
LIB = VU.add_library("lib")
LIB.add_source_files(Path(__file__).parent / ".." / "sim" / "edgedetect_tb.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "rgb2gray.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "sobel_top.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "gauss_top.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "linebuffer.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "kernel_top.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "types_lib.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "gauss_kernel.vhd")
LIB.add_source_files(Path(__file__).parent / ".." / "src" / "sobel_kernel.vhd")

TB_GENERATED = LIB.test_bench("edgedetect_tb")

TB_GENERATED.set_generic("input_file", input_file.resolve())
TB_GENERATED.set_generic("threshold", threshold)


for test in TB_GENERATED.get_tests():
    generate_tests(test)

VU.main()
