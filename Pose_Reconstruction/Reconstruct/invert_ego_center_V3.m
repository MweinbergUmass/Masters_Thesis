function posdata_reconstructed = invert_ego_center_V3(posdata_centered , scale_factor, ref_centroid , frame_centroid, frame_rotation )

%% many of the following steps should probably be vectorized

mouse.x_cent = posdata_centered([1:22],:); %%/280;
mouse.y_cent = posdata_centered([1:22]+22,:);
mouse.x_reconstruct = nan(size( mouse.x_cent));
mouse.y_reconstruct = nan(size( mouse.y_cent));

for frame_i = 1:size(posdata_centered,2)

%% step 1: move the frame data such that the centroid is at the origin
%% to do this, subtract the reference centroid
mouse.x_reconstruct(:,frame_i) = mouse.x_cent(:,frame_i) - ref_centroid(1,frame_i);
mouse.y_reconstruct(:,frame_i) = mouse.y_cent(:,frame_i) - ref_centroid(2,frame_i);


%% step 2: invert the rotation
if isfinite(frame_rotation(frame_i))
    angleRadians = deg2rad(360-frame_rotation(frame_i));
    rotationMatrix = [cos(angleRadians), -sin(angleRadians); sin(angleRadians), cos(angleRadians)];
    transposedPoints = [mouse.x_reconstruct(:,frame_i),mouse.y_reconstruct(:,frame_i)]';
    rotatedPoints = (rotationMatrix * transposedPoints)';
    mouse.x_reconstruct(:,frame_i)= rotatedPoints(:,1);
    mouse.y_reconstruct(:,frame_i)= rotatedPoints(:,2);
end
%%


%% step 3: adjust position by the frame centroid
mouse.x_reconstruct(:,frame_i) = mouse.x_reconstruct(:,frame_i) + frame_centroid(1,frame_i);
mouse.y_reconstruct(:,frame_i) = mouse.y_reconstruct(:,frame_i) + frame_centroid(2,frame_i);

end %% end frame_i

%% Step 4: inverse the scale factor
posdata_reconstructed = [mouse.x_reconstruct ; mouse.y_reconstruct]/ scale_factor;



return;