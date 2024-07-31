function TrainEmbedding(project)
% assumes ComputeAllFeatures and ComputeAllWavelets have been run

% First we need to figure out the total number of frames there are and how many we want to grab from each file
TrainingSetSize = project.parameters.embedding.TrainingSetSize;
numFiles = length(project.fileRegistry);
recons_type = fieldnames(project.fileRegistry(1).processed)
lengths = zeros(numFiles,1);

% I should make this a method in the project class



