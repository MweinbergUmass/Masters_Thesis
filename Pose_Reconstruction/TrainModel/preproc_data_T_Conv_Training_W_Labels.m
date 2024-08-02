function preproc_data_T_Conv_Training_W_Labels(project)
   
    sequence_length = project.parameters.autoenc.model_parameters.sequence_length;

    selected_files_preds = project.parameters.selected_files_preds;
    selected_files_labels = project.parameters.selected_files_labels;
    num_files = length(selected_files_preds);
    load(project.parameters.autoenc.reference_frame_path, 'reference_frame');

    % Initialize cell arrays to hold processed data
    ri_pred_cell = cell(1, num_files);
    ri_pred_cell_labels = cell(1, num_files);
    fp_pred_cell = cell(1, num_files);
    fp_pred_cell_labels = cell(1, num_files);

    % Process each selected file
    for i = 1:num_files
        disp(['Processing File num: ', num2str(i)])
        mice_pos_data_preds = Sleapdataproc(project,selected_files_preds{i});
        mice_pos_data_labels = Sleapdataproc(project,selected_files_labels{i});
    
        % Process ri_mouse data
        temp_ri_stru_preds = ego_center_v4(reference_frame, mice_pos_data_preds.ri_mouse);
        temp_ri_stru_labels = ego_center_v4(reference_frame, mice_pos_data_labels.ri_mouse);

        % Process fiber_mouse data
        temp_fp_stru_preds = ego_center_v4(reference_frame, mice_pos_data_preds.fiber_mouse);
        temp_fp_stru_labels = ego_center_v4(reference_frame, mice_pos_data_labels.fiber_mouse);

        % Store processed data
        ri_pred_cell{i} = temp_ri_stru_preds.posdata_centered_qc;
        ri_pred_cell_labels{i} = temp_ri_stru_labels.posdata_centered_qc;
        fp_pred_cell{i} = temp_fp_stru_preds.posdata_centered_qc;
        fp_pred_cell_labels{i} = temp_fp_stru_labels.posdata_centered_qc;
        
    end
    diff_lengths_ri = cellfun(@length,ri_pred_cell) - cellfun(@length,ri_pred_cell_labels);
    for i = 1:length(ri_pred_cell)
        ri_pred_cell{i} = ri_pred_cell{i}(:,1:end-diff_lengths_ri(i));
    end 
    diff_lengths_fp = cellfun(@length,fp_pred_cell) - cellfun(@length,fp_pred_cell_labels);
    for i = 1:length(fp_pred_cell)
        fp_pred_cell{i} = fp_pred_cell{i}(:,1:end-diff_lengths_fp(i));
    end 
    
    % Calculate the total number of sequences
    total_sequences_ri = sum(cellfun(@(x) size(x, 1), ri_pred_cell)) - length(ri_pred_cell) * sequence_length;
    total_sequences_fp = sum(cellfun(@(x) size(x, 1), fp_pred_cell)) - length(fp_pred_cell) * sequence_length;

    % Preallocate arrays to hold sequences
    all_sequences_ri_X = NaN(total_sequences_ri, sequence_length, size(ri_pred_cell{1}, 1));
    all_sequences_ri_Y = NaN(total_sequences_ri, sequence_length, size(ri_pred_cell_labels{1}, 1));
    all_sequences_fp_X = NaN(total_sequences_fp, sequence_length, size(fp_pred_cell{1}, 1));
    all_sequences_fp_Y = NaN(total_sequences_fp, sequence_length, size(fp_pred_cell_labels{1}, 1));

    
    ri_seq_count = 0;
    fp_seq_count = 0;

    % Split data into sequences and remove sequences with NaNs
    for i = 1:length(ri_pred_cell)
        % Create sequences
        sequences_ri_X = create_sequences(ri_pred_cell{i}', sequence_length);
        sequences_ri_Y = create_sequences(ri_pred_cell_labels{i}', sequence_length);
        
        % Append to all_sequences_ri
        num_sequences = size(sequences_ri_X, 1);
        all_sequences_ri_X(ri_seq_count+1:ri_seq_count+num_sequences, :, :) = sequences_ri_X;
        all_sequences_ri_Y(ri_seq_count+1:ri_seq_count+num_sequences, :, :) = sequences_ri_Y;
        ri_seq_count = ri_seq_count + num_sequences;
    end
    clear ri_pred_cell ri_pred_cell_labels sequences_ri_X sequences_ri_Y
    for i = 1:length(fp_pred_cell)
        % Create sequences
        sequences_fp_X = create_sequences(fp_pred_cell{i}', sequence_length);
        sequences_fp_Y = create_sequences(fp_pred_cell_labels{i}', sequence_length);
        
        % Append to all_sequences_fp
        num_sequences = size(sequences_fp_X, 1);
        all_sequences_fp_X(fp_seq_count+1:fp_seq_count+num_sequences, :, :) = sequences_fp_X;
        all_sequences_fp_Y(fp_seq_count+1:fp_seq_count+num_sequences, :, :) = sequences_fp_Y;
        fp_seq_count = fp_seq_count + num_sequences;
    end
    clear fp_pred_cell fp_pred_cell_labels sequences_fp_X sequences_fp_Y


    % Trim the preallocated arrays to actual size
    all_sequences_ri_X = all_sequences_ri_X(1:ri_seq_count, :, :);
    all_sequences_ri_Y = all_sequences_ri_Y(1:ri_seq_count, :, :);
    %% X needs the raw preds with nans removed (So first lets remove all pages with any nan's in both
    % then shift X into Y such that all of Y remains and where Y = nan, we
    % set it to X

    nan_mask_ri = any(any(isnan(all_sequences_ri_X), 3), 2);
    all_sequences_ri_X = all_sequences_ri_X(~nan_mask_ri, :, :);
    all_sequences_ri_Y = all_sequences_ri_Y(~nan_mask_ri, :, :);
    %% now shift X into Y such that all Y remains and where Y = nan, we set it to X
    nan_indices = isnan(all_sequences_ri_Y);
    all_sequences_ri_Y(nan_indices) = all_sequences_ri_X(nan_indices);
    

    nan_mask_fp = any(any(isnan(all_sequences_fp_X), 3), 2);
    all_sequences_fp_X = all_sequences_fp_X(~nan_mask_fp, :, :);
    all_sequences_fp_Y = all_sequences_fp_Y(~nan_mask_fp, :, :);
    nan_indices = isnan(all_sequences_fp_Y);
    all_sequences_fp_Y(nan_indices) = all_sequences_fp_X(nan_indices);
    clear nan_indices
    % Concatenate all sequences
    alldataX = [all_sequences_fp_X; all_sequences_ri_X];
    clear all_sequences_fp_X all_sequences_ri_X
    alldataY = [all_sequences_fp_Y; all_sequences_ri_Y];
    clear all_sequences_fp_Y all_sequences_ri_Y
    % Define the train/test split ratio
    train_ratio = 0.7;
    num_train_sequences = round(size(alldataX, 1) * train_ratio);

    % Split the data sequentially
    train_dataX = alldataX(1:num_train_sequences, :, :);
    test_dataX = alldataX(num_train_sequences+1:end, :, :);
    clear alldataX
    train_dataY = alldataY(1:num_train_sequences, :, :);
    test_dataY = alldataY(num_train_sequences+1:end, :, :);
    clear alldataY

    arraysize = 2 * (prod(size(train_dataX)) * 8) / 1024^3;
    outputFile = fullfile(project.dataDir, 'traintestSeq.mat');
    project.parameters.autoenc.trainingsetpath = outputFile;
    if arraysize > 2
        project.log{end+1} = 'Variable "train_data" exceeds 2GB. Using MAT-file version 7.3.';
        save(outputFile, 'train_dataX', 'train_dataY', 'test_dataX', 'test_dataY', '-v7.3');
        project.parameters.autoenc.v73 = 1;

    else
        save(outputFile, 'train_dataX', 'train_dataY', 'test_dataX', 'test_dataY');
        project.parameters.autoenc.v73 = 0;
    end
    project.log{end+1} = sprintf('Saved processed data to %s', outputFile);
    project.parameters.autoenc.traintestdataready = true;
    project.saveProject
end
 