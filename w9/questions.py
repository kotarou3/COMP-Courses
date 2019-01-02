# Adapted from :
# https://gis.stackexchange.com/questions/152853/image-segmentation-of-rgb-image-by-k-means-clustering-in-python

import numpy as np
import sklearn.cluster
import matplotlib.pyplot as plt

from PIL import Image

img_path = "data/tm1_1_1.png"
num_clusters = 3

img = Image.open(img_path)
img.thumbnail((100, 100))

img_mat = np.array(img)

red = img_mat[:, :, 0]
green = img_mat[:, :, 1]
blue  = img_mat[:, :, 2]
original_shape = red.shape # so we can reshape the labels later

samples = np.column_stack([red.flatten(), green.flatten(), blue.flatten()])

clf = sklearn.cluster.KMeans(n_clusters=num_clusters)
#clf = sklearn.cluster.MeanShift(bandwidth = 50, n_jobs = -1)
labels = clf.fit_predict(samples).reshape(original_shape)


plt.imshow(labels)
plt.show()
