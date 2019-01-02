""" Code adapted from Steven Hurwitt:
https://www.kaggle.com/stevenhurwitt/cats-vs-dogs-using-a-keras-convnet

who adapted it from Jeff Delaney:
https://www.kaggle.com/jeffd23/catdognet-keras-convnet-starter
"""

import numpy as np
from keras.models import Sequential
from keras.layers import Flatten, Conv2D, MaxPooling2D, Dense, Activation
from keras.optimizers import RMSprop
from keras.callbacks import Callback


def catdog(optimizer, objective):
    model = Sequential()
    # Fill in the gaps so that this code runs!

    # layer 1
    model.add(Conv2D(
            6,  # replace this with a valid arg
            (4, 4),  # replace this with a valid arg
            padding='same',
            input_shape=train.shape[1:],
            activation='relu'
        )
    )
    model.add(MaxPooling2D(
        pool_size=(2, 2),  # replace this with a valid arg
        data_format="channels_first"
    ))

    # layer 2
    model.add(Conv2D(
            16,  # replace this with a valid arg
            (4, 4),   # replace this with a valid arg
            padding='same',
            activation='relu'
        )
    )
    model.add(MaxPooling2D(
        pool_size=(2, 2),  # replace this with a valid arg
        data_format="channels_first"
    ))

    model.add(Flatten())

    model.add(Dense(
        120,   # replace this with a valid argument
        activation='relu')
    )

    model.add(Dense(1))  # Don't need to modify this one. 
    model.add(Activation('sigmoid'))
    print("Compiling model...")
    model.compile(
        loss=objective,
        optimizer=optimizer,
        metrics=['accuracy']
    )
    return model


#  Callback for loss logging per epoch
class LossHistory(Callback):
    def on_train_begin(self, logs={}):
        self.losses = []
        self.val_losses = []

    def on_epoch_end(self, batch, logs={}):
        self.losses.append(logs.get('loss'))
        self.val_losses.append(logs.get('val_loss'))


def run_catdog(train, labels, model):
    epochs = 10
    batch_size = 16
    history = LossHistory()
    print("running model...")
    model.fit(train, labels, batch_size=batch_size, epochs=epochs,
              validation_split=0.25, verbose=1, shuffle=True,
              callbacks=[history])


if __name__ == "__main__":

    train = np.load("train.out.npy")
    labels = np.load("labels.out.npy")

    optimizer = RMSprop(lr=1e-4)
    objective = 'binary_crossentropy'

    print("Creating model:")

    model = catdog(optimizer, objective)

    run_catdog(train, labels, model)
