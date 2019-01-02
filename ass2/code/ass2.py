# coding=utf-8

import collections
import heapq
import itertools

import cv2
import numpy

from union_find import UnionFind

# Set to False for a huge speedup. Switches between python and opencv
# implementations of certain functions.
disableCv2KnnMatch = False # Especially this one! ~2x(#cores)x speedup
disableCv2FindHomography = False
disableCv2WarpPerspective = False

def getTranslationMatrix(offset):
    return numpy.array([[1, 0, offset[0]], [0, 1, offset[1]], [0, 0, 1]])

def detectFeatures(image):
    sift = cv2.xfeatures2d.SIFT_create()
    keypoints, descriptors = sift.detectAndCompute(image, None)
    return keypoints, descriptors

def drawKeypoints(image, keypoints):
    return cv2.drawKeypoints(image, keypoints, image.copy(), flags = cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)

def knnMatch(queryDescriptors, trainDescriptors, k):
    # Simple brute force matcher
    matches = []
    for q, query in enumerate(queryDescriptors):
        displacements = trainDescriptors - query
        distancesSquared = numpy.sum(displacements * displacements, 1)
        knn = heapq.nsmallest(
            k, enumerate(distancesSquared),
            key = lambda e: e[1]
        )
        knn = [cv2.DMatch(
            _distance = numpy.sqrt(distanceSquared),
            _imgIdx = 0,
            _queryIdx = q,
            _trainIdx = t
        ) for t, distanceSquared in knn]
        matches.append(knn)

    return matches

def matchFeatures(descriptorsA, descriptorsB):
    if disableCv2KnnMatch:
        matchesA = knnMatch(descriptorsA, descriptorsB, 2)
        matchesB = knnMatch(descriptorsB, descriptorsA, 2)
    else:
        matcher = cv2.BFMatcher()
        matchesA = matcher.knnMatch(descriptorsA, descriptorsB, 2)
        matchesB = matcher.knnMatch(descriptorsB, descriptorsA, 2)

    # Use Lowe's nearest neighbour to next nearest ratio test (as presented in
    # the original SIFT paper section 7.1) to filter out likely-"bad" matches
    goodMatchesA = []
    goodMatchesB = []
    for a, b in matchesA:
        if a.distance < 0.8 * b.distance:
            goodMatchesA.append(a)
    for a, b in matchesB:
        if a.distance < 0.8 * b.distance:
            goodMatchesB.append(a)

    # Cross check the matches
    goodMatchesB = set((m.trainIdx, m.queryIdx) for m in goodMatchesB)
    goodMatches = []
    for match in goodMatchesA:
        if (match.queryIdx, match.trainIdx) in goodMatchesB:
            goodMatches.append(match)

    return goodMatches

def drawMatches(imageA, keypointsA, imageB, keypointsB, matches):
    return cv2.drawMatches(imageA, keypointsA, imageB, keypointsB, matches, None)

def isOkHomography(image, homography):
    # Skewness shouldn't be too high
    if abs(homography[2][0]) > 0.002 or abs(homography[2][1]) > 0.002:
        return False

    # There should be no reflections
    border = warpBorder(image, homography)
    hull = tuple(cv2.convexHull(border, clockwise = False, returnPoints = False).reshape(-1))
    if hull not in {(0, 1, 2, 3), (1, 2, 3, 0), (2, 3, 0, 1), (3, 0, 1, 2)}:
        return False

    # The reprojected image should not be too different in size
    shape = border.max(0) - border.min(0)
    areaRatio = shape[0] * shape[1] / (image.shape[0] * image.shape[1])
    if not 0.01 <= areaRatio <= 100:
        return False

    return True

def _findHomography(srcPoints, dstPoints, reprojThreshold):
    assert(srcPoints.shape == dstPoints.shape)
    assert(len(srcPoints.shape) == 2)
    assert(srcPoints.shape[1] == 2)
    srcPoints = srcPoints.astype(numpy.float32)
    dstPoints = dstPoints.astype(numpy.float32)

    def RANSACStep(points):
        # Returns (homography, inlier mask)
        H = cv2.getPerspectiveTransform(srcPoints[points,], dstPoints[points,])
        transformedPoints = cv2.perspectiveTransform(srcPoints.reshape(-1, 1, 2), H).reshape(-1, 2)
        displacements = dstPoints - transformedPoints
        distances = numpy.sum(displacements * displacements, 1)
        return H, (distances <= reprojThreshold).reshape(-1, 1)

    iterations = 2000
    samples = [numpy.random.choice(srcPoints.shape[0], 4, replace = False) for i in xrange(iterations)]
    s, _ = max(enumerate(samples), key = lambda e: numpy.count_nonzero(RANSACStep(e[1])[1]))
    return RANSACStep(samples[s])

