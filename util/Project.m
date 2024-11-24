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
        osinfo
    end
    
    methods
        function obj = Project(projectName, params)
            baseDir = fullfile('Projects',projectName);
            % Constructor
            if nargin >= 1
                obj.name = projectName;
                obj.creationDate = datetime('now');
                obj.baseDir = baseDir;
                obj.dataDir = fullfile(baseDir, 'data');
                obj.fileRegistry = struct('original', {}, 'processed', {}, 'status', {});
                obj.log = {};
                obj.filePatterns = struct(...
                'preds', '*.analysis.h5', ...
                'labels', '*.analysis.h5' ...
                );
                % osinfo will be indicate if the system is windows or linux using ismac and ispc
                if ismac
                    obj.osinfo = 'mac';
                elseif ispc
                    obj.osinfo = 'windows';
                else
                    obj.osinfo = 'linux';
                end
                
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
                if nargin < 2 || isempty(params)
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
        function loadModule(obj, moduleType)
            if nargin < 2
                moduleType = 'TC_Auto';
            end
            
            if strcmp(moduleType, 'TC_Auto')
                load_TC_auto(obj)
            end
            if strcmp(moduleType, 'TSNE_MLP')
                load_TSNE_MLP(obj)
            end
        end
        function load_TC_auto(obj)
            % Load the TC_Auto module
            utilDir = fullfile(pwd, 'Pose_Reconstruction/Util');
                
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
        function load_TSNE_MLP(obj)
            % Load the TSNE_MLP module
            utilDir = fullfile(pwd, 'Embedding/util');
                
                % Add the Util directory to Python's sys.path
                if count(py.sys.path, utilDir) == 0
                    insert(py.sys.path, int32(0), utilDir);
                end
                
                % Now import the module
                try
                    obj.module = py.importlib.import_module('TrainandPredictWithMLP');
                    disp('Successfully imported TSNE_MLP module');
                catch ME
                    error('Failed to import TSNE_MLP module: %s', ME.message);
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
                obj.loadModule()
            end
        end
        
        function [processedFilePath] = addProcessedFile(obj, originalFilePath, processedData, processingType, processedDataLength)
            if nargin < 5
                if isfield(processedData.fp, 'posdata_reconstructed')
                    processedDataLength = length(processedData.fp.posdata_reconstructed);
                else
                    processedDataLength = [];
                end 
                
            end
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
                newEntry.processed.(processingType) = struct('filePath', processedFilePath, 'dataLength', processedDataLength);
                newEntry.status = struct(...
                    'sleap_extracted', false, ...
                    'autoencoder_completed', false, ...
                    'features_extracted', false, ...
                    'wavelets_completed', false,...
                    'embedded', false, ...
                    'segmented', false ...
                );
                obj.fileRegistry(end+1) = newEntry;
            else
                % If yes, add or update the processed file for this processing type
                obj.fileRegistry(originalFileIndex).processed.(processingType) = struct('filePath', processedFilePath, 'dataLength', processedDataLength);
            end
            
            % Add log entry
            logEntry = sprintf('Processed file: %s -> %s (Type: %s, Length: %d)', originalFilePath, processedFilePath, processingType, processedDataLength);
            obj.log{end+1} = sprintf('%s: %s', char(datetime('now')), logEntry);
            
            % Save updated project
            obj.saveProject();
        end
        function updateProcessingStatus(obj, filePath, statusType, value, processedData)
            % Update the processing status for a specific file, whether it's an original or processed file
            % Try to find the file as an original file
            originalFileIndex = find(strcmp({obj.fileRegistry.original}, filePath), 1);
            
            % If not found, try to find it as a processed file
            if isempty(originalFileIndex)
            originalFilePath = obj.getOriginalFile(filePath);
            if ~isempty(originalFilePath)
                originalFileIndex = find(strcmp({obj.fileRegistry.original}, originalFilePath), 1);
            end
            end
            
            % Update the processing status if the original file is found
            if ~isempty(originalFileIndex)
            obj.fileRegistry(originalFileIndex).status.(statusType) = value;
            % Save updated project
            if nargin == 5
                ProcessedFilePath =  obj.getProcessedFile(originalFilePath);
                save(ProcessedFilePath, 'processedData');
                % Add log entry
                logEntry = sprintf('Updated status for file: %s, %s = %d', obj.fileRegistry(originalFileIndex).original, statusType, value);
                obj.log{end+1} = sprintf('%s: %s', char(datetime('now')), logEntry);
                obj.log{end+1} = sprintf('%s: Saved updated data for file: %s', char(datetime('now')), ProcessedFilePath);
            else
                % Add log entry
                logEntry = sprintf('Updated status for file: %s, %s = %d', obj.fileRegistry(originalFileIndex).original, statusType, value);
                obj.log{end+1} = sprintf('%s: %s', char(datetime('now')), logEntry);
            end
            obj.saveProject();
            else
            warning('File not found in registry: %s', filePath);
            end
        end
        function status = getProcessingStatus(obj, filePath)
            % Get the processing status for a specific file, whether it's an original or processed file
            
            % Try to find the file as an original file
            originalFileIndex = find(strcmp({obj.fileRegistry.original}, filePath), 1);
            
            % If not found, try to find it as a processed file
            if isempty(originalFileIndex)
                originalFilePath = obj.getOriginalFile(filePath);
                if ~isempty(originalFilePath)
                    originalFileIndex = find(strcmp({obj.fileRegistry.original}, originalFilePath), 1);
                end
            end
            
            % Get the processing status if the original file is found
            if ~isempty(originalFileIndex)
                status = obj.fileRegistry(originalFileIndex).status;
            else
                status = [];
                warning('File not found in registry: %s', filePath);
            end
        end
        
        function processedFilePath = getProcessedFile(obj, originalFilePath, processingType)
            % Find the original file1 in the registry
            if nargin < 3
                processingType = 'default_reconstruction';
            end
            originalFileIndex = find(strcmp({obj.fileRegistry.original}, originalFilePath), 1);
            
            if isempty(originalFileIndex)
                processedFilePath = '';
                warning('File not found in registry: %s', originalFilePath);
                return;
            end
            
            % Check if the processing type exists for this file
            if isfield(obj.fileRegistry(originalFileIndex).processed, processingType)
                processedFilePath = obj.fileRegistry(originalFileIndex).processed.(processingType);
                if isstruct(processedFilePath)
                    processedFilePath = processedFilePath.filePath;
                end
            else
                processedFilePath = '';
                warning('Processing type not found for file: %s', originalFilePath);
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
            
     function prepareTrainingData_PR(obj, mainDataDir)
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
                param_dict = params_to_python_dict(obj.parameters.autoenc.model_parameters);
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
    function [processedFiles] = returnDefaultReconstructionFiles(obj, reconsmethod)
        %% This returns a cell array of all the files that have been processed with the default reconstruction method
        if nargin < 2
            reconsmethod = 'default_reconstruction';
        end
        % Initialize an empty cell array to store the file paths
        processedFiles = {};
        % Loop through each struct and add the default_reconstruction path to the list
        for i = 1:numel(obj.fileRegistry)
            if isstruct(obj.fileRegistry(i).processed)
                processedFiles{end+1} = obj.fileRegistry(i).processed.(reconsmethod).filePath;
            else
                processedFiles{end+1} = obj.fileRegistry(i).processed.(reconsmethod);
            end
        end
    end
    function lengths = returnDataLengths(obj, recons_type)
        if nargin < 2
            recons_type = 'default_reconstruction';
        end
        numFiles = numel(obj.fileRegistry);
        for i = 1:numFiles
            lengths(i) = obj.fileRegistry(i).processed.(recons_type).dataLength;
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
        function addDefaultAutoModel(obj, defaultmodelpath)
            if nargin < 2 || ~exist("defaultmodelpath","var")
               [parDir, curdir, ~] = fileparts(pwd);
                defaultmodelpath = fullfile(parDir,curdir, 'Pose_Reconstruction','Models', 'conv_autoencoder_model_default.h5');
            end 
            source = defaultmodelpath;
            destination = fullfile(obj.modelsDir, ['conv_autoencoder_model_default', '.h5']);
            copyfile(source,destination)
            obj.log{end+1} = sprintf('%s: Set current model to: %s', datetime('now'), 'default model');
            obj.saveProject();
        end 
        function addDefaultMLPModel(obj, defaultmodelpath)
            if nargin < 2 || ~exist("defaultmodelpath","var")
                defaultmodelpath = fullfile(pwd, 'Data','Default_MLP', 'converted_model.json');
            end 
            source = defaultmodelpath;
            destination = fullfile(obj.modelsDir, ['unif_MLP', '.json']);
            copyfile(source,destination)
            obj.parameters.embedding.mlp.default.model_path = destination;
            obj.log{end+1} = sprintf('%s: Set current model to: %s', datetime('now'), 'default model');
            obj.saveProject();
            
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

        function [isPrepared, isTrained] = checkProcess(obj)
            % Check if data preparation has been done
            isPrepared.files = isfield(obj.parameters, 'selected_files_preds') && ...
                         isfield(obj.parameters, 'selected_files_labels') && ...
                         ~isempty(obj.parameters.selected_files_preds) && ...
                         ~isempty(obj.parameters.selected_files_labels);
            
            if isfield(obj.parameters.autoenc, 'traintestdataready') && ...
                isfield(obj.parameters.autoenc, 'trainingsetpath')
                isPrepared.traintest = obj.parameters.autoenc.traintestdataready;
            else
                isPrepared.traintest = false;
            end
             
            
            % Check if a model has been trained
            isTrained = isfield(obj.parameters, 'autoenc') && ...
                        isfield(obj.parameters.autoenc, 'modelPath') && ...
                        exist(obj.parameters.autoenc.modelPath, 'file') == 2;
        end
        
        % I need a method to take a processed file and return the matching original file        
        function originalFile = getOriginalFile(obj, processedFile)
            % Find the original file that matches the processed file
            for i = 1:length(obj.fileRegistry)
                if isfield(obj.fileRegistry(i).processed, 'default_reconstruction') && ...
                   strcmp(obj.fileRegistry(i).processed.default_reconstruction.filePath, processedFile)
                    originalFile = obj.fileRegistry(i).original;
                    return;
                end
            end
            originalFile = '';
        end
        % add a method to  % Return the runDir and metadata
        % out.runDir = runDir;
        % out.metadata = metadata;
        % % Now we need to couple all this with the project
        % project.addMLPModel(runDir, metadata); % How should this be implemented? 
        function addMLPModel(obj, runDir, metadata)
            % Add the MLP model to the project
            obj.parameters.embedding.mlp.runDir = runDir;
            obj.parameters.embedding.mlp.metadata = metadata;
            obj.log{end+1} = sprintf('%s: Added MLP model to project', datetime('now'));
            obj.saveProject();
        end
        % now we need a method to select the correct mlp model which defaults to the most recent one
        
        function setMLPModel(obj, mlpfolder)
            % mlpfolder should be a datetime
            % Set the MLP model to use for predictions
            outputdirname = obj.parameters.embedding.mlp.outputdir;
            outputdirpath = fullfile(obj.baseDir, 'data', 'EmbeddingData', outputdirname);
            if nargin < 2
                % the goal here is to point to the most recent model in the output directory
                % we need to grab the most recent model from the output directory
                % outputdirname = model_output
                % outputdirpath = baseDir/data/EmbeddingData/outputdirname        
                OutputDir = dir(outputdirpath);
                
                modelFolders = OutputDir([OutputDir.isdir]);
                modelFolders = modelFolders(~ismember({modelFolders.name}, {'.', '..'}));
                if isempty(modelFolders)
                    error('No MLP models found in %s', OutputDir);
                end
                
                modelDates = datetime({modelFolders.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
                [~, idx] = max(modelDates);
                mlpfolder = modelFolders(idx).name;
                
                modelPath = fullfile(outputdirpath, mlpfolder, obj.parameters.embedding.mlp.model_name);
                mlpDirPath = fullfile(outputdirpath, mlpfolder);
                
                obj.parameters.embedding.mlp.runDir = mlpDirPath;
                % now we need to grab the metadata from the model folder
                metadataPath = fullfile(mlpDirPath, 'metadata.json');
                metadata = jsondecode(fileread(metadataPath));
                obj.parameters.embedding.mlp.metadata = metadata;
                % now log the action
                obj.log{end+1} = sprintf('%s: Set current MLP model to: %s', datetime('now'), modelPath);
                obj.saveProject();
                return
            elseif nargin == 2
                % now we need to construct the full path to the model which is basedir/data/EmbeddingData/model_output/datetime/model.joblib
                mlpDirPath = fullfile(outputdirpath, mlpfolder);
                obj.parameters.embedding.mlp.runDir = mlpDirPath;
                metadataPath = fullfile(mlpDirPath, 'metadata.json');
                metadata = jsondecode(fileread(metadataPath));
                obj.parameters.embedding.mlp.metadata = metadata;
                % now log the action
                obj.log{end+1} = sprintf('%s: Set current MLP model to: %s', datetime('now'), mlpfolder);
                obj.saveProject();

               
            end

        end 
         
    end
    %% TODO: Need to implement Reconstruction next, Done
    methods(Static)
        function checkPythonEnv()
            % Check if pyenv is already configured
            try
                current_pyenv = pyenv;
                disp('Current Python environment:');
                disp(current_pyenv);
            catch
                error('pyenv is not configured. Please set up your Python environment first.');
            end

            % Verify that the correct Python is being used
            disp(['Using Python version: ', char(py.sys.version)]);
            if ~contains(char(py.sys.version), '3.9') && ~contains(char(py.sys.version), '3.10') && ~contains(char(py.sys.version), '3.11')
                warning('At least Python 3.9 is required. Please set up your Python environment accordingly.');
            end
        end

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