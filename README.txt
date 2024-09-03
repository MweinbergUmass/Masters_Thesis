# Masters Thesis Project

## About

This repository contains all the code and data for a Master's Thesis project focused on pose reconstruction and behavioral analysis using machine learning techniques.

## Project Structure

The project is organized around a central `Project` class that handles data management and model tracking for individual use cases. It's coupled with a parameter dictionary to implement various parameter changes for the models.

### Key Components:

1. **Pose Reconstruction**: Autoencoder-based reconstruction of animal poses.
2. **Feature Extraction**: Computation of geometric and wavelet-based features from pose data.
3. **Embedding**: Training of embeddings using t-SNE and MLP for dimensionality reduction and visualization.
4. **Data Processing**: Handling of SLEAP output files and preprocessing steps.

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/MweinbergUmass/Masters_Thesis.git
   ```

2. Set up the Python environment:
   - For Mac: Use `environment_mac.yml`
   - For Windows: Use `environment_win.yml`

   ```
   conda env create -f environment_[mac/win].yml
   ```

3. Activate the environment:
   ```
   conda activate [environment_name]
   ```

## Usage

The main workflow is implemented through the `Project` class. Here's a basic usage example:
matlab
% Create a new project
project = Project.create('MyProject');
% Prepare training data
project.prepareTrainingData_PR('path/to/data');
% Train autoencoder
project.trainAuto('my_model');
% Compute features and embeddings
ComputeAllFeatures(project);
ComputeAllWavelets(project);
TrainInitEmbedding(project);
% Set and use MLP model
project.setMLPModel();


For more detailed usage, refer to the `howto.m` or `howto.mlx` files in the repository.

## Key Files

- `util/Project.m`: Core class for project management.
- `Pose_Reconstruction/`: Contains autoencoder models and reconstruction code.
- `Embedding/`: Includes code for feature extraction, t-SNE, and MLP training.
- `Data/`: Stores processed data and default models.

## Dependencies

This project uses both MATLAB and Python. Key dependencies include:

- MATLAB (with Signal Processing Toolbox)
- Python 3.9+
- TensorFlow
- scikit-learn
- h5py

For a complete list of Python dependencies, refer to the `requirements.txt` file.

## Contributing

Contributions to this project are welcome. Please ensure to follow the existing code style and add unit tests for any new features.

## Contact

For any queries regarding this project, please contact:
Max Weinberg - mweinberg@umass.edu