def findHomography(image, srcPoints, dstPoints, matches):
    # If we have #matching points < 50, we probably won't end up with a good
    # homography
    if len(matches) < 50:
        return None, []

    srcPoints = numpy.array([srcPoints[m.queryIdx].pt for m in matches])
    dstPoints = numpy.array([dstPoints[m.trainIdx].pt for m in matches])

    if disableCv2FindHomography:
        homography, mask = _findHomography(srcPoints, dstPoints, 5.0)
    else:
        homography, mask = cv2.findHomography(srcPoints, dstPoints, cv2.RANSAC, 5.0)

    inliers = []
    for m, match in enumerate(matches):
        if mask[m][0]:
            inliers.append(match)

    # If #inliers < 50% of matching points, probably wasn't a good homography
    if len(inliers) < 0.5 * min(len(srcPoints), len(dstPoints)):
        return None, []

    if not isOkHomography(image, homography):
        return None, []

    return homography, inliers

def warpBorder(image, transformation):
    height = image.shape[0]
    width = image.shape[1]
    border = numpy.float32([(0, 0), (width, 0), (width, height), (0, height)]).reshape(-1, 1, 2)
    return cv2.perspectiveTransform(border, transformation).reshape(-1, 2)

def cartesian_product_transpose_pp(*arrays):
    # From https://stackoverflow.com/a/49445693
    la = len(arrays)
    dtype = numpy.result_type(*arrays)
    arr = numpy.empty([la] + map(len, arrays), dtype=dtype)
    idx = [slice(None)] + list(itertools.repeat(None, la))
    for i, a in enumerate(arrays):
        arr[i, ...] = a[idx[:la-i]]
    return arr.reshape(la, -1).T

def _warpPerspective(image, transformation, outputShape):
    mapping = cartesian_product_transpose_pp(
        numpy.arange(outputShape[0], dtype = numpy.float32),
        numpy.arange(outputShape[1], dtype = numpy.float32)
    )
    mapping = mapping.reshape(outputShape[0], outputShape[1], 2)
    mapping = cv2.perspectiveTransform(mapping, numpy.matrix(transformation).getI())
    return numpy.swapaxes(cv2.remap(
        image,
        mapping, None,
        interpolation = cv2.INTER_LINEAR
    ), 0, 1)

def warpPerspective(image, transformation, outputShape = None):
    if type(outputShape) == type(None):
        # Find a new image size such that the entire transformed image fits
        border = warpBorder(image, transformation)
        offset = numpy.min([(0, 0), border.min(0)], 0)
        outputShape = numpy.ceil((border - offset).max(0)).astype(int)

        # Since we can't have negative coordinates, shift everything to be positive
        transformation = numpy.matmul([[1, 0, -offset[0]], [0, 1, -offset[1]], [0, 0, 1]], transformation)
    else:
        offset = [0, 0]

    outputShape = tuple(outputShape)
    if disableCv2WarpPerspective:
        newImage = _warpPerspective(image, transformation, outputShape)
        mask = _warpPerspective(numpy.full(image.shape, 255, dtype = numpy.uint8), transformation, outputShape)
    else:
        newImage = cv2.warpPerspective(image, transformation, outputShape)
        mask = cv2.warpPerspective(numpy.full(image.shape, 255, dtype = numpy.uint8), transformation, outputShape)

    return newImage, mask, offset

