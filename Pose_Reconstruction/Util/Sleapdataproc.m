function [mice_pos_data,track_names]  = Sleapdataproc(project,sleaph5path)

disp('starting to proc:')
disp(sleaph5path)

[node_names, tracks_matrix,track_names] = readh5(sleaph5path, project);

fp_mouse = (mergeTracks(tracks_matrix, track_names, 'fp'))';
ri_mouse = (mergeTracks(tracks_matrix, track_names, 'ri'))';
if ~any(strcmpi(track_names, 'fp'))
    fp_mouse = (mergeTracks(tracks_matrix, track_names, 'track_0'))';
end
if ~any(strcmpi(track_names, 'ri'))
    ri_mouse = (mergeTracks(tracks_matrix, track_names, 'track_1'))';
end


mice_pos_data.ri_mouse = ri_mouse;
mice_pos_data.fiber_mouse = fp_mouse;
mice_pos_data.node_names = node_names;

numnans = length(find(isnan(mice_pos_data.ri_mouse))) +  length(find(isnan(mice_pos_data.fiber_mouse)));
prcntnans = (numnans / (numel(mice_pos_data.ri_mouse) + numel(mice_pos_data.fiber_mouse))) * 100;
disp(['this file is ', num2str(prcntnans), '% nans']);
    function [node_names, tracks_matrix, track_names] = readh5(sleaph5path, project)
    try
        % Try reading directly using h5read (works on Mac/Linux)
        node_names = h5read(sleaph5path, '/node_names');
        tracks_matrix = h5read(sleaph5path, '/tracks');
        track_names = h5read(sleaph5path, '/track_names');
    catch
        % If direct reading fails, use the module method (for Windows)
        mod = project.module;
        node_names = mod.h5read(sleaph5path, '/node_names');
        node_names = convertpy(node_names);
        
        % Read tracks and transpose to correct dimensions
        tracks_matrix = double(mod.h5read(sleaph5path, '/tracks'));
        tracks_matrix = permute(tracks_matrix, [4, 3, 2, 1]);
        
        track_names = mod.h5read(sleaph5path, '/track_names');
        track_names = convertpy(track_names);
    end
end
function cell_array = convertpy(numpy_array)
    array_length = int64(numpy_array.shape{1});
    % Preallocate a cell array
    cell_array = cell(array_length, 1);
    % Iterate and convert each element, cleaning up the strings
    for i = 1:array_length
        % Convert to string and remove extra characters
        str = char(numpy_array.item(int64(i-1)));
        % Remove the 'b' at the beginning and extra quotes
        str = regexprep(str, '^b''|''$', '');
        cell_array{i} = str;
    end
end
end 
 
