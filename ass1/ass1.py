from __future__ import division
import math
import operator

import cv2
import numpy

from hsluv import hsluv_to_rgb
from union_find import UnionFind2D

def otsu(image):
    histogram = numpy.bincount(image.flatten())
    # Calculations can result in very large integers, so we force 64-bit ints.
    # Bigints (long) would be better, but much much slower
    histogram = histogram.astype(numpy.uint64)
    assert(numpy.sum(histogram) == image.size)

    maxInterclassVar = 0
    maxInterclassVarT = None

    # demean = "denormalised mean" = mean multiplied by the count
    count0 = 0
    count1 = image.size
    demean0 = 0
    demean1 = numpy.dot(numpy.arange(len(histogram)), histogram)
    for t in xrange(len(histogram)):
        count0 += histogram[t]
        count1 -= histogram[t]
        demean0 += t * histogram[t]
        demean1 -= t * histogram[t]

        if count0 == 0 or count1 == 0:
            # Avoid dividing by 0.
            # Nothing on one side of the threshold, so definitely wouldn't be a
            # valid maximum interclass variation either
            continue

        meanDiff = demean1 / count1 - demean0 / count0
        interclassVar = count0 * count1 * meanDiff * meanDiff

        if interclassVar > maxInterclassVar:
            maxInterclassVar = interclassVar
            maxInterclassVarT = t

    return (maxInterclassVarT, maxInterclassVar)

def threshold(image, t = None, value = 255):
    if t == None:
        t = otsu(image)[0]
    return (image >= t) * value

def toBarycentric(p, a, b, c):
    v0 = (b[0] - a[0], b[1] - a[1])
    v1 = (c[0] - a[0], c[1] - a[1])
    v2 = (p[0] - a[0], p[1] - a[1])
    den = v0[0] * v1[1] - v1[0] * v0[1]
    v = (v2[0] * v1[1] - v1[0] * v2[1]) / den
    w = (v0[0] * v2[1] - v2[0] * v0[1]) / den
    u = 1 - v - w
    return [u, v, w]

def isInRect(p, a, b):
    if p[0] < a[0] or p[1] < a[1]:
        return False
    if p[0] >= b[0] or p[1] >= b[1]:
        return False
    return True

def fixBadThresholds(thresholds):
    # Fix up "bad" thresholds ("bad" = low interclass standard deviation) by
    # replacing them with values interpolated between the "good" ones

    # Apply Otsu's algorithm on the interclass standard deviation to work out a
    # "good" threshold
    interclassSDs = numpy.empty(thresholds.shape)
    for y in xrange(thresholds.shape[0]):
        for x in xrange(thresholds.shape[1]):
            interclassSDs[y, x] = math.sqrt(thresholds[y, x][1])
    # Approximate by limiting to a maxmium of 10000 integer bins
    scale = 1
    if interclassSDs.max() >= 10000:
        scale = interclassSDs.max() / 10000
        interclassSDs /= scale
    goodInterclassVarThreshold = otsu(interclassSDs.astype(int))[0] or 0
    goodInterclassVarThreshold *= scale
    goodInterclassVarThreshold *= goodInterclassVarThreshold

    # Apply Delaunay triangulation over the entire thresholds with each "good"
    # threshold as a vertex
    triangulation = cv2.Subdiv2D(tuple(numpy.append([0, 0], thresholds.shape)))
    for y in xrange(thresholds.shape[0]):
        for x in xrange(thresholds.shape[1]):
            if thresholds[y, x][1] >= goodInterclassVarThreshold:
                triangulation.insert((y, x))

    # Use barycentric interpolation to extend these "good" thresholds over the
    # entire grid, overwriting the "bad" ones
    # XXX: Potentially O(N^2) because triangulation.locate() might not be O(log N)
    result = numpy.empty(thresholds.shape)
    for y in xrange(thresholds.shape[0]):
        for x in xrange(thresholds.shape[1]):
            kind, edge, vertex = triangulation.locate((y, x))
            if kind == cv2.CV_PTLOC_INSIDE or kind == cv2.CV_PTLOC_ON_EDGE:
                _, vertexA = triangulation.edgeOrg(edge)
                _, vertexB = triangulation.edgeDst(edge)
                # XXX: Is this guaranteed to be the third vertex of the triangle?
                _, vertexC = triangulation.edgeDst(triangulation.nextEdge(edge))
                vertices = [(int(p[0]), int(p[1])) for p in (vertexA, vertexB, vertexC)]
                
                weights = toBarycentric((y, x), vertices[0], vertices[1], vertices[2])
                for n, vertex in enumerate(vertices):
                    if not isInRect(vertex, (0, 0), thresholds.shape):
                        weights[n] = 0
                        vertices[n] = (0, 0)
                
                result[y, x] = numpy.dot(weights, map(lambda v: thresholds[v][0], vertices))
                result[y, x] /= numpy.sum(weights)
            elif kind == cv2.CV_PTLOC_VERTEX:
                result[y, x] = thresholds[y, x][0]
            else:
                assert(false)

    return result

