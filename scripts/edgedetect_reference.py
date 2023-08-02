import argparse
import numpy as np
from skimage import io

def save_as_text(img, filename):
    if len(img.shape) == 3:
        height, width, channel = img.shape
    else:
        height, width = img.shape
        channel = 1

    txt = []

    for y in range(height):
        for x in range(width):
            if channel == 1:
                txt.append(str(img[y, x].astype(np.uint8)))
            else:
                txt.append(",".join(np.char.mod("%d", img[y, x])))

    with open(filename, "w") as output:
        output.write("\n".join(txt))
        output.write("\n")

    return txt


def to_grayscale(img):
    grayscale_image = np.zeros((img.shape[0], img.shape[1]))

    for y in range(img.shape[0]):
        for x in range(img.shape[1]):

            red = img[y, x][0]
            green = img[y, x][1]
            blue = img[y, x][2]

            grayscale_image[y, x] = (
                (red >> 3)
                + (red >> 5)
                + (red >> 6)
                + (green >> 1)
                + (green >> 4)
                + (green >> 5)
                + (blue >> 3)
            )

    return grayscale_image


def apply_gauss(img):
    kernel = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]])
    kernel_width, _ = kernel.shape

    copy = np.zeros((img.shape[0] + kernel_width - 1, img.shape[1] + kernel_width - 1))
    offset = kernel_width // 2

    # Copy Image into larger image with black border
    copy[offset : offset + img.shape[0], offset : offset + img.shape[1]] = img
    target = np.zeros_like(copy)

    for y in range(1, copy.shape[0] - 1):
        for x in range(1, copy.shape[1] - 1):
            acc = np.sum(
                copy[y - offset : y + offset + 1, x - offset : x + offset + 1] * kernel
            )
            target[y, x] = int(acc) >> 4

    return target[1:-1,1:-1]


def apply_sobel(img, threshold):
    width, height = img.shape
    kernel_width = 3
    copy = np.zeros((img.shape[0] + kernel_width - 1, img.shape[1] + kernel_width - 1))
    offset = kernel_width // 2

    # Copy Image into larger image with black border
    copy[offset : offset + img.shape[0], offset : offset + img.shape[1]] = img
    copy = copy.astype(np.uint8)
    target_x = np.zeros_like(copy)
    target_y = np.zeros_like(copy)
    target_xy = np.zeros_like(copy)

    for y in range(1, copy.shape[0] - 1):
        for x in range(1, copy.shape[1] - 1):
            values = copy[y - offset : y + offset + 1, x - offset : x + offset + 1]
            acc_x = values[0, 0] + (values[1, 0] << 1) + values[2, 0]
            acc_x -= values[0, 2] + (values[1, 2] << 1) + values[2, 2]

            acc_y = values[0, 0] + (values[0, 1] << 1) + values[0, 2]
            acc_y -= values[2, 0] + (values[2, 1] << 1) + values[2, 2]

            acc_x = abs(acc_x)
            acc_y = abs(acc_y)

            result_xy = acc_x + acc_y

            acc_x = min(acc_x, 255)
            acc_y = min(acc_y, 255)

            target_x[y, x] = acc_x
            target_y[y, x] = acc_y
            target_xy[y, x] = min(result_xy, 255);

            if threshold > 0:
                for l in range(0,480):
                    for k in range(0,640):
                        if sobel_xy[l,k] < threshold:
                            sobel_xy[l,k] = 0
                        else:
                            sobel_xy[l,k] = 255


    return target_xy[1:-1,1:-1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--filepath", metavar="path_to_file", required=True)
    parser.add_argument("-t", "--threshold", required=False, type=int, default=0)
    args = parser.parse_args()
    img = io.imread(args.filepath)

    python_results = {}
    python_results["gray_out"] = to_grayscale(img)
    python_results["gauss_out"] = apply_gauss(python_results["gray_out"])
    sobel_xy = apply_sobel(python_results["gauss_out"], args.threshold)

    python_results["sobel_out"] = sobel_xy

    save_as_text(python_results["gray_out"], "scripts/vunit_out/gray_control")
    save_as_text(python_results["gauss_out"], "scripts/vunit_out/gauss_control")
    save_as_text(python_results["sobel_out"], "scripts/vunit_out/sobel_control")


if __name__ == "__main__":
    main()
