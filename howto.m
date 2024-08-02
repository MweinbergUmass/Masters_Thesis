%% This will be a walkthrough of how to use the project class and perform pose reconstruction using a temporal convolutional autoencoder.
% First, add all the sleap h5's to the data directory. One folder for preds and one for labels.
% Then, run the following code to prepare the training data and train the model.
%Lets add all subfolders to the path first
addpath(genpath('Pose_Reconstruction'));
addpath("util/")
%setuppyenv();
%%
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
%% checking if stuff exists and if not, running it.
if ~exist('testDir', 'dir')
    project = Project('testDir', params); %this creates a project object which holds the data directory and the parameters and loads the python module
else
    project = Project.loadProject('testDir/testDir_project.mat'); %this loads the project object from the directory given
end 

[isPrepared, isTrained] = project.checkProcess(); %this checks if the data is prepared and the model is trained
if ~isPrepared.files
    project.prepareTrainingData_PR('Data/'); %this prepares the training data, essentially it just loads the data from the directory (Data/) and stores it in the project object
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

%% Now we will do the reconstruction
sleaph5path = 'TestData/main_newcam_proj_real_newcopy.107_WIN_20240607_15_51_02_Pro_output_converted.analysis.h5';
existingProcessedFile = project.getProcessedFile(sleaph5path);
if ~isempty(existingProcessedFile)
    disp(['File already processed. Loading: ' existingProcessedFile]);
    load(existingProcessedFile, 'processedData');
    proc_mice_pos_data = processedData;
else 
    [proc_mice_pos_data] = reconstruct_sleap_preds(sleaph5path, project); %this will reconstruct the data using the trained model and store it in the project object in the directory given by project.processedDir
end


%%
sleaph5path2 = 'TestData/main_newcam_proj_real_newcopy.105_WIN_20240607_14_34_33_Pro_output_converted.analysis.h5';
existingProcessedFile = project.getProcessedFile(sleaph5path2);
if ~isempty(existingProcessedFile)
    disp(['File already processed. Loading: ' existingProcessedFile]);
    load(existingProcessedFile, 'processedData');
    proc_mice_pos_data2 = processedData;
else 
    [proc_mice_pos_data2] = reconstruct_sleap_preds(sleaph5path2, project); %this will reconstruct the data using the trained model and store it in the project object in the directory given by project.processedDir
end




%% Okay the structure of the proc_mice_pos_data is as follows:
% proc_mice_pos_data.ri.posdata_reconstructed is the reconstructed data for the resident mouse
% proc_mice_pos_data.fp.posdata_reconstructed is the reconstructed data for the fiber mouse

% This is what we will be working with. Lets take a look at the data structure
disp(proc_mice_pos_data)

%% here's what each field in the init struct means
% node_names: [22x1 string] %these are the names of the nodes in the sleap file 
% sleappath: 'TestData/main_newcam_proj_real_newcopy.107_WIN_20240607_15_51_02_Pro_output_converted.analysis.h5' %this is the path to the sleap file
%        ri: [1x1 struct]  %this is the resident mouse data
%        fp: [1x1 struct]   %this is the fiber mouse data
% sequence_length: 15 %this is the sequence length used for training the model


disp(proc_mice_pos_data.fp)
%% here's what each field in the secondary fp (symmetric to ri) struct means
% refdata: [2x22 double] %this is the reference data for the fiber mouse used in the reconstruction
% number_of_pts_found: [22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 ... ] (1x26755 double) %this is the number of points found in each frame
%        scale_factor: 0.0063 %this is the scale factor used in the reconstruction
%            centroid: [1x1 struct] %this is the centroid of the fiber mouse it contains the reference and frame centroids and the frame rotation
%      frame_rotation: [0.5486 0.8844 0.5697 0.5479 0.9234 0.7172 0.5658 0.8565 0.6458 0.1513 0.3968 0.3842 0.3454 0.8327 0.5712 ... ] (1x26755 double) %this is the frame rotation used in the reconstruction
%    posdata_centered: [44x26755 double] %this is the centered data used in the reconstruction
% posdata_centered_qc: [44x26755 double] %this is the centered data used in the reconstruction after quality control essentially the same as posdata_centered but with NaNs removed and with data further than N standard deviations from the mean removed
%                orig: [44x26755 double] %this is the original data
%   reconstructedData: [26740x44 double] %this is the reconstructed data in the ego center reference frame
% posdata_reconstructed: [44x26740 double] %this is the reconstructed data after inverting the ego center

%% lets plot the data before and after reconstruction
figure
subplot(1,2,1)
plot(proc_mice_pos_data.fp.orig(1,:), proc_mice_pos_data.fp.orig(1+22,:), 'r.') %this plots the nose of the fiber mouse x and y
title('Original Data')
subplot(1,2,2)
plot(proc_mice_pos_data.fp.posdata_reconstructed(1,:), proc_mice_pos_data.fp.posdata_reconstructed(1+22,:), 'b.')
title('Reconstructed Data')

%% Lets display nan's before and after the reconstruction
nans_before = sum(isnan(proc_mice_pos_data.fp.orig(:)));
nans_after = sum(isnan(proc_mice_pos_data.fp.posdata_reconstructed(:)));
disp(['Number of NaNs before reconstruction: ' num2str(nans_before)])
disp(['Number of NaNs after reconstruction: ' num2str(nans_after)]) %this should be close to zero but it might not be due to the quality control

%% Now we will extract all the features from the data
addpath(genpath('Embedding'))
ComputeAllFeatures(project) %this will compute all the features for the data and store it in the project object in the directory given by the fileDirectory: project.fileDirectory

%% Now lets take a look at some of the features
proc_mice_pos_data2 = load(existingProcessedFile, 'processedData').processedData;
% First, they are stored like this:
% proc_mice_pos_data.features.angle_features
% proc_mice_pos_data.features.distance_features
% each of these contain the info for the features and the features are actually stored in the values field
% lets take a look at the angle features
figure
subplot(1,2,1)
plot(proc_mice_pos_data2.features.angle_features.values(1,:))
title('Angle Feature 1')
subplot(1,2,2)
plot(proc_mice_pos_data2.features.angle_features.values(2,:))
title('Angle Feature 2')



%% Now we will compute the wavelets
ComputeAllWavelets(project) %this will compute all the wavelets for the data and store it in the project object in the directory given by the fileDirectory: project.fileDirectory
%% Now lets take a look at some of the wavelets
% First, they are stored like this:
% proc_mice_pos_data.wavelets.angles.amps, these are the normalized amplitudes of the wavelets
% proc_mice_pos_data.wavelets.angles.Frame_amps, these are the frame amplitudes of the wavelets used to normalize
% there are also the distances
% lets take a look at a generated spectrogram
numperiods = project.parameters.wavelets.numPeriods;
figure
subplot(1,2,1)
imagesc(proc_mice_pos_data2.wavelets.angles.amps(:,1:numperiods))
xlabel('Scale')
ylabel('Frame')
title('Wavelet Transform for Angle Feature 1')
subplot(1,2,2)
imagesc(proc_mice_pos_data2.wavelets.angles.amps(:, numperiods+1:numperiods+numperiods))
xlabel('Scale')
ylabel('Frame')
title('Wavelet Transform for Angle Feature 2')
%%
TrainInitEmbedding(project)
%%
TrainMLP(project)
%%
Embedalldata(project)
