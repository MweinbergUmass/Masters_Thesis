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
    % now we need to train the MLP
    project.load_TSNE_MLP();
    parameters = project.parameters.embedding.mlp;
    savename = parameters.savename;
    savename = fullfile(Embeddingdir, savename);
    %trainModel(X_tr, y_tr, X_te, y_te, savename,verbose=True,early_stopping=True, validation_fraction=0.1,batch_size=512,PlotsOn=True):
    project.module.trainModel(features_train, Y_train, features_test, Y_test, parameters.savename, parameters.verbose, parameters.early_stopping, parameters.validation_fraction, parameters.batch_size, parameters.PlotsOn);



end