from __future__ import print_function

import numpy
import sklearn.datasets
import sklearn.cross_validation
import sklearn.neighbors

def q3():
    dataset = sklearn.datasets.load_digits()

    data_X, data_y = zip(*numpy.random.permutation(zip(dataset.data, dataset.target)))
    trainingData = (data_X[:len(data_X) * 8 / 10], data_y[:len(data_y) * 8 / 10])
    testingData = (data_X[len(data_X) * 8 / 10:], data_y[len(data_y) * 8 / 10:])
    for k in (1, 3, 5):
        knn = sklearn.neighbors.KNeighborsClassifier(k)
        knn.fit(*trainingData)
        
        accuracy = knn.score(*testingData)
        print("{}: {:.3}".format(k, accuracy))

    for k in (1, 3, 5):
        knn = sklearn.neighbors.KNeighborsClassifier(k)
        accuracy = sklearn.cross_validation.cross_val_score(knn, dataset.data, dataset.target, scoring = "accuracy", cv = 5)
        print("{}: {:.3} +/- {:.3}".format(k, numpy.mean(accuracy), numpy.std(accuracy) * 1.96))

q3()    
