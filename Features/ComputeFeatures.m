function [angle_features, distance_features] = ComputeFeatures(proc_mice_pos_data, project)

feature_list_fn_dist = project.parameters.features.distances_xlsx_Path;
feature_table_dist = readtable(feature_list_fn_dist);
distance_features = CalculateDistanceFeatures(proc_mice_pos_data,feature_table_dist);


feature_list_fn_ang = project.parameters.features.angles_xlsx_path;
feature_table_ang = readtable(feature_list_fn_ang);
angle_features = CalculateAngleFeatures(proc_mice_pos_data,feature_table_ang);
angle_features = angle_features;
distance_features = distance_features;

end 