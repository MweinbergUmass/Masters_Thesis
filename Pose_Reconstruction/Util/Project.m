classdef Project < handle
    properties
        name
        creationDate
        baseDir
        dataDir
        parameterFile
        parameters
        fileRegistry
        log
        trainDataDir 
        filePatterns
        modelsDir
        module
    end
    
    methods
        function obj = Project(projectName, baseDir, params)
            % Constructor
            if nargin >= 2
                obj.name = projectName;
                obj.creationDate = datetime('now');
                obj.baseDir = baseDir;
                obj.dataDir = fullfile(baseDir, 'data');
                obj.fileRegistry = struct('original', {}, 'processed', {});
                obj.log = {};
                obj.filePatterns = struct(...
                'preds', '*.analysis.h5', ...
                'labels', '*.analysis.h5' ...
                );
                obj.loadModule();
                
                % Create project and data directories if they don't exist
                if ~exist(obj.baseDir, 'dir')
                    mkdir(obj.baseDir);
                end
                if ~exist(obj.dataDir, 'dir')
                    mkdir(obj.dataDir);
                end
                obj.modelsDir = fullfile(baseDir, 'Models');
                if ~exist(obj.modelsDir, 'dir')
                    mkdir(obj.modelsDir);
                end
                
                % Handle parameters
                if nargin < 3 || isempty(params)
                    obj.parameters = setparams(); %need to somehow implement this method?
                else
                    obj.parameters = params;
                end
                
                % Save parameters
                obj.parameterFile = fullfile(obj.baseDir, 'project_params.mat');
                save(obj.parameterFile, 'params');
                
                % Save initial project file
                obj.saveProject();
                disp(['Created new project: ' projectName]);
            elseif nargin ~= 0
                error('Project constructor requires either 0, 2, or 3 arguments');
            end
        end
        function loadModule(obj)
            % Get the current directory
            currentDir = pwd;
            
            % Construct the path to the Util directory
            utilDir = fullfile(currentDir, 'Util');
            
            % Add the Util directory to Python's sys.path
            if count(py.sys.path, utilDir) == 0
                insert(py.sys.path, int32(0), utilDir);
            end
            
            % Now import the module
            try
                obj.module = py.importlib.import_module('TC_Auto');
                disp('Successfully imported TC_Auto module');
            catch ME
                error('Failed to import TC_Auto module: %s', ME.message);
            end
        end
        
        function saveProject(obj)
            % Save the project structure
            if isprop(obj,'module') && ~isempty(obj.module);
                obj.module = [];
            end
            
            % Save the project structure
            projectFile = fullfile(obj.baseDir, [obj.name '_project.mat']);
            save(projectFile, 'obj');
            disp(['Saved project: ' obj.name]);
            
            % Restore the module if it was removed
            if ~(isprop(obj,'module') && ~isempty(obj.module));
                obj.module = py.importlib.import_module('TC_Auto');
            end
        end
        
        function [processedFilePath] = addProcessedFile(obj, originalFilePath, processedData, processingType)
            % Generate a unique filename for the processed data
            [~, NAME, ~] = fileparts(originalFilePath);
            processedFilePath = fullfile(obj.dataDir, [NAME '_' processingType '.mat']);
            
            % Save the processed data
            save(processedFilePath, 'processedData');
            
            % Check if the original file is already in the registry
            originalFileIndex = find(strcmp({obj.fileRegistry.original}, originalFilePath), 1);
            
            if isempty(originalFileIndex)
                % If not, add a new entry
                newEntry = struct('original', originalFilePath, 'processed', struct());
                newEntry.processed.(processingType) = processedFilePath;
                obj.fileRegistry(end+1) = newEntry;
            else
                % If yes, add or update the processed file for this processing type
                obj.fileRegistry(originalFileIndex).processed.(processingType) = processedFilePath;
            end
            
            % Add log entry
            logEntry = sprintf('Processed file: %s -> %s (Type: %s)', originalFilePath, processedFilePath, processingType);
            obj.log{end+1} = sprintf('%s: %s', char(datetime('now')), logEntry);
            
            % Save updated project
            obj.saveProject();
        end
        
        function processedFilePath = getProcessedFile(obj, originalFilePath, processingType)
            % Find the original file1 in the registry
            originalFileIndex = find(strcmp({obj.fileRegistry.original}, originalFilePath), 1);
            
            if isempty(originalFileIndex)
                processedFilePath = '';
                return;
            end
            
            % Check if the processing type exists for this file
            if isfield(obj.fileRegistry(originalFileIndex).processed, processingType)
                processedFilePath = obj.fileRegistry(originalFileIndex).processed.(processingType);
            else
                processedFilePath = '';
            end
        end
        
        function displayProjectSummary(obj)
            disp(['Project Name: ' obj.name]);
            disp(['Creation Date: ' char(obj.creationDate)]);
            disp(['Base Directory: ' obj.baseDir]);
            disp(['Data Directory: ' obj.dataDir]);
            disp(['Parameter File: ' obj.parameterFile]);
            disp(['Number of Original Files: ' num2str(length(obj.fileRegistry))]);
            disp('Processed Files:');
            for i = 1:length(obj.fileRegistry)
                disp(['  Original: ' obj.fileRegistry(i).original]);
                processingTypes = fieldnames(obj.fileRegistry(i).processed);
                for j = 1:length(processingTypes)
                    disp(['    - ' processingTypes{j} ': ' obj.fileRegistry(i).processed.(processingTypes{j})]);
                end
            end
            disp('Recent Log Entries:');
            numEntries = min(5, length(obj.log));
            for i = 1:numEntries
                disp(obj.log{end-numEntries+i});
            end
        end
        
        function updateParameters(obj, newParams)
        % Update project parameters
        obj.parameters = obj.mergeStructs(obj.parameters, newParams);
        
        % Save updated parameters
        save(obj.parameterFile, 'newParams');
        
        % Log the update
        obj.log{end+1} = sprintf('%s: Updated project parameters', char(datetime('now')));
        
        % Save the entire project
        obj.saveProject();
        end
    
    function mergedStruct = mergeStructs(obj, oldStruct, newStruct)
        % Helper function to recursively merge structs
        mergedStruct = oldStruct;
        fields = fieldnames(newStruct);
        
        for i = 1:length(fields)
            if isfield(oldStruct, fields{i})
                if isstruct(oldStruct.(fields{i})) && isstruct(newStruct.(fields{i}))
                    % Recursively merge nested structs
                    mergedStruct.(fields{i}) = obj.mergeStructs(oldStruct.(fields{i}), newStruct.(fields{i}));
                else
                    % Update the value
                    mergedStruct.(fields{i}) = newStruct.(fields{i});
                end
            else
                % Add new field
                mergedStruct.(fields{i}) = newStruct.(fields{i});
            end
        end
    end
            
     function prepareTrainingData(obj, mainDataDir)
            % Set up training data directory
            obj.trainDataDir = mainDataDir;
            obj.parameters.sleappredspath = fullfile(mainDataDir, 'Preds');
            obj.parameters.sleaplabelspath = fullfile(mainDataDir, 'Labels');
            
            % Find and match files
            predsFiles = obj.findFiles('preds');
            labelsFiles = obj.findFiles('labels');
            [matchedPreds, matchedLabels] = obj.matchFiles(predsFiles, labelsFiles);
            
            % Store matched files in parameters
            obj.parameters.selected_files_preds = matchedPreds;
            obj.parameters.selected_files_labels = matchedLabels;

            % Log the action
            obj.log{end+1} = sprintf('%s: Prepared training data from %s. Matched %d file pairs.', ...
                char(datetime('now')), mainDataDir, length(matchedPreds));
            obj.saveProject();
        end

        function fileList = findFiles(obj, fileType)
            if strcmp(fileType, 'preds')
                folder = obj.parameters.sleappredspath;
            elseif strcmp(fileType, 'labels')
                folder = obj.parameters.sleaplabelspath;
            else
                error('Invalid file type specified');
            end

            filePattern = fullfile(folder, obj.filePatterns.(fileType));
            files = dir(filePattern);
            fileList = fullfile({files.folder}, {files.name});
        end

        function setFilePattern(obj, fileType, pattern)
            if ~isfield(obj.filePatterns, fileType)
                error('Invalid file type. Use ''preds'' or ''labels''.');
            end
            obj.filePatterns.(fileType) = pattern;
        end

        function [matchedPreds, matchedLabels] = matchFiles(~, predsFiles, labelsFiles)
            % Extract identifiers from filenames
            getIdentifier = @(filename) regexp(filename, '\d{3}_WIN_\d{8}_\d{2}_\d{2}_\d{2}', 'match', 'once');
            predIdentifiers = cellfun(getIdentifier, predsFiles, 'UniformOutput', false);
            labelIdentifiers = cellfun(getIdentifier, labelsFiles, 'UniformOutput', false);

            % Find matches
            [~, predIdx, labelIdx] = intersect(predIdentifiers, labelIdentifiers, 'stable');

            % Return matched files
            matchedPreds = predsFiles(predIdx);
            matchedLabels = labelsFiles(labelIdx);
        end
    
    function trainAuto(obj, modelName)
            % Check if modelName is provided, if not, generate a default name
            if nargin < 2 || isempty(modelName)
                modelName = ['model_', datestr(now, 'yyyymmdd_HHMMSS')];
            end
            
            % Create full path for the model
            modelPath = fullfile(obj.modelsDir, [modelName, '.h5']);
            
            % Check if model with this name already exists
            if exist(modelPath, 'file')
                error('Model with name %s already exists. Please choose a different name.', modelName);
            end
            
            % Update parameters with the new model path
            obj.parameters.autoenc.modelPath = modelPath;
            
            % Ensure other necessary paths are set
            if ~isfield(obj.parameters.autoenc, 'trainingsetpath') || ...
               ~isfield(obj.parameters.autoenc, 'features_means_path')
                error('Training set path or features means path is not set in parameters.');
            end
            
            % Log the start of training
            obj.log{end+1} = sprintf('%s: Starting training of model: %s', datetime('now'), modelName);
            
            try
                % Call the training function
                param_dict = params_to_python_dict(obj.parameters.autoenc.model_params);
                obj.module.trainmodel(...
                    obj.parameters.autoenc.trainingsetpath, ...
                    obj.parameters.autoenc.features_means_path, ...
                    modelPath, obj.parameters.autoenc.v73,param_dict);
                
                % Log successful training
                obj.log{end+1} = sprintf('%s: Successfully trained model: %s', datetime('now'), modelName);
            catch ME
                % Log error if training fails
                obj.log{end+1} = sprintf('%s: Error training model %s: %s', datetime('now'), modelName, ME.message);
                rethrow(ME);
            end
            
            % Save updated project
            obj.saveProject();
            function py_dict = params_to_python_dict(model_params)
            % Convert MATLAB struct to Python dict
            py_dict = py.dict();
            
            % Add model parameters
            fields = fieldnames(model_params);
            for i = 1:length(fields)
                key = fields{i};
                value = model_params.(key);
                if strcmp(key, 'input_shape')
                    % Ensure input_shape is a tuple of integers
                    py_dict{key} = py.tuple(int32(value));
                elseif isnumeric(value) && ~isscalar(value)
                    % Convert MATLAB arrays to Python lists
                    py_dict{key} = py.list(num2cell(int32(value)));
                elseif isinteger(value)
                    % Ensure integers are passed as Python ints
                    py_dict{key} = int64(value);
                elseif isfloat(value)
                    % Ensure floats are passed as Python floats
                    py_dict{key} = py.float(value);
                else
                    py_dict{key} = value;
                end
            end
        end
    end
    

        function listModels(obj)
            % List all models in the models directory
            models = dir(fullfile(obj.modelsDir, '*.h5'));
            if isempty(models)
                disp('No models found.');
            else
                disp('Available models:');
                for i = 1:length(models)
                    disp(['  ', models(i).name]);
                end
            end
        end

        function setCurrentModel(obj, modelName)
            % Set the current model to use for predictions
            modelPath = fullfile(obj.modelsDir, [modelName, '.h5']);
            if ~exist(modelPath, 'file')
                error('Model %s does not exist.', modelName);
            end
            obj.parameters.autoenc.modelPath = modelPath;
            obj.log{end+1} = sprintf('%s: Set current model to: %s', datetime('now'), modelName);
            obj.saveProject();
        end
    end
    %% TODO: Need to implement Reconstruction next
    methods(Static)
        function obj = loadProject(projectFile)
            % Load an existing project
            if exist(projectFile, 'file')
                loaded = load(projectFile);
                obj = loaded.obj;
                disp(['Loaded project: ' obj.name]);
                obj.loadModule();
            else
                error('Project file does not exist.');
            end
        end
        
        function obj = create(projectName, baseDir, params)
            % Static method to create a new project
            if nargin < 3
                obj = Project(projectName, baseDir);
            else
                obj = Project(projectName, baseDir, params);
            end
        end
    end
end