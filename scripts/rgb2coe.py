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
fp = open(args.output_path, "w")

original_stdout = sys.stdout
sys.stdout = fp

print("memory_initialization_radix=10;")
print("memory_initialization_vector=")

z = 0
cnt = 1
for x in data:
    for y in x:
        if (cnt == (640*480)):
            break
        z = ((y[2]>>4)<<8)+((y[1]>>4)<<4)+(y[0]>>4)
        print(str(z)+",")
        cnt+=1

z = ((data[-1][-1][2]>>4)<<8)+((data[-1][-1][1]>>4)<<4)+(data[-1][-1][0]>>4)
print(str(z)+";", end = "")

sys.stdout = original_stdout


fp.close()
im.close()
