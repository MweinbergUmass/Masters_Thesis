function [proc_mice_pos_data] = Embedoos_default(proc_mice_pos_data_path, project)
    
    project.addDefaultMLPModel();
    project.load_TSNE_MLP();
    mod = project.module;
    proc_mice_pos_data = load(proc_mice_pos_data_path).processedData;
    
    angle_features = proc_mice_pos_data.features.angle_features.values;
    distance_features = proc_mice_pos_data.features.distance_features.values;
    
    angle_features_names = proc_mice_pos_data.features.angle_features.names;
    distance_features_names = proc_mice_pos_data.features.distance_features.names;

    % mod = py.importlib.import_module('TrainandPredictWithMLP'); 
    % [angle_features, distance_features] = ComputeFeatures(proc_mice_pos_data);
    
    temp_features = [angle_features, distance_features];
    % params.embedding.mlp.default.use_default = false;
    % params.embedding.mlp.default.model_path = fullfile('Data', 'unif_MLP.joblib');
    % params.embedding.mlp.default.ReEmbedInfoPath = fullfile('Data', 'ReEmbedInfo.mat');
    % params.embedding.mlp.default.EmbedoosinfoPath = fullfile('Data', 'Embedoosinfo.mat');   
    ReEmbedInfo = load(project.parameters.embedding.mlp.default.ReEmbedInfoPath);
    
    MinMaxInfo = ReEmbedInfo.MinMaxData;
    
    for i = 1:size(temp_features,2)
            temp_features(:,i) = rescale(temp_features(:,i),-1,1,"InputMax",MinMaxInfo(1,i),"InputMin",MinMaxInfo(2,i));    
    end 
    
    angles_inds = 1:length(angle_features_names);
    dist_inds = 1:length(distance_features_names);
    
    angles = temp_features(:,angles_inds);
    proc_mice_pos_data.features.angle_features.norm_values = angles;

    distances = temp_features(:,angles_inds(end)+dist_inds);
    proc_mice_pos_data.features.distance_features.norm_values = distances;
    
    projectedData_angles = ProjectNewData(angles, ReEmbedInfo.mu_angles, ReEmbedInfo.coeffs_angles, ReEmbedInfo.NumComps_angles);
    projectedData_distances = ProjectNewData(distances, ReEmbedInfo.mu_dists, ReEmbedInfo.coeffs_distances, ReEmbedInfo.NumComps_distances);
    
    CWTMat_Angles = findWavelets(projectedData_angles, project);
    CWTMat_Angles = CWTMat_Angles ./ sum(CWTMat_Angles,2);
    
    proc_mice_pos_data.wavelets.angles.amps = CWTMat_Angles;
    proc_mice_pos_data.wavelets.angles.Frame_amps = sum(CWTMat_Angles,2);

    CWTMat_Distances = findWavelets(projectedData_distances, project);
    CWTMat_Distances = CWTMat_Distances ./ sum(CWTMat_Distances,2);

    proc_mice_pos_data.wavelets.distances.amps = CWTMat_Angles;
    proc_mice_pos_data.wavelets.distances.Frame_amps = sum(CWTMat_Angles,2);
    
    X_data_all = [angles,distances,CWTMat_Distances,CWTMat_Angles];
    Y_embedded = double(mod.runModel_V2(X_data_all,project.parameters.embedding.mlp.default.model_path));
    
    load(project.parameters.embedding.mlp.default.EmbedoosinfoPath, 'XBinLimits', 'YBinLimits', 'maxVal', 'XEDGES', 'YEDGES', 'boundaries', 'L')
    [Heatmap,fig] = EmbedExperiment(Y_embedded,XBinLimits,YBinLimits,maxVal,XEDGES, YEDGES, boundaries, ['New Experiment']);
    region_inds = return_region_inds(Y_embedded,XEDGES,YEDGES, L);
    
    proc_mice_pos_data.Motmap_default.Zvals = Y_embedded;
    proc_mice_pos_data.Motmap_default.region_inds = region_inds;
    proc_mice_pos_data.Motmap_default.L = L;
    proc_mice_pos_data.Motmap_default.boundaries = boundaries;
    proc_mice_pos_data.Motmap_default.Heatmap = Heatmap;
    proc_mice_pos_data.Motmap_default.WatershedFig = fig;
    
    project.updateProcessingStatus(proc_mice_pos_data_path, 'embedded', 1, proc_mice_pos_data);
    project.saveProject();

end
function [Heatmap,fig] = EmbedExperiment(Y_embedded,XBinLimits,YBinLimits,maxVal,XEDGES, YEDGES, boundaries,titlestr, varargin)

    p = inputParser;
    addRequired(p, 'Y_embedded', @(x) isnumeric(x) && size(x, 2) >= 2);
    addParameter(p, 'Sigma', 1, @isnumeric);
    addParameter(p, 'NBins', 50, @isnumeric);
    addParameter(p, 'PlotStyle', struct('Colormap', 'jet', 'LineWidth', 1), @isstruct);
    parse(p, Y_embedded, varargin{:});

    sigma = p.Results.Sigma;
    n_bins = p.Results.NBins;
    plotStyle = p.Results.PlotStyle;

    [N,~,~] = histcounts2(Y_embedded(:,1),Y_embedded(:,2),n_bins, Normalization="pdf",XBinLimits=XBinLimits,YBinLimits=YBinLimits);
    xx = linspace(min(XEDGES), max(XEDGES), n_bins);
    yy = linspace(min(YEDGES), max(YEDGES), n_bins);
    Heatmap = imgaussfilt(N, sigma);


    % Plotting if enabled
    figure('Visible', 'off'); 
    imagesc(xx, yy, Heatmap), title(titlestr), axis equal tight, hold on;
    contour(xx, yy, boundaries, [0.5, 0.5], 'r', 'LineWidth', plotStyle.LineWidth), hold off;
    caxis([0, maxVal]); % Apply uniform color axis limits
    colormap(plotStyle.Colormap), colorbar;
    fig = gcf;
    
end
function projectedData = ProjectNewData(normalizedNewData, mu,coeffs, numcomps)
% Project normalized out-of-sample data onto the PCA space
projectedData = (normalizedNewData-mu) * coeffs(:, 1:numcomps);
end
