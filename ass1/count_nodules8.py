from __future__ import print_function

import argparse
import cv2
import ass1

def pixelCount(str):
    n = int(str)
    if not n >= 1:
        raise argparse.ArgumentTypeError("Minimum pixel count must be a positive integer")
    return n

parser = argparse.ArgumentParser(
    description = "Finds the 8-connected components of a binary image."
)
parser.add_argument("--input", required = True)
parser.add_argument("--optional_output")
parser.add_argument("--size", type = pixelCount, required = True)

args = parser.parse_args()

image = cv2.imread(args.input, cv2.CV_LOAD_IMAGE_GRAYSCALE)
image = ass1.connectedComponents(image, minimumPixels = args.size, is8Connected = True)
print(image.max())

if args.optional_output:
    image = ass1.colourComponents(image)
    cv2.imwrite(args.optional_output, image)
