function ComputeAllWavelets(project)
    % find the proc_mice files
    proc_mice_files = project.returnDefaultReconstructionFiles();
   
    for i = 1:length(proc_mice_files)
        % load the data
        proc_mice_pos_data = load(proc_mice_files{i}).processedData;
        if ~isfield(proc_mice_pos_data, 'features')
            warning('Features not computed for %s. Computing features now.', proc_mice_files{i});
            proc_mice_pos_data.features = ComputeFeatures(proc_mice_pos_data, project);
            
            minmaxdata = project.parameters.features.minmaxdata;
            minmaxdata.distances.min = nanmin([minmaxdata.distances.min; features.distance_features.values']);
            minmaxdata.distances.max = nanmax([minmaxdata.distances.max; features.distance_features.values']);
            minmaxdata.angles.min = nanmin([minmaxdata.angles.min; features.angle_features.values']);
            minmaxdata.angles.max = nanmax([minmaxdata.angles.max; features.angle_features.values']);
        end
        ProcessingStatus = project.getProcessingStatus(proc_mice_files{i});
        wavelets_processed = ProcessingStatus.wavelets_completed;
        if wavelets_processed
            warning('Wavelets already computed for %s. Skipping.', proc_mice_files{i});
            continue;
        end

        % compute the features
        [proc_mice_pos_data.wavelets.angles.amps, ~, proc_mice_pos_data.wavelets.angles.Frame_amps] = findWavelets(proc_mice_pos_data.features.angle_features.values, project);
        [proc_mice_pos_data.wavelets.distances.amps, ~, proc_mice_pos_data.wavelets.distances.Frame_amps] = findWavelets(proc_mice_pos_data.features.distance_features.values, project);
        
        
        % save the data
        project.updateProcessingStatus(proc_mice_files{i}, 'wavelets_completed', 1, proc_mice_pos_data);
    end
    project.parameters.features.numWaveletAngleFeatures = size(proc_mice_pos_data.wavelets.angles.amps,2);
    project.parameters.features.numWaveletDistanceFeatures = size(proc_mice_pos_data.wavelets.distances.amps,2);

    project.saveProject();