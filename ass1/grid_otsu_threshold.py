from __future__ import print_function

import argparse
import math

import cv2

import ass1

def gridSize(str):
    n = int(str)
    if not n >= 1:
        raise argparse.ArgumentTypeError("Grid size must be a positive integer")
    return n

parser = argparse.ArgumentParser(
    description = "Applies adaptive thresholding using Otsu's algorithm on N"
                  "approximately equally sized squares of a greyscale image"
)
parser.add_argument("--input", required = True)
parser.add_argument("--output", required = True)
parser.add_argument("n", type = gridSize)

args = parser.parse_args()

image = cv2.imread(args.input, cv2.CV_LOAD_IMAGE_GRAYSCALE)
sideLengths = [int(math.ceil(d / math.sqrt(args.n))) for d in image.shape]
image = ass1.gridOtsuThreshold(image, sideLengths)
cv2.imwrite(args.output, image)
