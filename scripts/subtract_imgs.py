import Image
import sys
import numpy as np



if len(sys.argv) < 3:
    print("Wrong number of arguments. Usage: python3 rgb2txt.py imagepath imagepath")
    quit()

im1 = Image.open(sys.argv[1])
im2 = Image.open(sys.argv[2])

buf1 = np.asarray(im1)
buf2 = np.asarray(im2)

buf3 = buf2 - buf1

im3 = Image.fromarray(buf3);
im3.save("sub.jpg")

#print(mse(im1,im2))
