function ComputeAllFeatures(project)
    % find the proc_mice files
    proc_mice_files = project.returnDefaultReconstructionFiles();
   
    % -compute the features
    temp_proc_mice_pos_data = load(proc_mice_files{1});
    [temp_features] = computeFeatures(temp_proc_mice_pos_data, project);

    % initialize minmaxdata
    minmaxdata.distances.min = nan(1,length(temp_features.distance_features));
    minmaxdata.distances.max = nan(1,length(temp_features.distance_features));
    minmaxdata.angles.min = nan(1,length(temp_features.angle_features));
    minmaxdata.angles.max = nan(1,length(temp_features.angle_features));

    clear temp_proc_mice_pos_data temp_features;




    % for each proc_mice file
    for i = 1:length(proc_mice_files)
        % load the data
        proc_mice_pos_data = load(proc_mice_files{i});

        % compute the features
        [features] = computeFeatures(proc_mice_pos_data, project);
        
        minmaxdata.distances.min = nanmin([minmaxdata.distances.min; features.distance_features]);
        minmaxdata.distances.max = nanmax([minmaxdata.distances.max; features.distance_features]);
        minmaxdata.angles.min = nanmin([minmaxdata.angles.min; features.angle_features]);
        minmaxdata.angles.max = nanmax([minmaxdata.angles.max; features.angle_features]);

        proc_mice_pos_data.features = features;

        % save the data
        project.updateProcessingStatus(proc_mice_files{i}, 'features_completed', 1);
    end

end 