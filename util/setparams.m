function params = setparams(varargin)
%% Sets up basic parameters. Is called as: params = setparams(varargin) where varargin is a struct with user defined parameters for the autoencoder model
% Inputs: struct with user defined parameters for the autoencoder model
% example: params = setparams(struct('autoenc', struct('model_params', struct('sequence_length', 15, 'input_shape', [15, 44], 'bottleneck_size', 22))))
% Outputs: struct with all parameters needed for the autoencoder model

%% Set up basic parameters
params = struct();
params.autoenc.reference_frame_path = strcat('Data', filesep, 'Static_AutoData', filesep, 'reference_frame');
params.autoenc.features_means_path = strcat('Data', filesep, 'Static_AutoData', filesep, 'features_means');
params.sleaplabelspath = strcat('Data', filesep, 'Labels');
params.sleappredspath = strcat('Data', filesep, 'Preds');
params.autoenc.model = 'TCONV';
params.numProcessors = 8;
params.closeMatPool = false;

%% Set up default model parameters to match Python Autoencoder class
params.autoenc.model_params = struct(...
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
if strcmpi(params.autoenc.model, 'TCONV')
    params.autoenc.path = strcat('Models', filesep, 'conv_autoencoder_model.h5');
elseif strcmpi(params.autoenc.model, 'MLP')
    params.autoenc.path = strcat('Models', filesep, 'autoencoder_model.h5');
    % Adjust parameters for MLP if needed
    params.autoenc.model_params.input_shape = [1, 360];
else
    error('Need to pick either TCONV or MLP for the autoencoder model.');
end

%% Params for Feature Extraction
params.features.angles_xlsx_path = strcat('Data', filesep, 'Features_XLSX', filesep, 'angle_features.xlsx');
params.features.distances_xlsx_Path = strcat('Data', filesep, 'Features_XLSX', filesep, 'distance_features.xlsx');

%% Wavelet parameters
params.wavelets.numPeriods = 25;
params.wavelets.omega0 = 5;
params.wavelets.samplingFreq = 30;
params.wavelets.minF = 0.5;
params.wavelets.maxF = 15;

%% Training Embedding Parameters
params.embedding.TrainingSetSize = 12000;
params.embedding.numNeighbors = 10;


%% Override default parameters with user-specified values
if ~isempty(varargin)
    user_params = varargin{1};
    params = recursiveOverride(params, user_params);
end

end

function params = recursiveOverride(params, user_params)
% Recursively override default parameters with user-specified values
fields = fieldnames(user_params);
for i = 1:numel(fields)
    field = fields{i};
    if isfield(params, field)
        if isstruct(params.(field)) && isstruct(user_params.(field))
            % Recursively override nested struct
            params.(field) = recursiveOverride(params.(field), user_params.(field));
        else
            % Override value, ensuring correct data type
            if isnumeric(params.(field))
                params.(field) = cast(user_params.(field), class(params.(field)));
            else
                params.(field) = user_params.(field);
            end
        end
    else
        % Add new field if it doesn't exist in params
        params.(field) = user_params.(field);
    end
end
end