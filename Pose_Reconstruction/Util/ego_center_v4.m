function out = ego_center_v4(refdata, posdata, varargin)
    do_size_norm = 1;
    do_ego_center = 1;
    good_pts_thresh = 6;

    outlier_thresh = 10; %%std deviations from mean to exclude points as outliers.


    %% load and reformat reference data
    ref.x = refdata([1:22]);
    ref.y = refdata([1:22]+22);
    out.refdata = [ref.x;ref.y];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%



    %% load and reformat data from Tracking Software
    mouse.x = posdata([1:22],:); %%/280;
    mouse.y = posdata([1:22]+22,:);
    mouse.x_rot = nan(size( mouse.x));
    mouse.y_rot = nan(size( mouse.y));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if do_size_norm %% set the average area of the mouse to ~1 by dividing by the sqrt of the area
        a = sqrt(diff(mouse.x([2,22],:)).^2+diff(mouse.y([2,22],:)).^2)/2;  %% semi-major axis of ellipse approximation of mouse
        b = sqrt(diff(mouse.x([12,18],:)).^2+diff(mouse.y([12,18],:)).^2)/2;%% semi-minor axis of ellipse approximation of mouse

        ellipse_areas = a .* b * pi; %% calculate ellipse approximation at each frame
        scale_factor = 1 / sqrt(trimmean(ellipse_areas,20)); %% this scaling factor should bring average area to 1

        mouse.x = mouse.x * scale_factor; %% scale the x data
        mouse.y = mouse.y * scale_factor; %% scale the y data
    end
    
    if do_ego_center
        centroid.ref = [];
        centroid.frame = [];
        frame_rotation = [];
        number_of_pts_found = [];

        for frame_i=1:size(mouse.x,2) %% cycle through all frames
            good_inds = find(isfinite(mouse.x(:,frame_i)));
            number_of_pts_found(frame_i) = length(good_inds);

            centroid.ref(1,frame_i) = mean(ref.x(good_inds));
            centroid.ref(2,frame_i) = mean(ref.y(good_inds));
            centroid.frame(1,frame_i) = mean(mouse.x(good_inds,frame_i));
            centroid.frame(2,frame_i) = mean(mouse.y(good_inds,frame_i));

            mouse.x(:,frame_i) = mouse.x(:,frame_i)-centroid.frame(1,frame_i); %% move mouse to origin
            mouse.y(:,frame_i) = mouse.y(:,frame_i)-centroid.frame(2,frame_i); %% move mouse to origin

            temp_ref.x = ref.x-centroid.ref(1,frame_i); %% move ref to origin
            temp_ref.y = ref.y-centroid.ref(2,frame_i); %% move ref to origin
            
            temp_angle = [];
            temp_dist = [];
            temp_offsets = [];
            if length(good_inds)>=good_pts_thresh
            for marker_i=1:length(good_inds)
                point2 = [mouse.x(marker_i,frame_i),mouse.y(marker_i,frame_i)];
                point1 = [temp_ref.x(marker_i),temp_ref.y(marker_i)];
                
                temp_angle(marker_i) = calculateAngleWithOrigin_V2(point1, [0,0], point2);
                temp_dist(marker_i) = sqrt(sum(point1.^2));
                temp_offsets(1,marker_i) = temp_dist(marker_i) * cosd(temp_angle(marker_i));
                temp_offsets(2,marker_i) = temp_dist(marker_i) * sind(temp_angle(marker_i));

                %% make temp_offsets a unit vector
                temp_offsets(:,marker_i) = temp_offsets(:,marker_i) / sqrt(sum(temp_offsets(:,marker_i).^2)); 
             end
% % %                 rotation_target_temp = nanmean(temp_offsets,2);


% %                 find trimmean of angles with respect to distance from the centroid
                    perc_angle_trim = 20;
                    markers2remove = floor(length(good_inds)*perc_angle_trim/100);
                    
                    temp_offset_centroid = nanmean(temp_offsets,2);
                    temp_offset_dist = sqrt((temp_offsets(1,:)- temp_offset_centroid(1)).^2 + (temp_offsets(2,:)- temp_offset_centroid(2)).^2);
                    if markers2remove>1
                        [~,I] = sort(temp_offset_dist);
                        remove_inds = I([end-markers2remove+1:end]);
                        temp_offsets(:,remove_inds) = nan;
                    end


                rotation_target = trimmean(temp_offsets,20,'round',2);
                frame_rotation(frame_i) = calculateAngleWithOrigin_V2(rotation_target, [0,0], [1,0]);
            else
                rotation_target = [];
                frame_rotation(frame_i) = nan; %% no way to calculate the rotation-->toss data
            end





if isfinite(frame_rotation(frame_i))
    angleRadians = deg2rad(frame_rotation(frame_i));
    rotationMatrix = [cos(angleRadians), -sin(angleRadians); sin(angleRadians), cos(angleRadians)];
    transposedPoints = [mouse.x(:,frame_i),mouse.y(:,frame_i)]';
    
    rotatedPoints = (rotationMatrix * transposedPoints)';
    mouse.x_rot(:,frame_i)= rotatedPoints(:,1);
    mouse.y_rot(:,frame_i)= rotatedPoints(:,2);
end

%% Now recenter by taking away the reference centroid
mouse.x_rot(:,frame_i) = mouse.x_rot(:,frame_i)+centroid.ref(1,frame_i); %% move ref to origin
mouse.y_rot(:,frame_i) = mouse.y_rot(:,frame_i)+centroid.ref(2,frame_i); %% move ref to origin

        end %% end frame i
    end %% end do_ego_center


%% create the output for the function
out.number_of_pts_found = number_of_pts_found;
out.scale_factor        = scale_factor;
out.centroid.ref        = centroid.ref;
out.centroid.frame      = centroid.frame;
out.frame_rotation      = frame_rotation;
out.posdata_centered    = [mouse.x_rot;mouse.y_rot];


if outlier_thresh>0
    num_pts = size(mouse.x_rot,1);
    for i=1:num_pts
        temp_centroid = [nanmean(mouse.x_rot(i,:)) , nanmean(mouse.y_rot(i,:))];
        temp_dist = sqrt((mouse.x_rot(i,:) - temp_centroid(1)).^2+(mouse.y_rot(i,:) - temp_centroid(2)).^2);
        
        temp_std = nanstd(temp_dist);
        temp_mean = nanmean(temp_dist);
        min_cut = temp_mean - outlier_thresh*temp_std;
        max_cut = temp_mean + outlier_thresh*temp_std;
        
        del_inds = find(or( temp_dist<min_cut  ,  temp_dist>max_cut));
        mouse.x_rot(i,del_inds) = nan;
        mouse.y_rot(i,del_inds) = nan;
    end
end

out.posdata_centered_qc    = [mouse.x_rot;mouse.y_rot];

return;
