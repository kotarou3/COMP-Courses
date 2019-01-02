from __future__ import print_function
import argparse
import os

import cv2
import numpy

import ass2

parser = argparse.ArgumentParser()
parser.add_argument("num", type = int, choices = range(1, 5))
parser.add_argument("input_folder")
parser.add_argument("output_folder")

args = parser.parse_args()

step1Output = os.path.join(args.output_folder, "step1")
step2Output = os.path.join(args.output_folder, "step2")
step3Output = os.path.join(args.output_folder, "step3")
step4Output = os.path.join(args.output_folder, "step4")
if args.num >= 1:
    os.mkdir(step1Output)
if args.num >= 2:
    os.mkdir(step2Output)
if args.num >= 3:
    os.mkdir(step3Output)
if args.num >= 4:
    os.mkdir(step4Output)

def saveStep2(filenameA, imageA, keypointsA, filenameB, imageB, keypointsB, matches):
    matchesImage = ass2.drawMatches(imageA, keypointsA, imageB, keypointsB, matches)
    outputFilename = "{}_{}_{}_{}_{}.jpg".format(
        filenameA, len(keypointsA),
        filenameB, len(keypointsB),
        len(matches)
    )
    cv2.imwrite(os.path.join(step2Output, outputFilename), matchesImage)

def saveStep3(filenameA, imageA, filenameB, homography):
    warpedImage = ass2.warpPerspective(imageA, homography)[0]
    outputFilename = "{}_{}.jpg".format(filenameA, filenameB)
    cv2.imwrite(os.path.join(step3Output, outputFilename), warpedImage)

images = []
matchedPairsMatrix = []
pairwiseHomographies = []
for filename in os.listdir(args.input_folder):
    image = cv2.imread(os.path.join(args.input_folder, filename))
    if type(image) == type(None):
        print("Failed to read {}. Skipping".format(filename))
        continue

    print("{}: {}".format(len(images), filename))
    # TODO: Convert to linear space

    if args.num >= 1:
        keypoints, descriptors = ass2.detectFeatures(image)
        cv2.imwrite(os.path.join(step1Output, filename), ass2.drawKeypoints(image, keypoints))

    if args.num >= 2:
        matchedPairs = []
        homographies = []
        for [filenameB, imageB, keypointsB, descriptorsB], matchedPairsB, homographiesB in zip(images, matchedPairsMatrix, pairwiseHomographies):
            matches = ass2.matchFeatures(descriptors, descriptorsB)
            saveStep2(filename, image, keypoints, filenameB, imageB, keypointsB, matches)

            matchesB = ass2.matchFeatures(descriptorsB, descriptors)
            saveStep2(filenameB, imageB, keypointsB, filename, image, keypoints, matchesB)

            if args.num >= 3:
                homography, matches = ass2.findHomography(image, keypoints, keypointsB, matches)
                if type(homography) != type(None):
                    saveStep3(filename, image, filenameB, homography)
                homographies.append(homography)

                homographyB, matchesB = ass2.findHomography(imageB, keypointsB, keypoints, matchesB)
                if type(homographyB) != type(None):
                    saveStep3(filenameB, imageB, filename, homographyB)
                homographiesB.append(homographyB)

            matchedPairs.append(matches)
            matchedPairsB.append(matchesB)

        matchedPairs.append([]) # Ignore matching to self
        homographies.append(numpy.identity(3)) # Homography-to-self is the identity
        matchedPairsMatrix.append(matchedPairs)
        pairwiseHomographies.append(homographies)

    images.append([filename, image, keypoints, descriptors])

if args.num >= 4:
    print("Stitching panorama...")
    trees = ass2.findStitchingTrees(matchedPairsMatrix)
    visitedImages = set()
    t = 0
    for t, tree in enumerate(trees):
        result = ass2.stitchBestPanorama([i[1] for i in images], pairwiseHomographies, tree)
        print("Saving panorama {} with dimensions {}".format(t, tuple(result.shape[:2])))
        outputFilename = "output{}.jpg".format(t)
        cv2.imwrite(os.path.join(step4Output, outputFilename), result)

        for edge in tree:
            visitedImages.add(edge[0])
            visitedImages.add(edge[1])
    for i, image in enumerate(images):
        if i not in visitedImages:
            t += 1
            print("Saving panorama {} with dimensions {}".format(t, tuple(image[1].shape[:2])))
            outputFilename = "output{}.jpg".format(t)
            cv2.imwrite(os.path.join(step4Output, outputFilename), image[1])
