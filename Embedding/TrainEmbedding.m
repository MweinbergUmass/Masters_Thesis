%% This function will:
    % 1. Start by computing the features from all the data
    % -Find all proc_mice file, load it, for each:
    % -compute features
    % -update minmaxdata
    % -update length cell array which is somehow coupled to the proc_mice_file (maybe use file registry for this?)
    % -save the data

function TrainEmbedding(project)
    % find the proc_mice files
    proc_mice_files = project.returnDefaultReconstructionFiles();
    
    % initialize the length cell array
    length_cell = cell(1, length(proc_mice_files));

   
    % start by computing the features for initial info
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
        
        minmaxdata.distances.min = nanmin([minmaxdata.min; features.distance_features]);
        minmaxdata.distances.max = nanmax([minmaxdata.max; features.distance_features]);
        minmaxdata.angles.min = nanmin([minmaxdata.min; features.angle_features]);
        minmaxdata.angles.max = nanmax([minmaxdata.max; features.angle_features]);

        proc_mice_pos_data.features = features;
        % save the data
        save(proc_mice_files{i}, 'proc_mice_pos_data');
        
    end
    


end 