import cv2
import numpy

def q4():
    low = cv2.imread("samples/Hybrid_pair2_1.png", cv2.CV_LOAD_IMAGE_COLOR)
    high = cv2.imread("samples/Hybrid_pair2_2.png", cv2.CV_LOAD_IMAGE_COLOR)
    
    dim = [min(a, b) for a, b in zip(low.shape, high.shape)]
    low = low[:dim[0], :dim[1]]
    high = high[:dim[0], :dim[1]]
    
    def mask(radius):
        cutoffRadius = 15
        interpolateRange = 3
        
        radius -= cutoffRadius
        if radius <= -interpolateRange:
            return 1
        elif -interpolateRange < radius < interpolateRange:
            return (interpolateRange - radius) / (2 * interpolateRange)
        else:
            return 0
    
    result = []
    for c in xrange(dim[2]):
        lowDft = cv2.dft(numpy.float32(low[:, :, c]), flags = cv2.DFT_COMPLEX_OUTPUT)
        highDft = cv2.dft(numpy.float32(high[:, :, c]), flags = cv2.DFT_COMPLEX_OUTPUT)
    
        for y in xrange(-dim[0] / 2, dim[0] / 2):
            for x in xrange(-dim[1] / 2, dim[0] / 2):
                radius = numpy.sqrt(x * x + y * y)
                ratio = mask(radius)
                lowDft[y, x] = ratio * lowDft[y, x] + (1 - ratio) * highDft[y, x]
                    
        idft = cv2.idft(lowDft, flags=cv2.DFT_SCALE | cv2.DFT_REAL_OUTPUT)
        result.append(idft)
        
    result = numpy.array(result)
    result = numpy.swapaxes(result, 0, 2)
    result = numpy.swapaxes(result, 0, 1)
    cv2.imwrite("q4.png", result)

q4()
