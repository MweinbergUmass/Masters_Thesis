function ComputeAllFeatures(project)
    % find the proc_mice files
    proc_mice_files = project.returnDefaultReconstructionFiles();
   
    % -compute the features
    temp_proc_mice_pos_data = load(proc_mice_files{1}).processedData;

    temp_features = ComputeFeatures(temp_proc_mice_pos_data, project);
    

    % initialize minmaxdata
    minmaxdata.distances.min = nan(1,size(temp_features.distance_features.values,2));
    minmaxdata.distances.max = nan(1,size(temp_features.distance_features.values,2));
    minmaxdata.angles.min = nan(1,size(temp_features.angle_features.values,2));
    minmaxdata.angles.max = nan(1,size(temp_features.angle_features.values,2));

    clear temp_proc_mice_pos_data temp_features;




    % for each proc_mice file
    for i = 1:length(proc_mice_files)
        % load the data
        proc_mice_pos_data = load(proc_mice_files{i}).processedData;

        % compute the features
        [features] = ComputeFeatures(proc_mice_pos_data, project);
        
        minmaxdata.distances.min = nanmin([minmaxdata.distances.min; features.distance_features.values]);
        minmaxdata.distances.max = nanmax([minmaxdata.distances.max; features.distance_features.values]);
        minmaxdata.angles.min = nanmin([minmaxdata.angles.min; features.angle_features.values]);
        minmaxdata.angles.max = nanmax([minmaxdata.angles.max; features.angle_features.values]);
        

        proc_mice_pos_data.features = features; 

        % save the data
        project.updateProcessingStatus(proc_mice_files{i}, 'features_extracted', 1, proc_mice_pos_data);
    end
    project.parameters.features.numAngleFeatures = size(features.angle_features.values,2);
    project.parameters.features.numDistanceFeatures = size(features.distance_features.values,2);
    project.parameters.features.minmaxdata = minmaxdata;
    project.saveProject();
end 