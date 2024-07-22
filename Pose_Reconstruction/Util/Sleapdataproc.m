function [mice_pos_data,track_names]  = Sleapdataproc(sleaph5path)
disp('starting to proc:')
disp(sleaph5path)

node_names = h5read(sleaph5path,'/node_names');
tracks_matrix = h5read(sleaph5path,'/tracks');
track_names = h5read(sleaph5path, '/track_names');
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
end 
