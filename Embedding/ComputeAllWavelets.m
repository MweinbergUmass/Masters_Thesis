function ComputeAllWavelets(project)
    % find the proc_mice files
    proc_mice_files = project.returnDefaultReconstructionFiles();
   
    for i = 1:length(proc_mice_files)
        % load the data
        proc_mice_pos_data = load(proc_mice_files{i}).processedData;

        % compute the features
        proc_mice_pos_data.wavelets.angles = findWavelets(proc_mice_pos_data.features.angle_features.values, project);
        proc_mice_pos_data.wavelets.distances = findWavelets(proc_mice_pos_data.features.distance_features.values, project);
        

        % save the data
        project.updateProcessingStatus(proc_mice_files{i}, 'wavelets_completed', 1, proc_mice_pos_data);
    end