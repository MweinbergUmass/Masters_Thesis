function TrainMLP(project)
   % okay we have already created the y_embedded
   % we need to perform the train test split on the y_embedded and the features
    Embeddingdir = fullfile(project.dataDir, 'EmbeddingData/');
    if ~exist(Embeddingdir, 'dir')
        error('Embedding data does not exist. Please run TrainInitEmbedding first.');
    end
    features_all = load(fullfile(Embeddingdir, 'features_all.mat'), 'features_all').features_all;
    Y_embedded = load(fullfile(Embeddingdir, 'Y_embedded_training.mat'), 'Y_embedded').Y_embedded;
    % now we need to split the data into a train test split and train the MLP using a cv object
    % we will use the cv object to perform the train test split
    cv = cvpartition(size(Y_embedded, 1), 'HoldOut', 0.2);
    trainindices = cv.training;
    testindices = cv.test;
    % now we need to split the data
    Y_train = Y_embedded(trainindices, :);
    Y_test = Y_embedded(testindices, :);
    features_train = features_all(trainindices, :);
    features_test = features_all(testindices, :);
    

    % Now we need to train the MLP
    project.load_TSNE_MLP();
    parameters = project.parameters.embedding.mlp;

    mlpOutputDir = fullfile(Embeddingdir, parameters.outputdir);
    if ~exist(mlpOutputDir, 'dir')
        mkdir(mlpOutputDir);
    end
    
    % Call the Python function with the output directory
    pythonOutput = project.module.trainModel(features_train, Y_train, features_test, Y_test, ...
        parameters.model_name, parameters.verbose, parameters.early_stopping, ...
        parameters.validation_fraction, parameters.batch_size, parameters.epochs, ...
        mlpOutputDir);

   
    runDir = char(pythonOutput{'run_dir'});
    metadatapath = fullfile(runDir, 'metadata.json');
    metadata = jsondecode(fileread(metadatapath));

    % Load the MATLAB data
    plotData = load(fullfile(runDir, 'plot_data.mat'));

    % Plot training loss
    % lets not actually display the plot here

    fig = figure('Visible', 'off');
    plot(plotData.epochs, plotData.loss_curve);
    title('Model Loss during Training');
    xlabel('Epochs');
    ylabel('Loss');
    saveas(fig, fullfile(runDir, 'training_loss.png'));
    close(fig);
    
    % Create and save predictions vs ground truth plot without displaying
    fig = figure('Visible', 'off');
    scatter(plotData.y_true, plotData.y_pred);
    hold on;
    plot([min(plotData.y_true), max(plotData.y_true)], [min(plotData.y_true), max(plotData.y_true)], 'r--');
    title(sprintf('Predictions vs True Values (R^2 = %.2f)', plotData.r_squared));
    xlabel('True Values');
    ylabel('Predictions');
    saveas(fig, fullfile(runDir, 'PredsVSgt.png'));
    close(fig);

    % Now we need to couple all this with the project
    project.addMLPModel(runDir, metadata); 
    [~, date, ~] = fileparts(runDir);
    project.setMLPModel(date);
    project.saveProject();

end 
