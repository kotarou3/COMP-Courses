import cv2

def q1(input, output, isSurf = False):
    image = cv2.imread(input)
    greyImage = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    if isSurf:
        sift = cv2.xfeatures2d.SURF_create()
    else:
        sift = cv2.xfeatures2d.SIFT_create()
    keyPoints = sift.detect(greyImage, None)
    
    image = cv2.drawKeypoints(image, keyPoints, image, flags = cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)
    cv2.imwrite(output, image)

q1("../w3/samples/Hybrid_pair2_1.png", "q1.1.1.png")
q1("../w3/samples/Hybrid_pair2_2.png", "q1.1.2.png")
q1("../w3/samples/Hybrid_pair2_1.png", "q1.2.1.png", True)
q1("../w3/samples/Hybrid_pair2_2.png", "q1.2.2.png", True)
