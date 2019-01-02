from __future__ import print_function

import argparse
import cv2
import ass1

parser = argparse.ArgumentParser(
    description = "Applies thresholding using Otsu's algorithm on a greyscale image"
)
parser.add_argument("--input", required = True)
parser.add_argument("--output", required = True)
parser.add_argument("--threshold", action = "store_true")

args = parser.parse_args()

image = cv2.imread(args.input, cv2.CV_LOAD_IMAGE_GRAYSCALE)

threshold = ass1.otsu(image)[0]
if args.threshold:
    print(threshold)
image = ass1.threshold(image, threshold)

cv2.imwrite(args.output, image)
