function TrainEmbedding(project)
% assumes ComputeAllFeatures and ComputeAllWavelets have been run

% First we need to figure out the total number of frames there are and how many we want to grab from each file
TrainingSetSize = project.parameters.embedding.TrainingSetSize;
numFiles = length(project.fileRegistry);
lengths = project.returnDataLengths();
uniformIndices = round(linspace(1, sum(lengths), TrainingSetSize));
% now we need to figure out which file each index corresponds to
fileIndices = zeros(1, TrainingSetSize);
fileStarts = [1 cumsum(lengths(1:end-1))+1];
% for each index, find the file it corresponds to
for i = 1:TrainingSetSize
    fileIndices(i) = find(uniformIndices(i) >= fileStarts, 1, 'last');
end

% now we need to load the data
proc_mice_pos_files = project.returnDefaultReconstructionFiles();

% initialize the matrices which will hold the features
angle_features_all = zeros(TrainingSetSize,project.parameters.features.numAngleFeatures); 
distance_features_all = zeros(TrainingSetSize,project.parameters.features.numDistanceFeatures);
wavelet_angle_features_all = zeros(TrainingSetSize,project.parameters.features.numWaveletAngleFeatures);
wavelet_distance_features_all = zeros(TrainingSetSize,project.parameters.features.numWaveletDistanceFeatures);
currentIndex = 1;

for i = 1:numFiles
    % load the data
    % check if the embedding has been computed
    ProcessingStatus = project.getProcessingStatus(proc_mice_pos_files{i});
    if ProcessingStatus.features_extracted == 0
        warning('Features not computed for %s. Skipping.', proc_mice_pos_files{i});
        continue;
    end
    if ProcessingStatus.wavelets_completed == 0
        warning('Wavelets not computed for %s. Skipping.', proc_mice_pos_files{i});
        continue;
    end
    if ProcessingStatus.embedding_processed
        warning('Embedding already computed for %s. Skipping.', proc_mice_pos_files{i});
        continue;
    end

    proc_mice_pos_data = load(proc_mice_pos_files{i}).processedData;
    
    indices = uniformIndices(fileIndices == i);
    % grab the features and wavelets
    angle_features = proc_mice_pos_data.features.angle_features.values(indices,:);
    distance_features = proc_mice_pos_data.features.distance_features.values(indices,:);
    angle_wavelets = proc_mice_pos_data.wavelets.angles.amps(indices,:);
    distance_wavelets = proc_mice_pos_data.wavelets.distances.amp(indices,:);
    
    % Calculate the number of indices for the current file
    numIndices = size(angle_features, 1);
    
    % Calculate the end index
    endIndex = currentIndex + numIndices - 1;
    
    % Add the features to the matrices
    angle_features_all(currentIndex:endIndex, :) = angle_features;
    distance_features_all(currentIndex:endIndex, :) = distance_features;
    wavelet_angle_features_all(currentIndex:endIndex, :) = angle_wavelets;
    wavelet_distance_features_all(currentIndex:endIndex, :) = distance_wavelets;
    
    % Update the current index for the next iteration
    currentIndex = endIndex + 1;
end

% Now we need to normalize the features
% Normalize the angle features
angle_features_all = (angle_features_all - project.parameters.features.minmaxdata.angles.min) ./ (project.parameters.features.minmaxdata.angles.max - project.parameters.features.minmaxdata.angles.min);
% Normalize the distance features
distance_features_all = (distance_features_all - project.parameters.features.minmaxdata.distances.min) ./ (project.parameters.features.minmaxdata.distances.max - project.parameters.features.minmaxdata.distances.min);
% wavelets are already normalized

% okay now lets make sure we save all the features in the same matrix
features_all = [angle_features_all, distance_features_all, wavelet_angle_features_all, wavelet_distance_features_all];



% Now we need to construct the distance matrices
% First we need to calculate the distance matrices
angle_distance_matrix = squareform(pdist(angle_features_all));
distance_distance_matrix = squareform(pdist(distance_features_all));
wavelet_angle_distance_matrix = findKLDivergences(wavelet_angle_features_all);
wavelet_distance_distance_matrix = findKLDivergences(wavelet_distance_features_all);

% Now we need to normalize the distance matrices
% Normalize the angle distance matrix by the max value
angle_distance_matrix = angle_distance_matrix ./ max(angle_distance_matrix(:));
% Normalize the distance distance matrix by the max value
distance_distance_matrix = distance_distance_matrix ./ max(distance_distance_matrix(:));
% Normalize the wavelet angle distance matrix by the max value
wavelet_angle_distance_matrix = wavelet_angle_distance_matrix ./ max(wavelet_angle_distance_matrix(:));
% Normalize the wavelet distance distance matrix by the max value
wavelet_distance_distance_matrix = wavelet_distance_distance_matrix ./ max(wavelet_distance_distance_matrix(:));

combined_distance_matrix = (angle_distance_matrix + distance_distance_matrix + wavelet_angle_distance_matrix + wavelet_distance_distance_matrix) ./ 4;
combined_distance_matrix = (combined_distance_matrix + combined_distance_matrix') ./ 2;



