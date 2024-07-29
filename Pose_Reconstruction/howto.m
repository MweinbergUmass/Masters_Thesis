%% This will be a walkthrough of how to use the project class and perform pose reconstruction using a temporal convolutional autoencoder.
% First, add all the sleap h5's to the data directory. One folder for preds and one for labels.
% Then, run the following code to prepare the training data and train the model.

%Lets add all subfolders to the path first
addpath(genpath(pwd));
% set params
 default_model_params = struct(... 
    'sequence_length', 15, ...
    'input_shape', [15, 44], ... 
    'bottleneck_size', (22), ...
    'activation', 'selu', ...
    'conv_units', (256), ...
    'kernel_size', (3), ...
    'stride_size', (1), ...
    'batch_size', (512), ...
    'dropout_rate', 0.1, ... 
    'val_split', 0.2, ... 
    'epochs', (100), ...
    'ER_Patience', (25), ...
    'LR_patience', (10) ...
);
params = setparams(default_model_params); 
disp(params.autoenc.model_params)
%% We should add functionality in the constructor method to check if the project is already created and if so, load it
if ~exist('testDir', 'dir')
    project = Project('testDir', 'testDir', params); %this creates a project object which holds the data directory and the parameters and loads the python module
else
    project = Project.loadProject('testDir/testDir_project.mat'); %this loads the project object from the directory given
end 

[isPrepared, isTrained] = project.checkProcess(); %this checks if the data is prepared and the model is trained
if ~isPrepared.files
    project.prepareTrainingData('Data/'); %this prepares the training data, essentially it just loads the data from the directory (Data/) and stores it in the project object
else
    disp('Data is already prepared');
end
if ~isPrepared.traintest
    preproc_data_T_Conv_Training_W_Labels(project) %this is a helper function which preporcesses the data for training the autoencoder and stores it in the project object in the directory given by project.dataDir
else
    disp('Data is already split into training and testing');
end
if ~isTrained
    project.trainAuto(); %this trains the model and stores it in the project object in the directory given by project.modelsDir 
else
    disp('Model is already trained');
end

project.listModels(); %this will list the models in the project object


