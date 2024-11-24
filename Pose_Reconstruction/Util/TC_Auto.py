import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Conv1D, Flatten, Reshape, Dense
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
from scipy.io import loadmat, savemat
import os
import h5py
class Autoencoder:
    def __init__(self, input_shape, bottleneck_size=22, activation='selu', conv_units=256, kernel_size=3, stride_size=1, batch_size=512, dropout_rate=0.1):
        self.input_shape = input_shape
        self.bottleneck_size = bottleneck_size
        self.activation = activation
        self.conv_units = conv_units
        self.kernel_size = kernel_size
        self.stride_size = stride_size
        self.batch_size = batch_size
        self.dropout_rate = dropout_rate
        self.model = self.build_model()
    def build_model(self):
        # Encoder
        inputs = Input(shape=self.input_shape)
        x = Dense(128, activation=self.activation)(inputs)
        x_short = Conv1D(self.conv_units, kernel_size=(self.kernel_size,), strides=(self.stride_size,), activation=self.activation, padding='same')(x)
        x = Dense(self.bottleneck_size, activation=self.activation)(x)
        shape_before_flatten = tf.keras.backend.int_shape(x)[1:]
        x = Flatten()(x)
        encoded = Dense(self.bottleneck_size, activation=self.activation)(x)
        # Decoder
        x = Dense(np.prod(shape_before_flatten), activation=self.activation)(encoded)
        x = Dense(self.input_shape[0] * self.input_shape[1], activation='linear')(x)
        decoded = Reshape(self.input_shape)(x)
        # Autoencoder
        autoencoder = Model(inputs, decoded)
        autoencoder.compile(optimizer='adam', loss='mse')
        autoencoder.summary()
        return autoencoder
    def train(self, x_train_masked, x_train, x_val_masked, x_val, epochs=100,ER_Patience=25, LR_patience=10):
        early_stopping = EarlyStopping(monitor='val_loss', patience=ER_Patience, restore_best_weights=True)
        reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=LR_patience, min_lr=1e-6)
        self.model.fit(x_train_masked, x_train, epochs=epochs, batch_size=self.batch_size, validation_data=(x_val_masked, x_val), callbacks=[early_stopping, reduce_lr])
    def predict(self, data):
        return self.model.predict(data)
    def evaluate(self, x_test, y_test):
        return self.model.evaluate(x_test, y_test)
    def save_model(self, save_path):
        self.model.save(save_path)
# I want a function which simply reads in an h5 file, given a path, and a dataset name
def h5read(file_path, dataset_name):
    with h5py.File(file_path, 'r') as file:
        data = file[dataset_name][:]
    return data
def load_v73_mat_file(file_path, var_name='X_data_all'):
    with h5py.File(file_path, 'r') as file:
        X_data_all = file[var_name][:]
        X_data_all = X_data_all.T
    return X_data_all
def load_data(file_path):
    try:
        data = loadmat(file_path)
        train_dataX = data['train_dataX']
        train_dataY = data['train_dataY']
        test_dataX = data['test_dataX']
        test_dataY = data['test_dataY']
    except NotImplementedError as e:
        print(f'Error loading MAT file with loadmat: {e}')
        print('Attempting to load using h5py...')
        try:
            with h5py.File(file_path, 'r') as f:
                train_dataX = np.array(f['train_dataX'][:])
                train_dataY = np.array(f['train_dataY'][:])
                test_dataX = np.array(f['test_dataX'][:])
                test_dataY = np.array(f['test_dataY'][:])
        except Exception as e:
            print(f'Error loading MAT file with h5py: {e}')
            raise
    except Exception as e:
        print(f'Unexpected error: {e}')
        raise
def load_feature_means(file_path):
    feature_means = loadmat(file_path)['features_means']
    feature_means = np.expand_dims(feature_means, axis=0)
    return feature_means
def create_masked_data(x_train, feature_means, mask_probability=0.1):
    mask = np.random.rand(*x_train.shape) < mask_probability
    # Reshape feature_means to be broadcastable
    feature_means_reshaped = feature_means.reshape(1, 1, -1)
    x_train_masked = np.where(mask, feature_means_reshaped, x_train)
    return x_train_masked
def save_reconstructions(file_path, reconstructions):
    savemat(file_path, reconstructions)
def get_predictions(data,weights_path):
    autoenc = Autoencoder(data.shape[1:])
    autoenc.model.load_weights(weights_path)
    return autoenc.predict(data)
