function ReconsAnimation(proc_mice_pos_data)
recons = proc_mice_pos_data.fp.reconstructedData;
orig = proc_mice_pos_data.fp.data_for_encoder';

% Extracting x and y coordinates for the reconstructed data
x_r = recons(:,1:22);
y_r = recons(:,23:end);

% Extracting x and y coordinates for the original data
x_o = orig(:,1:22);
y_o = orig(:,23:end);

output_inc = 1;
figure;

for i=1:output_inc:length(recons)
    cla; hold on;
    
  


    % Plotting a reference line
    plot([-200, 200], [0, 0], 'k')
    

    %%%JFB edits
x_both = [x_r(i,:);x_o(i,:);nan(size(x_r(i,:)))];
x_both = reshape(x_both,1,prod(size(x_both)));
y_both = [y_r(i,:);y_o(i,:);nan(size(y_r(i,:)))];
y_both = reshape(y_both,1,prod(size(y_both)));

h_orig = plot(x_both,y_both,'ko-');
set(h_orig,'MarkerFaceColor','k')
h_recons=plot(x_r(i,:),y_r(i,:),'ro');
set(h_recons,'MarkerFaceColor','r')

%%%end JFB edits




    % Add the legend inside the loop
    legend([h_recons, h_orig], {'Reconstructed', 'Original'});
    
    axis equal
    set(gca, 'xlim', [-2, 2], 'ylim', [-2, 2])
    drawnow
    % pause()
end
