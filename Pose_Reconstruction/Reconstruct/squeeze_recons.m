function new_data = squeeze_recons(reconstruction)
new_data = zeros(size(reconstruction,1),size(reconstruction,3));
new_data(1,:) = squeeze(reconstruction(1,1,:));
for i = 2:length(reconstruction)
    new_data(i,:) = squeeze(reconstruction(i,1,:));
end 
end 