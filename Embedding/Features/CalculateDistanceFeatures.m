function distance_features = CalculateDistanceFeatures(data,feature_table)

%%initialize features
distance_features.names = {};
distance_features.MouseID = {};
distance_features.PtsMeasured = {};
distance_features.values = [];

%% number of scored sleap pts
num_sleap_pts = 22;


%% precalculate the centroids of A and B
centroid_trim = 20;
data.fp.centroid = [];
data.fp.centroid(1,:) = trimmean(data.fp.posdata_reconstructed([1:num_sleap_pts],:),centroid_trim);
data.fp.centroid(2,:) = trimmean(data.fp.posdata_reconstructed([num_sleap_pts+1:2*num_sleap_pts],:),centroid_trim);

data.ri.centroid = [];
data.ri.centroid(1,:) = trimmean(data.ri.posdata_reconstructed([1:num_sleap_pts],:),centroid_trim);
data.ri.centroid(2,:) = trimmean(data.ri.posdata_reconstructed([num_sleap_pts+1:2*num_sleap_pts],:),centroid_trim);




%% precalculate the center of the box (based on centroids)
excluded_percent = 2;
lower_bound_x = prctile([data.fp.centroid(1,:),data.ri.centroid(1,:)], excluded_percent);
upper_bound_x = prctile([data.fp.centroid(1,:),data.ri.centroid(1,:)], 100-excluded_percent);
lower_bound_y = prctile([data.fp.centroid(2,:),data.ri.centroid(2,:)], excluded_percent);
upper_bound_y = prctile([data.fp.centroid(2,:),data.ri.centroid(2,:)], 100-excluded_percent);

box_center = [mean([lower_bound_x,upper_bound_x]);mean([lower_bound_y,upper_bound_y])];
box_centers = box_center * ones(1,size(data.fp.centroid,2));











%% loop through all of the features
for f_ind = 1:length(feature_table.Name)
    if feature_table.include(f_ind) %% excel file indicates feature is included
        
        %%collect data pt 1
        pt1_mID = feature_table.pt1{f_ind}(1);
        pt1_ID = feature_table.pt1{f_ind}([2:end]);
        switch pt1_ID
            case 'centroid'
%                 disp([num2str(f_ind),' is centroid'])
                if strcmp(pt1_mID,'A')
                    pt1_vals_x = data.fp.centroid(1,:);
                    pt1_vals_y = data.fp.centroid(2,:);
                else
                    pt1_vals_x = data.ri.centroid(1,:);
                    pt1_vals_y = data.ri.centroid(2,:);
                end

            case 'boxcenter'
%                 disp([num2str(f_ind),' is box center'])
                    pt1_vals_x = box_centers(1,:);
                    pt1_vals_y = box_centers(2,:);

                
            otherwise %% is a point on the mouse
                pt1_ID = str2num(pt1_ID);
                if strcmp(pt1_mID,'A')
                    pt1_vals_x = data.fp.posdata_reconstructed(pt1_ID,:);
                    pt1_vals_y = data.fp.posdata_reconstructed(pt1_ID+num_sleap_pts,:);
                else
                    pt1_vals_x = data.ri.posdata_reconstructed(pt1_ID,:);
                    pt1_vals_y = data.ri.posdata_reconstructed(pt1_ID+num_sleap_pts,:);
                end
        end










        %%collect data pt 2
        pt2_mID = feature_table.pt2{f_ind}(1);
        pt2_ID = feature_table.pt2{f_ind}([2:end]);
        switch pt2_ID
            case 'centroid'
% %                 disp([num2str(f_ind),' is centroid'])
                if strcmp(pt2_mID,'A')
                    pt2_vals_x = data.fp.centroid(1,:);
                    pt2_vals_y = data.fp.centroid(2,:);
                else
                    pt2_vals_x = data.ri.centroid(1,:);
                    pt2_vals_y = data.ri.centroid(2,:);
                end

            case 'boxcenter'
