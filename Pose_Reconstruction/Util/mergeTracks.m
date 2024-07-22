function merged_matrix = mergeTracks(tracks_matrix, track_names, track_type)
    % Find indices for the specified track type (e.g., 'FP' or 'RI')
    track_inds = find(strcmpi(track_names, track_type));
    

    % Initialize the merged matrix as empty
    merged_matrix = [];

    for i = 1:length(track_inds)
        current_track_matrix = squeeze(tracks_matrix(:,:,:,track_inds(i)));
        
        % If the merged matrix is empty, initialize it with the current track
        if isempty(merged_matrix)
            merged_matrix = current_track_matrix;
        else
            % Replace NaNs in merged_matrix with non-NaNs from current_track_matrix
            nan_indices = isnan(merged_matrix);
            merged_matrix(nan_indices) = current_track_matrix(nan_indices);
        end
    end
    merged_matrix = reshape(merged_matrix, [size(merged_matrix,1), size(merged_matrix,2) * 2]);
end

% Example of usage
% merged_fp = mergeTracks(tracks_matrix, track_names, 'FP');
% merged_ri = mergeTracks(tracks_matrix, track_names, 'RI');
