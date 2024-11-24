function segment(proc_mice_pos_data_path,project)
    segmentation_data = project.parameters.segmentation.segmentation_data;
    proc_mice_pos_data = load(proc_mice_pos_data_path).processedData;
    Y_embedded = proc_mice_pos_data.Motmap.Zvals;   
    parameters = segmentation_data.parameters;
    sigma = parameters.sigma;
    n_bins = parameters.n_bins;
    plotStyle = parameters.plotStyle;

    XEDGES = segmentation_data.XEDGES;
    YEDGES = segmentation_data.YEDGES;
    xx = segmentation_data.xx;
    yy = segmentation_data.yy;
    L = segmentation_data.L;
    boundaries = L == 0;
    maxVal = segmentation_data.maxVal;
    xmin = segmentation_data.xmin;
    xmax = segmentation_data.xmax;
    ymax = segmentation_data.ymax;
    ymin = segmentation_data.ymin;

    [N,~,~] = histcounts2(Y_embedded(:,1),Y_embedded(:,2),n_bins, Normalization="pdf",XBinLimits=[xmin,xmax],YBinLimits=[ymin,ymax]);

    Heatmap = imgaussfilt(N, sigma);

    % Plotting if enabled
    figure('Visible', 'off'); 
    titlestr = sprintf('Watershed Segmentation'); 
    imagesc(xx, yy, Heatmap), title(titlestr), axis equal tight, hold on;
    contour(xx, yy, boundaries, [0.5, 0.5], 'r', 'LineWidth', plotStyle.LineWidth), hold off;
    caxis([0, maxVal]); % Apply uniform color axis limits
    colormap(plotStyle.Colormap), colorbar;
    fig = gcf;

    
    
    region_inds = returnRegionInds(Y_embedded,XEDGES,YEDGES, L);
    proc_mice_pos_data.Motmap.segmentation_data = segmentation_data;
    proc_mice_pos_data.Motmap.N = N;
    proc_mice_pos_data.Motmap.Heatmap = Heatmap;
    proc_mice_pos_data.Motmap.region_inds = region_inds;
    proc_mice_pos_data.Motmap.WatershedFig = fig;
    project.updateProcessingStatus(proc_mice_pos_data_path, 'segmented', true, proc_mice_pos_data);
    project.saveProject();
end