def findStitchingTrees(matchedPairsMatrix):
    # Find maximum spanning forest with Kruskal's algorithm using #matching
    # points as edge weight

    forest = UnionFind()
    msf = []

    edges = list(itertools.product(xrange(len(matchedPairsMatrix)), xrange(len(matchedPairsMatrix))))
    edges.sort(key = lambda e: len(matchedPairsMatrix[e[0]][e[1]]), reverse = True)
    for edge in edges:
        # Ignore edges with no matching points
        if len(matchedPairsMatrix[edge[0]][edge[1]]) == 0:
            break
        if forest[edge[0]] != forest[edge[1]]:
            forest.union(edge[0], edge[1])
            msf.append(edge)

    # Split the forest into trees
    trees = {}
    for edge in msf:
        assert(forest[edge[0]] == forest[edge[1]])
        trees.setdefault(forest[edge[0]], []).append(edge)

    # Returns [[edges], [edges], ...] where each [edges] is a tree
    return trees.values()

def findStitchingHomographies(stitchingTreeEdges, pairwiseHomographies):
    # Root the tree using one of the first edge's nodes, then build up the
    # homographies by iterating over all edges such that one node is already in
    # the rooted tree
    result = [[None for dst in xrange(len(pairwiseHomographies))] for src in xrange(len(pairwiseHomographies))]
    edgesToVisit = collections.deque(stitchingTreeEdges)
    root = stitchingTreeEdges[0][0]
    visitedNodes = {root}
    nodeOrder = [root]
    result[root][root] = numpy.identity(3)
    while len(edgesToVisit) > 0:
        edge = edgesToVisit.popleft()
        if edge[0] in visitedNodes:
            anchor = edge[0]
            neighbour = edge[1]
        elif edge[1] in visitedNodes:
            anchor = edge[1]
            neighbour = edge[0]
        else:
            # By doing "skip-and-retry-later", this makes the iteration O(N^2),
            # but since our overall algorithm is already O(N^2), this doesn't
            # matter in the end
            edgesToVisit.append(edge)
            continue

        # Identity for project-to-self
        result[neighbour][neighbour] = numpy.identity(3)

        # Just copy the known homography for the direct pairing
        result[anchor][neighbour] = pairwiseHomographies[anchor][neighbour]
        result[neighbour][anchor] = pairwiseHomographies[neighbour][anchor]
        assert(type(result[anchor][neighbour]) != type(None))
        assert(type(result[neighbour][anchor]) != type(None))

        for node in visitedNodes:
            if node == anchor:
                continue

            # Project the known homography for indirect pairings
            assert(type(result[anchor][node]) != type(None))
            assert(type(result[node][anchor]) != type(None))
            result[node][neighbour] = numpy.matmul(result[anchor][neighbour], result[node][anchor])
            result[neighbour][node] = numpy.matmul(result[anchor][node], result[neighbour][anchor])

        visitedNodes.add(neighbour)
        nodeOrder.append(neighbour)

    return result, nodeOrder

def findBestPanorama(images, pairwiseHomographies, stitchingTreeEdges):
    # "Best" as in maximising #images, then minimising area, which should tend
    # to prefer less distorted results

    homographies, imageOrder = findStitchingHomographies(stitchingTreeEdges, pairwiseHomographies)

    # Project the borders of every image onto every image to work out the
    # required image area of the paronama using each image as the reference
    # projection. Also keep a count of images that can end up in the panorama,
    # since we might reject some images for having a bad resulting homography.
    panoramaImages = [0 for i in images]
    skippedImages = [set() for i in images]
    panoramaArea = [0 for i in images]
    for src, srcImage in enumerate(images):
        for dst, dstImage in enumerate(images):
            if type(homographies[src][dst]) == type(None):
                continue
            if not isOkHomography(srcImage, homographies[src][dst]):
                homographies[src][dst] = None
                skippedImages[dst].add(src)
                continue

            border = warpBorder(srcImage, homographies[src][dst])
            # XXX: We're double counting intersections here, which sounds bad,
            # but in practice seems to be fine...
            panoramaArea[dst] += cv2.contourArea(border)
            panoramaImages[dst] += 1

    i, _ = min(
        enumerate(zip(panoramaImages, panoramaArea)),
        key = lambda e: (-e[1][0], e[1][1])
    )
    homography = [h[i] for h in homographies]
    imageOrder = filter(lambda i: type(homography[i]) != type(None), imageOrder)

    if len(skippedImages[i]) > 0:
        print(
            "Warning: Reprojected homography for images {} were bad.\n"
            "         Maybe the input images have >170 degree FoV in total?\n"
            "         Panorama will be incomplete.".format(list(skippedImages[i]))
        )

    # Calculate the resulting image shape of the panorama
    infCoord = numpy.array([numpy.inf, numpy.inf])
    panoramaBorder = [infCoord, -infCoord]
    for i in imageOrder:
        border = warpBorder(images[i], homography[i])
        panoramaBorder[0] = numpy.min([panoramaBorder[0], border.min(0)], 0)
        panoramaBorder[1] = numpy.max([panoramaBorder[1], border.max(0)], 0)

    offset = panoramaBorder[0]
    shape = numpy.ceil(panoramaBorder[1] - offset).astype(int)

    return shape, offset, homography, imageOrder

