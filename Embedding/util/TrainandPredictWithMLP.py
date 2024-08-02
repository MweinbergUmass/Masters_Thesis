from sklearn.neural_network import MLPRegressor
from scipy.io import loadmat, savemat
from joblib import dump, load
import matplotlib.pyplot as plt
import matplotlib as mpl
from scipy.stats import pearsonr
import h5py
from sklearn.manifold import TSNE
import numpy as np
import os
import json
from datetime import datetime

# the order of opperations:
#   run_unif_train_model(): (This will train the model on the uniformlly sampled data)
#   run_run_init_unif_RunModel (This will run the model on uniformly sampled model on all the data and output 'Data/init_unif_all_y_embedded.mat' )

def runTsne(distance_matrix,perplexity_scale,n_components=2,verbose=2,n_iter=1000):
    num_2_sample = distance_matrix.shape[1]
    tsne = TSNE(metric="precomputed", n_components=n_components, random_state=42,init='random', perplexity=num_2_sample/perplexity_scale,verbose=verbose, n_iter=n_iter)
    Y_embedded = tsne.fit_transform(distance_matrix)
    return Y_embedded

def Embed(data, modelpath):
    mlp = load(modelpath)
    Y_embedded = mlp.predict(data)
    return Y_embedded

def load_unif_data():
    X_tr = loadmat('Data/X_tr_unif')['X_tr_unif']
    y_tr = loadmat('Data/y_tr_unif')['y_tr_unif']
    X_te = loadmat('Data/X_te_unif')['X_te_unif']
    y_te = loadmat('Data/y_te_unif')['y_te_unif']
    return X_tr, y_tr, X_te, y_te

def load_unif_data_good():
    X_tr = loadmat('Data/GoodData/X_tr_unif')['X_tr_unif']
    y_tr = loadmat('Data/GoodData/y_tr_unif')['y_tr_unif']
    X_te = loadmat('Data/GoodData/X_te_unif')['X_te_unif']
    y_te = loadmat('Data/GoodData/y_te_unif')['y_te_unif']
    return X_tr, y_tr, X_te, y_te

def load_importance_sampled_data():
    X_tr = loadmat('Data/X_tr_IS')['X_tr_IS']
    y_tr = loadmat('Data/y_tr_IS')['y_tr_IS']
    X_te = loadmat('Data/X_te_IS')['X_te_IS']
    y_te = loadmat('Data/y_te_IS')['y_te_IS']
    return X_tr, y_tr, X_te, y_te

def run_unif_train_model():
    X_tr, y_tr, X_te, y_te = load_unif_data_good()
    print(X_tr.shape)
    trainModel(X_tr, y_tr, X_te, y_te, 'Models/unif_MLP.joblib')

def run_importance_sampled_train_model():
    X_tr, y_tr, X_te, y_te = load_importance_sampled_data()
    trainModel(X_tr, y_tr, X_te, y_te, 'Models/IS_MLP.joblib')

def run_run_importance_sampled_RunModel(): # run the predictions for importance sampled
    X_data = load_v73_mat_file('X_data_all.mat')
    #X_data = loadmat('Data/X_data_all')['X_data_all']
    savename = 'Y_final_all_embeded.mat'
    modelPath = 'Models/IS_unif_MLP.joblib'
    runModel(X_data=X_data, modelPath=modelPath, savename=savename)

def run_run_init_unif_RunModel(): # run the predictions for unif 
    X_data = load_v73_mat_file('DataNew/X_data_all.mat')
    print(X_data.shape)
   #X_data = loadmat('Data/X_data_all')['X_data_all']
    savename = 'Data/init_unif_all_y_embedded.mat'
    modelPath = 'Models/unif_MLP.joblib'
    runModel(X_data=X_data, modelPath=modelPath, savename=savename)


