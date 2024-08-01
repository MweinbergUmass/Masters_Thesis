function [features] = ComputeFeatures(proc_mice_pos_data, project)

    
feature_list_fn_dist = project.parameters.features.distances_xlsx_Path;
feature_table_dist = readtable(feature_list_fn_dist);
distance_features = CalculateDistanceFeatures(proc_mice_pos_data,feature_table_dist);


feature_list_fn_ang = project.parameters.features.angles_xlsx_path;
feature_table_ang = readtable(feature_list_fn_ang);
angle_features = CalculateAngleFeatures(proc_mice_pos_data,feature_table_ang);
features.angle_features = angle_features;
features.distance_features = distance_features;

if size(features.angle_features.values,1) < size(features.angle_features.values,2)
    features.angle_features.values = features.angle_features.values';
end
if size(features.distance_features.values,1) < size(features.distance_features.values,2)
    features.distance_features.values = features.distance_features.values';
end

end 