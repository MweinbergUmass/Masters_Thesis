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
                
                % Create project and data directories if they don't exist
                if ~exist(obj.baseDir, 'dir')
                    mkdir(obj.baseDir);
                end
                if ~exist(obj.dataDir, 'dir')
                    mkdir(obj.dataDir);
                end
                
                % Handle parameters
                if nargin < 3 || isempty(params)
                    obj.parameters = obj.setparams();
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
        
        function saveProject(obj)
            % Save the project structure
            projectFile = fullfile(obj.baseDir, [obj.name '_project.mat']);
            save(projectFile, 'obj');
            disp(['Saved project: ' obj.name]);
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
            % Find the original file in the registry
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
            obj.parameters = newParams;
            save(obj.parameterFile, 'newParams');
            obj.log{end+1} = sprintf('%s: Updated project parameters', char(datetime('now')));
            obj.saveProject();
        end
    end
    
    methods(Static)
        function obj = loadProject(projectFile)
            % Load an existing project
            if exist(projectFile, 'file')
                loaded = load(projectFile);
                obj = loaded.obj;
                disp(['Loaded project: ' obj.name]);
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