def trainmodel(traindatapath, feature_means_path, model_save_path, v73, model_params):
    try:
        # Load data
        if v73:
            x_train = load_v73_mat_file(traindatapath, var_name='train_dataX')
            y_train = load_v73_mat_file(traindatapath, var_name='train_dataY')
            x_test = load_v73_mat_file(traindatapath, var_name='test_dataX')
            y_test = load_v73_mat_file(traindatapath, var_name='test_dataY')
        else:
            data = loadmat(traindatapath)
            x_train, y_train = data['train_dataX'], data['train_dataY']
            x_test, y_test = data['test_dataX'], data['test_dataY']
        print(f"Data loaded. Shapes: x_train: {x_train.shape}, y_train: {y_train.shape}")
        # Load feature means and create masked data
        feature_means = load_feature_means(feature_means_path)
        x_train_masked = create_masked_data(x_train, feature_means)
        # Prepare validation data
        validation_split = float(model_params['val_split'])  # Ensure this is a float
        val_size = int(len(x_train) * validation_split)
        x_val, y_val = x_train[:val_size], y_train[:val_size]
        x_val_masked = x_train_masked[:val_size]
        x_train, y_train = x_train[val_size:], y_train[val_size:]
        x_train_masked = x_train_masked[val_size:]
        print(f"Data prepared. Shapes: x_train_masked: {x_train_masked.shape}, x_val_masked: {x_val_masked.shape}")
        # Ensure input_shape is a tuple of integers
        input_shape = tuple(map(int, model_params['input_shape']))
        print(f"Creating Autoencoder with input_shape: {input_shape}")
        # Create and train the autoencoder
        autoenc = Autoencoder(
            input_shape=input_shape,
            bottleneck_size=int(model_params['bottleneck_size']),
            activation=model_params['activation'],
            conv_units=int(model_params['conv_units']),
            kernel_size=int(model_params['kernel_size']),
            stride_size=int(model_params['stride_size']),
            batch_size=int(model_params['batch_size']),
            dropout_rate=float(model_params['dropout_rate'])
        )
        print("Autoencoder created. Starting training...")
        history = autoenc.train(
            x_train_masked, y_train,
            x_val_masked, y_val,
            epochs=int(model_params['epochs']),
            ER_Patience=int(model_params['ER_Patience']),
            LR_patience=int(model_params['LR_patience'])
        )
        print("Training completed. Evaluating model...")
        # Evaluate and save the model
        test_loss = autoenc.evaluate(x_test, y_test)
        print(f'Test loss: {test_loss}')
        autoenc.save_model(model_save_path)
        return test_loss
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        import traceback
        traceback.print_exc()
        return None
if __name__ == "__main__":
    # Load your data
    input_shape = [15, 44]
    data = np.random.rand(1000,15,44)
    # get_predictions(data)
    autoenc = Autoencoder(input_shape)
    model = autoenc.build_model()
    model.summary()
    file_path = '/Users/maxweinberg/Desktop/Bergan_Lab_Repo/All_Fiber_Stuff/Sleapproc/Autoenc/PreprocForEncoder/traintestSeq.mat'
    x_train = load_v73_mat_file(file_path, var_name='train_dataX')
    y_train = load_v73_mat_file(file_path, var_name='train_dataY')
    x_test = load_v73_mat_file(file_path, var_name='test_dataX')
    y_test = load_v73_mat_file(file_path, var_name='test_dataY')
    print(x_train.shape)
    feature_means = load_feature_means('/Users/maxweinberg/Desktop/Bergan_Lab_Repo/All_Fiber_Stuff/Sleapproc/Autoenc/PreprocForEncoder/features_means.mat')
    # Create masked data
    x_train_masked = create_masked_data(x_train, feature_means)
    # Define the shape of your input data
    input_shape = x_train.shape[1:]
    print(input_shape)
    # Manually split the data into training and validation sets to avoid temporal leakage
    validation_split = 0.2
    val_size = int(len(x_train) * validation_split)
    x_val = x_train[:val_size]
    y_val = y_train[:val_size]
    x_val_masked = x_train_masked[:val_size]
    x_train = x_train[val_size:]
    y_train = y_train[val_size:]
    x_train_masked = x_train_masked[val_size:]
    # # # Define the parameter space for Bayesian optimization
    # # param_space = [
    # #     Integer(22, 660, name='bottleneck_size')
    # # ]
    # # # Perform Bayesian search
    # # n_calls = 20  # Number of parameter settings that are sampled
    # # res = bayesian_search(input_shape, param_space, x_train_masked, y_train, x_val_masked, y_val, x_test, y_test, n_calls=n_calls)
    # # best_params = res.x
    # # best_test_loss = res.fun
    # # print(f"Best parameters: {best_params}")
    # # print(f"Best test loss: {best_test_loss}")
    # # savemat('gridresults.mat', {'best_params': best_params, 'best_test_loss': best_test_loss})
    # Initialize and train the best autoencoder
    autoenc = Autoencoder(
        input_shape
    )
    autoenc.train(x_train_masked, y_train, x_val_masked, y_val)
    # # Get the reconstructions
    # reconstructions = autoenc.predict(x_test)
    # sample_data = loadmat('/Users/maxweinberg/Desktop/Bergan_Lab_Repo/All_Fiber_Stuff/Sleapproc/Autoenc/PreprocForEncoder/sequences_fp.mat')['sequences_fp']
    # reconstructions2 = autoenc.predict(sample_data)
    # # Save the reconstructions to a .mat file
    # save_reconstructions('/Users/maxweinberg/Desktop/Bergan_Lab_Repo/All_Fiber_Stuff/Sleapproc/Autoenc/PreprocForEncoder/reconstructions.mat', {'reconstructions': reconstructions})
    # save_reconstructions('/Users/maxweinberg/Desktop/Bergan_Lab_Repo/All_Fiber_Stuff/Sleapproc/Autoenc/PreprocForEncoder/reconstructions2.mat', {'reconstructions2': reconstructions2})
    # # Evaluate the model on the test data
    test_loss = autoenc.evaluate(x_test, y_test)
    print(f'Test loss: {test_loss}')
    # # Save the entire model to a file
    model_save_path = '/Users/maxweinberg/Desktop/Bergan_Lab_Repo/All_Fiber_Stuff/Sleapproc/Autoenc/Encoder/models/conv_autoencoder_model.h5'
    autoenc.save_model(model_save_path)








