from PIL import Image
import sys
import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input_path", help="Path to the input text file", required=True)
parser.add_argument("-o", "--output_path", help="Path to the output image", required=True)
parser.add_argument("-x", "--image_width", help="Path to the output image", type=int, required=False, default=640)
parser.add_argument("-y", "--image_height", help="Path to the output image", type=int, required=False, default=480)
args = parser.parse_args()


im = Image.new('L', (args.image_width, args.image_height))
data_out = []

fp = open(args.input_path, "r")
Lines = fp.readlines()

for line in Lines:
    data_out.append(int(line.strip()))

im.putdata(data_out)

im.save(args.output_path)

im.close()
fp.close()
