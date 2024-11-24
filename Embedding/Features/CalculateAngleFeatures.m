function angle_features = CalculateAngleFeatures(data,feature_table)

%%initialize features
angle_features.names = {};
angle_features.MouseID = {};
angle_features.PtsMeasured = {};
angle_features.values = [];

%% number of scored sleap pts
num_sleap_pts = 22;


%% loop through all of the features
for f_ind = 1:length(feature_table.Name)
    if feature_table.include(f_ind)
        pt1_mID = feature_table.pt1{f_ind}(1);
        vertex_mID = feature_table.vertex{f_ind}(1);
        pt2_mID = feature_table.pt2{f_ind}(1);

        pt1_ID = str2num(feature_table.pt1{f_ind}([2:end]));
        vertex_ID = str2num(feature_table.vertex{f_ind}([2:end]));
        pt2_ID = str2num(feature_table.pt2{f_ind}([2:end]));




        %%collect data pt 1
        if strcmp(pt1_mID,'A')
            pt1_vals_x = data.fp.posdata_reconstructed(pt1_ID,:);
            pt1_vals_y = data.fp.posdata_reconstructed(pt1_ID+num_sleap_pts,:);
        else
            pt1_vals_x = data.ri.posdata_reconstructed(pt1_ID,:);
            pt1_vals_y = data.ri.posdata_reconstructed(pt1_ID+num_sleap_pts,:);
        end

        %%collect data vertex
        if strcmp(vertex_mID,'A')
            vertex_vals_x = data.fp.posdata_reconstructed(vertex_ID,:);
            vertex_vals_y = data.fp.posdata_reconstructed(vertex_ID+num_sleap_pts,:);
        else
            vertex_vals_x = data.ri.posdata_reconstructed(vertex_ID,:);
            vertex_vals_y = data.ri.posdata_reconstructed(vertex_ID+num_sleap_pts,:);
        end

        %%collect data pt 2
        if strcmp(pt2_mID,'A')
            pt2_vals_x = data.fp.posdata_reconstructed(pt2_ID,:);
            pt2_vals_y = data.fp.posdata_reconstructed(pt2_ID+num_sleap_pts,:);
        else
            pt2_vals_x = data.ri.posdata_reconstructed(pt2_ID,:);
            pt2_vals_y = data.ri.posdata_reconstructed(pt2_ID+num_sleap_pts,:);
        end
    
        % Calculate vectors between points
        v1 = [pt1_vals_x',pt1_vals_y'] - [vertex_vals_x',vertex_vals_y'];
        v2 = [pt2_vals_x',pt2_vals_y'] - [vertex_vals_x',vertex_vals_y'];

        % Calculate cos of angles using dot product
        dot_prod = dot(v1, v2,2);
        norm_v1 = sqrt(sum(v1.^2, 2));
        norm_v2 = sqrt(sum(v2.^2, 2));
        temp_feature = dot_prod ./ (norm_v1 .* norm_v2);







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

        angle_features.names{end+1} = feature_table.Name{f_ind};
        angle_features.MouseID{end+1} = [  pt1_mID ,vertex_mID, pt2_mID   ];
        angle_features.PtsMeasured{end+1} = {  num2str(pt1_ID) ,num2str(vertex_mID), num2str(pt2_ID)   };

        angle_features.values(end+1,:) = temp_feature;



        if feature_table.includeDerivitive1(f_ind)
            angle_features.names{end+1} = [feature_table.Name{f_ind},'_derivative_1'];
            angle_features.MouseID{end+1} = [  pt1_mID , pt2_mID   ];
            angle_features.PtsMeasured{end+1} = {  num2str(pt1_ID) , num2str(pt2_ID)   };
            temp_feature_D = diff(temp_feature);
            temp_feature_D(end+1) = temp_feature_D(end);
            angle_features.values(end+1,:) = temp_feature_D;


            if feature_table.includeDerivitive2(f_ind)
                angle_features.names{end+1} = [feature_table.Name{f_ind},'_derivative_2'];
                angle_features.MouseID{end+1} = [  pt1_mID , pt2_mID   ];
                angle_features.PtsMeasured{end+1} = {  num2str(pt1_ID) , num2str(pt2_ID)   };
                temp_feature_DD = diff(temp_feature_D);
                temp_feature_DD(end+1) = temp_feature_DD(end);
                angle_features.values(end+1,:) = temp_feature_DD;
            end
        end
    end
end
return;
