function [features, angles, distances, MinMaxData] = graballfeats(project)
    proc_mice__pos_file_list = project.returnDefaultReconstructionFiles;

    all_features = cell(1,length(proc_mice__pos_file_list));
    bookeeper = cell(1,length(proc_mice__pos_file_list));
    feature_lengths = zeros(1,length(proc_mice__pos_file_list));
    
    for i = 1:length(proc_mice__pos_file_list)
    fprintf('Appending Features for File %d: %s\n',i, proc_mice__pos_file_list{1,i});
    load(proc_mice__pos_file_list{1,i})
    [angle_features, distance_features] = ComputeFeatures(proc_mice_pos_data,project);
    temp_features = [angle_features.values', distance_features.values'];
    all_features{i} = temp_features;
    bookeeper{i} = i .* ones(size(temp_features,1),1);
    feature_lengths(i) = length(temp_features);
    if saveraw
    proc_mice_pos_data.features.raw.btween = temp_features;
    save(proc_mice__pos_file_list{1,i},"proc_mice_pos_data");
    pro
    end 
    end
    features_info.angle_features = rmfield(angle_features,"values");
    features_info.distance_features = rmfield(distance_features, "values"); 


   %% now I need to run through one round of truncation to find the percentiles for each feature
   
   all_features_mat = cell2mat(all_features');
   all_features_normed_final = zeros(size(all_features_mat));
   for i = 1:size(all_features_mat,2)
        all_features_normed_final(:,i) = rescale(all_features_mat(:,i),-1,1);    
   end
   min_all_features_mat = min(all_features_mat);
   max_all_features_mat = max(all_features_mat);
   MinMaxData = [max_all_features_mat;min_all_features_mat];


  bookeeper = cell2mat(bookeeper');

  features.all_features = all_features;
  features.bookeeper = bookeeper;
  features.all_features_normed_final = all_features_normed_final;
  features.features_info = features_info;
  features.onehotexp = onehotexp;
  features.file_lists = file_lists;
  features.feature_lengths = feature_lengths;

   angles_inds = 1:length(features.features_info.angle_features.names);
dist_inds = 1:length(features.features_info.distance_features.names);
angles = features.all_features_normed_final(:,angles_inds);
distances = features.all_features_normed_final(:,angles_inds(end)+dist_inds);



    end