def trainModel(X_tr, y_tr, X_te, y_te, savename, verbose=True, early_stopping=True, validation_fraction=0.1, batch_size=512, epochs=200, output_dir='model_output'):
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Generate a unique identifier for this run
    run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Create a subdirectory for this run
    run_dir = os.path.join(output_dir, run_id)
    os.makedirs(run_dir, exist_ok=True)

    mlp = MLPRegressor(hidden_layer_sizes=(512,256,128,64), verbose=verbose, early_stopping=early_stopping, validation_fraction=validation_fraction, batch_size=batch_size, max_iter=epochs)
    mlp.fit(X_tr, y_tr)
    pred_te = mlp.predict(X_te)
    
    # Convert y_te and pred_te to numpy arrays if they're not already
    y_te_np = np.array(y_te)
    pred_te_np = np.array(pred_te)
    
    var_explained = pearsonr(y_te_np.flatten(), pred_te_np.flatten())[0]**2
    print(f'R^2 between predicted and actual = {var_explained:.2f}')

    # Save the model
    model_path = os.path.join(run_dir, 'model.joblib')
    dump(mlp, model_path)
    print(f'Model saved to {model_path}')
    
    # Prepare data for MATLAB
    loss_curve = np.array(mlp.loss_curve_)
    epochs_array = np.arange(1, len(loss_curve) + 1)
    
    # Save data for MATLAB
    matlab_data = {
        'loss_curve': loss_curve,
        'epochs': epochs_array,
        'y_true': y_te_np.flatten(),
        'y_pred': pred_te_np.flatten(),
        'r_squared': var_explained
    }
    matlab_path = os.path.join(run_dir, 'plot_data.mat')
    savemat(matlab_path, matlab_data)
    print(f'Data for plotting saved to {matlab_path}')

    # Save metadata
    metadata = {
        'run_id': run_id,
        'model_path': model_path,
        'matlab_data_path': matlab_path,
        'r_squared': var_explained,
        'parameters': {
            'verbose': verbose,
            'early_stopping': early_stopping,
            'validation_fraction': validation_fraction,
            'batch_size': batch_size,
            'epochs': epochs,
        }
    }
    metadata_path = os.path.join(run_dir, 'metadata.json')
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f'Metadata saved to {metadata_path}')

    # Return a single dictionary containing both run_dir and metadata
    return {'run_dir': run_dir, 'metadata': metadata}

# Usage:
# run_dir, metadata = trainModel(X_tr, y_tr, X_te, y_te, "model_save_name.joblib", output_dir='my_project_output')

def runModel(X_data, modelPath, savename):
    mlp = load(modelPath)
    Y_embedded = mlp.predict(X_data)
    Y_embedded_dict = {'Y_embedded': Y_embedded}
    savemat(savename, Y_embedded_dict)
    return Y_embedded

import pickle

import json
import numpy as np

def runModel_V2(X_data, modelPath='Models/converted_model.json'):
    def custom_load(file_path):
        try:
            with open(file_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"JSON loading failed: {str(e)}")
            raise ValueError("Unable to load the model data.")

    def get_activation_function(name):
        if name == 'relu':
            return lambda x: np.maximum(0, x)
        elif name == 'tanh':
            return np.tanh
        elif name == 'logistic':
            return lambda x: 1 / (1 + np.exp(-x))
        elif name == 'identity':
            return lambda x: x
        else:
            raise ValueError(f"Unsupported activation function: {name}")

    def predict(X, model_data):
        activation = get_activation_function(model_data['params']['activation'])
        
        # Apply the activation function to all layers except the last
        for layer in model_data['coefs_and_intercepts'][:-1]:
            X = activation(np.dot(X, layer['weights']) + layer['biases'])
        
        # For the last layer, just apply the linear transformation
        last_layer = model_data['coefs_and_intercepts'][-1]
        return np.dot(X, last_layer['weights']) + last_layer['biases']

    try:
        model_data = custom_load(modelPath)
        
        # Check input size
        if X_data.shape[1] != model_data['input_size']:
            raise ValueError(f"Input data should have {model_data['input_size']} features, but has {X_data.shape[1]}")

        Y_embedded = predict(X_data, model_data)
        return Y_embedded
    except Exception as e:
        print(f"Error in runModel_V2: {str(e)}")
        raise

# Add this line to help with debugging
print("Python function runModel_V2 defined successfully")

# Add this line to help with debugging
print("Python function runModel_V2 defined successfully")


def load_v73_mat_file(file_path, var_name='X_data_all'):
    with h5py.File(file_path, 'r') as file:
        X_data_all = file[var_name][:]
        X_data_all = X_data_all.T
    return X_data_all

def plot_predictions_vs_truth(y_te, pred_te, var_explained, savename,plotsOn=False):
    # Assuming y_te and pred_te are structured with two columns for the two y values.
    fig, axs = plt.subplots(1, 2, figsize=(12, 6))

    for i in range(2):
        axs[i].scatter(y_te[:, i], pred_te[:, i], alpha=0.5)
        axs[i].plot([y_te[:, i].min(), y_te[:, i].max()], [y_te[:, i].min(), y_te[:, i].max()], 'k--', lw=4)
        axs[i].set_xlabel('Actual')
        axs[i].set_ylabel('Predicted')
        axs[i].set_title(f'Y Value {i+1}')
    
    # Add R^2 value to the plot
    plt.figtext(0.5, 0.01, f'R^2 between predicted and actual = {var_explained:.2f}', ha='center', fontsize=12)
    plt.savefig(savename)
    # Save the figure
    if plotsOn:
        plt.show()
    return
   
