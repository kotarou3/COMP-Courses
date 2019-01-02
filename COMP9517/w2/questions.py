import cv2
import numpy

def q1():
    image1 = cv2.imread("samples/1.png", cv2.CV_LOAD_IMAGE_GRAYSCALE)
    image2 = cv2.imread("samples/2.png", cv2.CV_LOAD_IMAGE_GRAYSCALE)
    
    dim = [min(a, b) for a, b in zip(image1.shape, image2.shape)]
    image1 = image1[:dim[0], :dim[1]]
    image2 = image2[:dim[0], :dim[1]]

    image1[:, dim[0] / 2:] = image2[:, dim[0] / 2:]
    cv2.imwrite("q1.png", image1)

def q2():
    image = cv2.imread("samples/1.png", cv2.CV_LOAD_IMAGE_GRAYSCALE)
    image2 = image & 0b10000000
    image8 = image & 0b11100000
    image32 = image & 0b11111000
    cv2.imwrite("q2-2.png", image2)
    cv2.imwrite("q2-8.png", image8)
    cv2.imwrite("q2-32.png", image32)

def q3():
    image = cv2.imread("samples/1.png", cv2.CV_LOAD_IMAGE_GRAYSCALE)
    image = 255 - image
    cv2.imwrite("q3.png", image)

def q4():
    image = cv2.imread("samples/1.png", cv2.CV_LOAD_IMAGE_GRAYSCALE)
    image = image - image.min()
    image = image * (255. / image.max())
    cv2.imwrite("q4.png", image)

def histogram(m):
    hist = [0 for i in range(255)]
    for row in m:
        for v in row:
            hist[v] += 1
    return hist

def q5():
    image = cv2.imread("samples/1.png", cv2.CV_LOAD_IMAGE_GRAYSCALE)
    print(repr(histogram(image)))

q1()
q2()
q3()
q4()
q5()