def projectBestPanorama(images, pairwiseHomographies, stitchingTreeEdges):
    shape, offset, homographies, imageOrder = findBestPanorama(images, pairwiseHomographies, stitchingTreeEdges)

    for i in imageOrder:
        # Apply the offset to the homographies so no pixel ends up with negative
        # coordinates
        homography = numpy.matmul([[1, 0, -offset[0]], [0, 1, -offset[1]], [0, 0, 1]], homographies[i])

        result, mask, _ = warpPerspective(images[i], homography, shape)
        yield result, mask

def binaryBlendPanorama(imagesAndMasks):
    # Boring binary blending
    result = None
    for image, mask in imagesAndMasks:
        if type(result) == type(None):
            result = image
        else:
            numpy.copyto(result, image, where = mask > 0)
    return result

def applyMask(image, mask):
    result = numpy.zeros(image.shape, dtype = image.dtype)
    numpy.copyto(result, image, where = mask > 0)
    return result

def findGraphCut(imageA, maskA, imageB, maskB):
    # Ideally, we would find the cut that minimises the pixel difference along
    # the cut, but I don't have time to implement that, so we simply go with the
    # cut that maximises imageA's area
    assert(maskA.dtype == maskB.dtype)
    newMaskA = maskA
    newMaskB = applyMask(maskB - maskA, maskB)
    return newMaskA, newMaskB

def getLaplacianPyramid(image, mask):
    gaussian = image
    resizedMask = mask
    laplacians = []

    octaves = int(numpy.floor(numpy.log2(numpy.min(image.shape[:2]))))
    for o in xrange(octaves):
        shape = gaussian.shape
        nextGaussian = cv2.pyrDown(gaussian)
        laplacians.append([gaussian - cv2.pyrUp(nextGaussian)[:shape[0], :shape[1]], mask, resizedMask])
        gaussian = nextGaussian
        mask = cv2.pyrDown(mask)
        resizedMask = resizedMask[::2, ::2]
    laplacians.append([gaussian, mask, resizedMask])

    return list(reversed(laplacians))

def pyramidBlend(imageA, maskA, imageB, maskB):
    assert(imageA.shape == imageB.shape)
    imageA = imageA.astype(float) / 255
    imageB = imageB.astype(float) / 255
    maskA = maskA.astype(float) / 255
    maskB = maskB.astype(float) / 255
    laplaciansA = getLaplacianPyramid(imageA, maskA)
    laplaciansB = getLaplacianPyramid(imageB, maskB)

    result = None
    for (laplacianA, maskA, resizedMaskA), (laplacianB, maskB, resizedMaskB) in zip(laplaciansA, laplaciansB):
        laplacian = maskA * laplacianA + (1 - maskA) * laplacianB
        shape = laplacian.shape
        #mask = (resizedMaskA + resizedMaskB)[:shape[0], :shape[1]]
        if type(result) == type(None):
            result = laplacian
        else:
            #result = applyMask(cv2.pyrUp(result)[:shape[0], :shape[1]] + laplacian, mask)
            result = cv2.pyrUp(result)[:shape[0], :shape[1]] + laplacian

    return (result * 255).astype(numpy.uint8)

def blendPanorama(imagesAndMasks):
    result = None
    resultMask = None
    for image, mask in imagesAndMasks:
        if type(result) == type(None):
            result = image
            resultMask = mask
        else:
            maskA, maskB = findGraphCut(result, resultMask, image, mask)
            result = pyramidBlend(result, maskA, image, maskB)
            resultMask = maskA + maskB
    return result

def stitchBestPanorama(images, pairwiseHomographies, stitchingTreeEdges):
    return blendPanorama(projectBestPanorama(images, pairwiseHomographies, stitchingTreeEdges))
