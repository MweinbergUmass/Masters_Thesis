function params = setparams(varargin)
    %% Sets up basic parameters. Is called as: params = setparams(varargin) where varagin is a struct with user defined parameters for the autoencoder model
    % Inputs: struct with user defined parameters for the autoencoder model
    % example: params = setparams(struct('sequence_length', 15, 'input_shape', [15, 44], 'bottleneck_size', 22))
    % Outputs: struct with all parameters needed for the autoencoder model 
    %%
    % Set up basic parameters
    params.autoenc.reference_frame_path = 'Data/reference_frame'; %% Lets add filesep here
    params.autoenc.features_means_path = 'Data/features_means';
    params.sleaplabelspath = 'Data/Labels';
    params.sleappredspath = 'Data/Preds';
    params.autoenc.model = 'TCONV';

    % Set up default model parameters to match Python Autoencoder class
    default_model_params = struct(... 
        'sequence_length', 15, ...
        'input_shape', [15, 44], ... % Ensure these are integers
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

    % Override default model parameters with user-specified values
    if ~isempty(varargin)
        user_model_params = varargin{1};
        default_model_params = overrideParams(default_model_params, user_model_params);
    end

    % Set model parameters
    params.autoenc.model_params = default_model_params;

    % Set model path based on model type
    if strcmpi(params.autoenc.model, 'TCONV')
        params.autoenc.path = 'Models/conv_autoencoder_model.h5';
    elseif strcmpi(params.autoenc.model, 'MLP')
        params.autoenc.path = 'Models/autoencoder_model.h5';
        % Adjust parameters for MLP if needed
        params.autoenc.model_params.input_shape = [1, 360]; % Ensure these are integers
    else
        error('Need to pick either TCONV or MLP for the autoencoder model.');
    end
end

function overriddenParams = overrideParams(defaultParams, userParams)
    % Override default parameters with user-specified values
    overriddenParams = defaultParams;
    fields = fieldnames(userParams);
    for i = 1:numel(fields)
        field = fields{i};
        if isfield(defaultParams, field)
            if isnumeric(defaultParams.(field))
                overriddenParams.(field) = cast(userParams.(field), class(defaultParams.(field)));
            else
                overriddenParams.(field) = userParams.(field);
            end
        else
            error('Invalid parameter name: %s', field);
        end
    end
end
