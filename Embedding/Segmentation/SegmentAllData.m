function SegmentAllData(Y_embedded, project)
    
    % SEGMENT Perform watershed segmentation on a 2D embedding
    parameters = project.parameters.segmentation;
    sigma = parameters.sigma;
    n_bins = parameters.n_bins;
    plotStyle = parameters.plotStyle;

    % Compute the 2D histogram
    xmax = max(Y_embedded(:,1));
    xmin = min(Y_embedded(:,1));
    ymax = max(Y_embedded(:,2));
    ymin = min(Y_embedded(:,2));

    [N,XEDGES,YEDGES] = histcounts2(Y_embedded(:,1),Y_embedded(:,2),n_bins, Normalization="pdf",XBinLimits=[xmin,xmax],YBinLimits=[ymin,ymax]);
    xx = linspace(min(XEDGES), max(XEDGES), n_bins);
    yy = linspace(min(YEDGES), max(YEDGES), n_bins);
    Heatmap = imgaussfilt(N, sigma);

    % Perform watershed segmentation
    L = watershed(-Heatmap, 8);
    boundaries = L == 0;

    region_inds = returnRegionInds(Y_embedded,XEDGES,YEDGES, L);

    % Determine global color axis limits
    maxVal = max(Heatmap(:));
    
    % lets just save the figure and not plot it

    figure('Visible', 'off'); 
    % Original PDF
    subplot(3, 1, 1), imagesc(xx, yy, N), title('Original PDF'), axis equal tight;
    caxis([0, maxVal * .8]); % Apply uniform color axis limits
    colormap(plotStyle.Colormap), colorbar;

    % Gaussian Convolved PDF
    subplot(3, 1, 2), imagesc(xx, yy, Heatmap), title(sprintf('Gaussian Convolved PDF, \\sigma = %.1f', sigma)), axis equal tight;
    caxis([0, maxVal * .8]); % Apply uniform color axis limits
    colormap(plotStyle.Colormap), colorbar;

    % Heatmap with Watershed Boundaries
    subplot(3, 1, 3), imagesc(xx, yy, Heatmap), title('Watershed Segmentation'), axis equal tight, hold on;
    contour(xx, yy, boundaries, [0.5, 0.5], 'r', 'LineWidth', plotStyle.LineWidth), hold off;
    caxis([0, maxVal * .8]); % Apply uniform color axis limits
    colormap(plotStyle.Colormap), colorbar;

    fig = gcf;
    
    outdir = fullfile(project.parameters.embedding.mlp.runDir, 'segmentation/');
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    % Save the figure and data 
   
    num_regions = length(unique(region_inds)) - 1;
    saveas(fig, fullfile(outdir, sprintf('segmentation_%d_regions.png', num_regions)));
    segmentation_data.heatmap = Heatmap;
    segmentation_data.L = L;
    segmentation_data.boundaries = boundaries;
    segmentation_data.region_inds = region_inds;
    segmentation_data.XEDGES = XEDGES;
    segmentation_data.YEDGES = YEDGES;
    segmentation_data.parameters = parameters;
    segmentation_data.xmax = xmax;
    segmentation_data.xmin = xmin;
    segmentation_data.ymax = ymax;
    segmentation_data.ymin = ymin;
    segmentation_data.N = N;
    segmentation_data.xx = xx;
    segmentation_data.yy = yy;
    segmentation_data.maxVal = maxVal;
    
    save(fullfile(outdir, 'segmentation_data.mat'), 'segmentation_data');

end
