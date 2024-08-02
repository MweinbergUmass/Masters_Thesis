function Embedoos(proc_mice_pos_data_file, project)
    % okay so we have the MLP now lets use it to embed the out of sample data
    % first we need to load the data
    
    proc_mice_pos_data = load(proc_mice_pos_data_file).processedData;
    % now we need to normalize the distances and angles
    minmaxdata = project.parameters.features.minmaxdata;
    angle_features = (proc_mice_pos_data.features.angle_features.values - minmaxdata.angles.min) ./ (minmaxdata.angles.max - minmaxdata.angles.min);
    distance_features = (proc_mice_pos_data.features.distance_features.values - minmaxdata.distances.min) ./ (minmaxdata.distances.max - minmaxdata.distances.min);
    
    % now we need to grab the wavelets to make features_all = [angle_features_all, distance_features_all, wavelet_angle_features_all, wavelet_distance_features_all];
    features_all = [angle_features, distance_features, proc_mice_pos_data.wavelets.angles.amps, proc_mice_pos_data.wavelets.distances.amps];
    project.load_TSNE_MLP();
    
    % now we need to embed the data
    proc_mice_pos_data.Motmap.Zvals = double(project.module.Embed(features_all,project.parameters.embedding.mlp.metadata.model_path));
    proc_mice_pos_data.Motmap.mlp_path = project.parameters.embedding.mlp.metadata.model_path;
    % updateProcessingStatus(obj, filePath, statusType, value, processedData)
    project.updateProcessingStatus(proc_mice_pos_data_file, 'embedded', 1, proc_mice_pos_data);
    project.saveProject();
    
    
end 