% %                disp([num2str(f_ind),' is box center'])
                    pt2_vals_x = box_centers(1,:);
                    pt2_vals_y = box_centers(2,:);
            otherwise %% is a point on the mouse
                pt2_ID = str2num(pt2_ID);
                if strcmp(pt2_mID,'A')
                    pt2_vals_x = data.fp.posdata_reconstructed(pt2_ID,:);
                    pt2_vals_y = data.fp.posdata_reconstructed(pt2_ID+num_sleap_pts,:);
                else
                    pt2_vals_x = data.ri.posdata_reconstructed(pt2_ID,:);
                    pt2_vals_y = data.ri.posdata_reconstructed(pt2_ID+num_sleap_pts,:);
                end
        end






















        %% calculate the distance between the points
        temp_feature = sqrt((pt1_vals_x - pt2_vals_x).^2 + (pt1_vals_y - pt2_vals_y).^2);


        %% truncate the data
        switch feature_table.truncationStyle{f_ind}
            case 'sdev'
                if feature_table.truncation(f_ind)>0
                    temp_mean   =nanmean(temp_feature);
                    temp_std    =nanstd(temp_feature);
        
                    high_cutoff = temp_mean + feature_table.truncation(f_ind)*temp_std;
                    low_cutoff  = temp_mean - feature_table.truncation(f_ind)*temp_std;
        
                    %%remove outlier points
                    inds = find(temp_feature>high_cutoff | temp_feature<low_cutoff );
                    temp_feature(inds) = nan;
                end

            case 'prct'
                if feature_table.truncation(f_ind)>0
                    % Define lower and upper percentiles
                    lower_percentile = feature_table.truncation(f_ind)/2;
                    upper_percentile = 100-lower_percentile;

                    

                    % Calculate lower and upper percentile values
                    lower_threshold = prctile(temp_feature, lower_percentile);
                    upper_threshold = prctile(temp_feature, upper_percentile);

                    % Exclude outliers
                    temp_feature(find(temp_feature < lower_threshold | temp_feature > upper_threshold)) = nan;
                end
            otherwise
        end %% end truncation switch case





        %% fill in nan data points
        if feature_table.interpnanGap(f_ind)>0
            temp_feature = fillmissing(temp_feature,'linear','EndValues','nearest');
        end





        %% perform a running average filter
        if feature_table.filterwindow(f_ind)>0
            temp_feature = movmean(temp_feature, feature_table.filterwindow(f_ind), 'omitnan');
        end

        distance_features.names{end+1} = feature_table.Name{f_ind};
        distance_features.MouseID{end+1} = [  pt1_mID , pt2_mID   ];
        distance_features.PtsMeasured{end+1} = {  num2str(pt1_ID) , num2str(pt2_ID)   };

        distance_features.values(end+1,:) = temp_feature;


        if feature_table.includeDerivitive1(f_ind)
            distance_features.names{end+1} = [feature_table.Name{f_ind},'_derivative_1'];
            distance_features.MouseID{end+1} = [  pt1_mID , pt2_mID   ];
            distance_features.PtsMeasured{end+1} = {  num2str(pt1_ID) , num2str(pt2_ID)   };
            temp_feature_D = diff(temp_feature);
            temp_feature_D(end+1) = temp_feature_D(end);
            distance_features.values(end+1,:) = temp_feature_D;


            if feature_table.includeDerivitive2(f_ind)
                distance_features.names{end+1} = [feature_table.Name{f_ind},'_derivative_2'];
                distance_features.MouseID{end+1} = [  pt1_mID , pt2_mID   ];
                distance_features.PtsMeasured{end+1} = {  num2str(pt1_ID) , num2str(pt2_ID)   };
                temp_feature_DD = diff(temp_feature_D);
                temp_feature_DD(end+1) = temp_feature_DD(end);
                distance_features.values(end+1,:) = temp_feature_DD;
            end
        end


    end
end
return;