def gridOtsuThreshold(image, sideLengths):
    gridShape = [int(math.ceil(i / s)) for i, s in zip(image.shape, sideLengths)]

    # Apply Otsu on the grid
    thresholds = numpy.empty(gridShape, dtype = tuple)
    for y in xrange(gridShape[0]):
        yStart = y * sideLengths[0]
        yEnd = yStart + sideLengths[0]
        for x in xrange(gridShape[1]):
            xStart = x * sideLengths[1]
            xEnd = xStart + sideLengths[1]
            thresholds[y, x] = otsu(image[yStart:yEnd, xStart:xEnd])

    # Fix up "bad" thresholds ("bad" = low interclass standard deviation)
    thresholds = fixBadThresholds(thresholds)

    # Apply the thresholding
    result = numpy.empty(image.shape, dtype = image.dtype)
    for y in xrange(gridShape[0]):
        yStart = y * sideLengths[0]
        yEnd = yStart + sideLengths[0]
        for x in xrange(gridShape[1]):
            xStart = x * sideLengths[1]
            xEnd = xStart + sideLengths[1]
            result[yStart:yEnd, xStart:xEnd] = threshold(image[yStart:yEnd, xStart:xEnd], thresholds[y, x])

    return result

def connectedComponents(image, background = 255, is8Connected = False, minimumPixels = 1, equalOp = operator.eq):
    # Assign all connected components (ignoring the background) to their own
    # sets with Union-Find
    components = UnionFind2D(image.shape)
    for y in xrange(image.shape[0]):
        for x in xrange(image.shape[1]):
            if image[y, x] == background:
                continue

            if is8Connected and y != 0 and x != 0 and equalOp(image[y - 1, x - 1], image[y, x]):
                components.union((y, x), (y - 1, x - 1))
            if y != 0 and equalOp(image[y - 1, x], image[y, x]):
                components.union((y, x), (y - 1, x))
            if is8Connected and y != 0 and x + 1 != image.shape[1] and equalOp(image[y - 1, x + 1], image[y, x]):
                components.union((y, x), (y - 1, x + 1))
            if x != 0 and equalOp(image[y, x - 1], image[y, x]):
                components.union((y, x), (y, x - 1))

    # Give each set of sufficient size a component number (strictly positive
    # integer, sequentially from 1), and return the image with each component
    # replaced with their component number. The background and sets of
    # insufficient size are replaced with 0s
    result = numpy.zeros(image.shape, dtype = int)
    validComponents = {}
    maxComponent = 0
    for y in xrange(image.shape[0]):
        for x in xrange(image.shape[1]):
            if image[y, x] == background:
                continue
            if components.getSize(y, x) >= minimumPixels:
                if components[y, x] not in validComponents:
                    maxComponent += 1
                    validComponents[components[y, x]] = maxComponent
                result[y, x] = validComponents[components[y, x]]

    return result

def colourComponents(image):
    max = image.max()
    result = numpy.zeros(numpy.append(image.shape, 3))
    for y in xrange(image.shape[0]):
        for x in xrange(image.shape[1]):
            if image[y, x] != 0:
                # Since hue is [0, 360) and 67 is coprime to 360, this loops
                # through all 360 integer hue values before repeating, while
                # avoiding the issue of hue difference being small for small
                # differences in component number
                result[y, x] = numpy.array(hsluv_to_rgb((image[y, x] * 67, 100, 50))) * 255
    return result
