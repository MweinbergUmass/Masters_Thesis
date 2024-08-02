function parameters= setparams(varargin)
%% Sets up basic parameters. Is called as: parameters= setparameters(varargin) where varargin is a struct with user defined parameters for the autoencoder model
% Inputs: struct with user defined parameters for the autoencoder model
% example: parameters= setparameters(struct('autoenc', struct('model_parameters', struct('sequence_length', 15, 'input_shape', [15, 44], 'bottleneck_size', 22))))
% Outputs: struct with all parameters needed for the autoencoder model

%% Set up basic parameters
parameters= struct();
parameters.autoenc.reference_frame_path = strcat('Data', filesep, 'Static_AutoData', filesep, 'reference_frame');
parameters.autoenc.features_means_path = strcat('Data', filesep, 'Static_AutoData', filesep, 'features_means');
parameters.sleaplabelspath = strcat('Data', filesep, 'Labels');
parameters.sleappredspath = strcat('Data', filesep, 'Preds');
parameters.autoenc.model = 'TCONV';
parameters.numProcessors = 8;
parameters.closeMatPool = false;

%% Set up default model parameters to match Python Autoencoder class
parameters.autoenc.model_parameters= struct(...
    'sequence_length', 15, ...
    'input_shape', [15, 44], ...
    'bottleneck_size', int32(22), ...
    'activation', 'selu', ...
    'conv_units', int32(256), ...
    'kernel_size', int32(3), ...
    'stride_size', int32(1), ...
    'batch_size', int32(512), ...
    'dropout_rate', 0.1, ...
    'val_split', 0.2, ...
    'epochs', int32(100), ...
    'ER_Patience', int32(25), ...
    'LR_patience', int32(10) ...
);

%% Set model path based on model type
if strcmpi(parameters.autoenc.model, 'TCONV')
    parameters.autoenc.path = strcat('Models', filesep, 'conv_autoencoder_model.h5');
elseif strcmpi(parameters.autoenc.model, 'MLP')
    parameters.autoenc.path = strcat('Models', filesep, 'autoencoder_model.h5');
    % Adjust parameters for MLP if needed
    parameters.autoenc.model_parameters.input_shape = [1, 360];
else
    error('Need to pick either TCONV or MLP for the autoencoder model.');
end

%% parametersfor Feature Extraction
parameters.features.angles_xlsx_path = strcat('Data', filesep, 'Features_XLSX', filesep, 'angle_features.xlsx');
parameters.features.distances_xlsx_Path = strcat('Data', filesep, 'Features_XLSX', filesep, 'distance_features.xlsx');

%% Wavelet parameters
parameters.wavelets.numPeriods = 25;
parameters.wavelets.omega0 = 5;
parameters.wavelets.samplingFreq = 30;
parameters.wavelets.minF = 0.5;
parameters.wavelets.maxF = 15;

%% Training Embedding Parameters
parameters.embedding.TrainingSetSize = 12000;
parameters.embedding.numNeighbors = 10;
parameters.embedding.numComponents = int32(2);
parameters.embedding.perplexity_scale = 100;
% verbose=2,n_iter=1000
parameters.embedding.verbose = int32(2);
parameters.embedding.n_iter = int32(1000);

%trainModel(X_tr, y_tr, X_te, y_te, savename,verbose=True,early_stopping=True, validation_fraction=0.1,batch_size=512,PlotsOn=True):


parameters.embedding.mlp.early_stopping = true;
parameters.embedding.mlp.validation_fraction = 0.1;
parameters.embedding.mlp.batch_size = int32(512);
parameters.embedding.mlp.verbose = true;
parameters.embedding.mlp.epochs = int32(200);
parameters.embedding.mlp.outputdir = 'model_output';
parameters.embedding.mlp.model_name = 'model.joblib';

parameters.embedding.mlp.default.use_default = true;
parameters.embedding.mlp.default.model_path = fullfile('Data','Default_MLP', 'converted_model.joblib');
parameters.embedding.mlp.default.ReEmbedInfoPath = fullfile('Data','Default_MLP', 'ReEmbedInfo.mat');
parameters.embedding.mlp.default.EmbedoosinfoPath = fullfile('Data','Default_MLP', 'Embedoosinfo.mat');


% add parametersfor segmentation
parameters.segmentation.sigma = 1;
parameters.segmentation.n_bins = 50;
parameters.segmentation.plotResults = false;
parameters.segmentation.plotStyle.Colormap = 'jet';
parameters.segmentation.plotStyle.LineWidth = 2;


%% Override default parameters with user-specified values
if ~isempty(varargin)
    user_parameters= varargin{1};
    parameters= recursiveOverride(parameters, user_parameters);
end

end

function parameters= recursiveOverride(parameters, user_parameters)
% Recursively override default parameters with user-specified values
fields = fieldnames(user_parameters);
for i = 1:numel(fields)
    field = fields{i};
    if isfield(parameters, field)
        if isstruct(parameters.(field)) && isstruct(user_parameters.(field))
            % Recursively override nested struct
            parameters.(field) = recursiveOverride(parameters.(field), user_parameters.(field));
        else
            % Override value, ensuring correct data type
            if isnumeric(parameters.(field))
                parameters.(field) = cast(user_parameters.(field), class(parameters.(field)));
            else
                parameters.(field) = user_parameters.(field);
            end
        end
    else
        % Add new field if it doesn't exist in parameters
        parameters.(field) = user_parameters.(field);
    end
end
end