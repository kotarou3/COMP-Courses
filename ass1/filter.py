from __future__ import print_function

import argparse
import cv2
import numpy
import ass1

def gridSize(str):
    n = int(str)
    if not n >= 1:
        raise argparse.ArgumentTypeError("Grid size must be a positive integer")
    return n

parser = argparse.ArgumentParser(
    description = "Applies thresholding using Otsu's algorithm, then applies a "
                  "closing morphological filter with a 5-pixel diametre circle."
)
parser.add_argument("--input", required = True)
parser.add_argument("--output", required = True)

args = parser.parse_args()

image = cv2.imread(args.input, cv2.CV_LOAD_IMAGE_GRAYSCALE)

# Since we want the filter to be independent of the orientation of the source
# image, the kernel needs to be circularly symmetric. This likely means that
# the circle is the only good kernel to use.
# Assumption: All input images will be of the same resolution (dpi) regardless
#             of pixel dimensions, so we choose a fixed kernel size
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))

# Since the graphite flakes will be black, they are treated as a "background"
# for morphological filtering. Since they also tend to be round, if we're going
# to apply a filter, it would be closing, to "round out" the background
image = cv2.morphologyEx(image.astype(numpy.uint8), cv2.MORPH_CLOSE, kernel)

image = ass1.threshold(image)
cv2.imwrite(args.output, image)
