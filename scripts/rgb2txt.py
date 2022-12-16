from PIL import Image
import sys
import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input_path", help="Path to the input image", required=True)
parser.add_argument("-o", "--output_path", help="Path to the output text file", required=True)
args = parser.parse_args()

im = Image.open(args.input_path)

data = np.asarray(im, dtype=np.uint8)
#fp = open(args.output_path, "w")
with open(args.output_path, "w") as fp:
    z = 0
    for x in data:
        for y in x:
            fp.write("%i,%i,%i\n" % (y[0], y[1], y[2]))


#fp.close()
im.close()
