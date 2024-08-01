function [sequences_fp,sequences_ri,proc_mice_pos_data,sequence_length]= preprocforVAE_T_Conv(project,sleaph5path,sequence_length,features_means)
    if nargin < 3
        sequence_length = 15;
    end 
    if nargin < 4
        load(strcat('Data', filesep, 'Static_AutoData', filesep, 'features_means'),'features_means');
    end 
    if nargin < 5
        load(strcat('Data', filesep, 'Static_AutoData', filesep, 'reference_frame'),'reference_frame');
    end 
        
    
    
    mice_pos_data = Sleapdataproc(project, sleaph5path);
    proc_mice_pos_data.node_names = mice_pos_data.node_names;
    proc_mice_pos_data.sleappath = sleaph5path;

    temp_ri_stru = ego_center_v4(reference_frame, mice_pos_data.ri_mouse);
    temp_fp_stru = ego_center_v4(reference_frame, mice_pos_data.fiber_mouse);
    
    proc_mice_pos_data.ri = temp_ri_stru;
    proc_mice_pos_data.ri.orig = mice_pos_data.ri_mouse;


    proc_mice_pos_data.fp = temp_fp_stru;
    proc_mice_pos_data.fp.orig = mice_pos_data.fiber_mouse;

    ri_preds = temp_ri_stru.posdata_centered_qc;
    fp_preds = temp_fp_stru.posdata_centered_qc;

    sequences_fp = create_sequences(fp_preds', sequence_length);
    sequences_ri = create_sequences(ri_preds', sequence_length);

    % Fill NaNs with the mean of each feature
    sequences_fp = fill_nan_with_mean(sequences_fp, features_means);
    sequences_ri = fill_nan_with_mean(sequences_ri, features_means);



function sequences = fill_nan_with_mean(sequences, feature_means)
    % sequences: (num_sequences, sequence_length, num_features)
    % feature_means: (1, num_features)

    % Repeat feature_means to match the shape of sequences
    feature_means_repeated = repmat(reshape(feature_means, 1, 1, []), size(sequences, 1), size(sequences, 2), 1);
    
    % Find NaNs in the sequences
    nan_mask = isnan(sequences);
    
    % Replace NaNs with the corresponding feature means
    sequences(nan_mask) = feature_means_repeated(nan_mask);
end
end 
