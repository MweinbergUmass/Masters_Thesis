from sklearn.neural_network import MLPRegressor
from scipy.io import loadmat, savemat
from joblib import dump, load
import matplotlib.pyplot as plt
import matplotlib as mpl
from scipy.stats import pearsonr
import h5py
from sklearn.manifold import TSNE
import numpy as np

# the order of opperations:
#   run_unif_train_model(): (This will train the model on the uniformlly sampled data)
#   run_run_init_unif_RunModel (This will run the model on uniformly sampled model on all the data and output 'Data/init_unif_all_y_embedded.mat' )

def runTsne(distance_matrix,perplexity_scale,n_components=2,verbose=2,n_iter=1000):
    num_2_sample = distance_matrix.shape[1]
    tsne = TSNE(metric="precomputed", n_components=n_components, random_state=42,init='random', perplexity=num_2_sample/perplexity_scale,verbose=verbose, n_iter=n_iter)
    Y_embedded = tsne.fit_transform(distance_matrix)
    return Y_embedded

def Embed(datapath, savename):
    Data = loadmat(datapath)['X_data_all']
    modelpath = 'Models/unif_MLP.joblib'
    Y_embedded = runModel(Data, modelpath, savename)
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
               
def trainModel(X_tr, y_tr, X_te, y_te, savename, PlotsOn=True):
    mlp = MLPRegressor(hidden_layer_sizes=(512,256,128,64),verbose=True,early_stopping=True,validation_fraction=0.1,batch_size=512)
    mlp.fit(X_tr, y_tr)
    pred_te = mlp.predict(X_te)
    var_explained = pearsonr(y_te.flatten(),pred_te.flatten())[0]**2
    print(r'R^2 between predicted and actual =%.2f'%var_explained)
    dump(mlp, savename)
    if PlotsOn:
        plt.figure(figsize=(10, 6))
        plt.plot(mlp.loss_curve_, label='Training Loss')
        plt.title('Model Loss during Training')
        plt.xlabel('Epochs')
        plt.ylabel('Loss')
        plt.legend()
        plt.savefig('training_loss.png')
        plt.show()
        plot_predictions_vs_truth(y_te, pred_te, var_explained, savename='PredsVSgt.png')

    return

def runModel(X_data, modelPath, savename):
    mlp = load(modelPath)
    Y_embedded = mlp.predict(X_data)
    Y_embedded_dict = {'Y_embedded': Y_embedded}
    savemat(savename, Y_embedded_dict)
    return Y_embedded

def runModel_V2(X_data, modelPath='Models/unif_MLP.joblib'):
    mlp = load(modelPath)
    Y_embedded = mlp.predict(X_data)
    return Y_embedded


def load_v73_mat_file(file_path, var_name='X_data_all'):
    with h5py.File(file_path, 'r') as file:
        X_data_all = file[var_name][:]
        X_data_all = X_data_all.T
    return X_data_all

def plot_predictions_vs_truth(y_te, pred_te, var_explained, savename):
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
    
    # Save the figure
    plt.savefig(savename)
    plt.show()
