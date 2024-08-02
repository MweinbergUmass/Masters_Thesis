function setuppyenv(envName,yamlFile)
    if nargin < 1
        envName = 'MotmautoEnv';
    end
    if nargin < 2
        % we need to check the os to see if we should use the mac or windows yaml file
        if ispc
            yamlFile = 'environment_windows.yml';
        else
            yamlFile = 'environment_mac.yml';
        end
    end

    % Check if the YAML file exists
    if ~exist(yamlFile, 'file')
        error('YAML file not found: %s', yamlFile);
    end

    % Check if conda is installed and get its path
    condaPath = FindCondaPath();
    
    if isempty(condaPath)
        % Install Miniconda if conda is not found
        installMiniconda();
        condaPath = FindCondaPath(); % Get path again after installation
        if isempty(condaPath)
            error('Failed to install or locate Conda. Please install Conda manually.');
        end
    end
    
    % Ensure conda is in the system PATH
    updateSystemPath(fileparts(condaPath));

    % Check if the environment already exists
    [status, cmdout] = system(['"' condaPath '" env list']);
    if contains(cmdout, envName)
        % Environment exists, check if it needs updating
        disp(['Environment ' envName ' already exists. Checking for updates...']);
        updateEnvironment(condaPath, yamlFile, envName);
    else
        % Create the environment from YAML file
        [status, cmdout] = system(['"' condaPath '" env create -f "' yamlFile '" -n ' envName]);
        if status ~= 0
            error('Failed to create environment. Error: %s', cmdout);
        end
    end

    % Get the path to the Python executable
    if ispc
        [~, cmdout] = system(['"' condaPath '" run -n ' envName ' where python']);
    else
        [~, cmdout] = system(['"' condaPath '" run -n ' envName ' which python']);
    end
    pythonPath = strtrim(cmdout);

    if isempty(pythonPath)
        error('Failed to locate Python in the created environment.');
    end

    % Set up the Python environment in MATLAB
    try
        pyenv('Version', pythonPath);
        disp(['Successfully set up Python environment: ' pyenv().Executable]);
        
    catch ME
        error('Failed to set up Python environment in MATLAB. Error: %s', ME.message);
    end
end

function updateEnvironment(condaPath, yamlFile, envName)
    % Parse YAML file
    requiredPackages = parseYAML(yamlFile);
    if isempty(requiredPackages)
        error('No dependencies found in the YAML file.');
    end

    % Check installed packages
    [~, cmdout] = system(['"' condaPath '" list -n ' envName]);
    installedPackages = strsplit(cmdout, '\n');

    % Compare and update packages
    for i = 1:length(requiredPackages)
        packageName = strsplit(requiredPackages{i}, '=');
        packageName = strtrim(packageName{1});
        if ~any(contains(installedPackages, packageName))
            disp(['Installing missing package: ' packageName]);
            [status, cmdout] = system(['"' condaPath '" install -n ' envName ' -y ' packageName]);
            if status ~= 0
                warning('Failed to install package %s. Error: %s', packageName, cmdout);
            end
        end
    end
    
    disp('Environment update complete.');
end

function requiredPackages = parseYAML(yamlFile)
    % Simple YAML parser for dependencies
    fid = fopen(yamlFile, 'r');
    content = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    content = content{1};

    inDependencies = false;
    requiredPackages = {};
    for i = 1:length(content)
        line = strtrim(content{i});
        if strcmp(line, 'dependencies:')
            inDependencies = true;
        elseif inDependencies && startsWith(line, '- ')
            package = strtrim(line(3:end));
            if ~startsWith(package, 'pip:') && ~isempty(package)
                requiredPackages{end+1} = package;
            end
        elseif inDependencies && ~startsWith(line, '- ')
            break;
        end
    end
end

function installMiniconda()
    % Download Miniconda
    if ispc
        url = 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe';
        installer = 'Miniconda3-latest-Windows-x86_64.exe';
    elseif ismac
        url = 'https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh';
        installer = 'Miniconda3-latest-MacOSX-x86_64.sh';
    else
        url = 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh';
        installer = 'Miniconda3-latest-Linux-x86_64.sh';
    end
    
    try
        websave(installer, url);
    catch
        error('Failed to download Miniconda installer. Please check your internet connection.');
    end

    % Install Miniconda
    if ispc
        [status, cmdout] = system([installer ' /S /D=%UserProfile%\Miniconda3']);
    else
        [status, cmdout] = system(['bash ' installer ' -b -p $HOME/miniconda3']);
    end
    
    if status ~= 0
        error('Failed to install Miniconda. Error: %s', cmdout);
    end

    % Add Miniconda to PATH
    if ispc
        updateSystemPath([getenv('UserProfile') '\Miniconda3\Scripts']);
    else
        updateSystemPath('$HOME/miniconda3/bin');
    end
end

function condaPath = FindCondaPath()
    % Initialize condaPath as empty
    condaPath = '';

    % Define possible Conda executable names
    if ispc
        condaExe = 'conda.exe';
    else
        condaExe = 'conda';
    end

    % 1. Check MATLAB's PATH
    matlabPath = strsplit(getenv('PATH'), pathsep);
    for i = 1:length(matlabPath)
        possiblePath = fullfile(matlabPath{i}, condaExe);
        if exist(possiblePath, 'file')
            condaPath = possiblePath;
            disp(['Conda found in MATLAB PATH: ' condaPath]);
            return;
        end
    end

    % 2. Check system PATH (which might be different from MATLAB's PATH)
    if ispc
        [status, result] = system(['where ' condaExe]);
    else
        [status, result] = system('command -v conda');
    end
    if status == 0
        condaPath = strtrim(result);
        disp(['Conda found in system PATH: ' condaPath]);
        return;
    end

    % 3. Check common installation directories
    if ispc
        commonPaths = {
            [getenv('UserProfile') '\Miniconda3'],
            [getenv('UserProfile') '\Anaconda3'],
            'C:\ProgramData\Miniconda3',
            'C:\ProgramData\Anaconda3',
            'C:\Miniconda3',
            'C:\Anaconda3'
        };
    else
        [~, homeDir] = system('echo $HOME');
        homeDir = strtrim(homeDir);
        commonPaths = {
            fullfile(homeDir, 'miniconda3'),
            fullfile(homeDir, 'anaconda3'),
            '/opt/miniconda3',
            '/opt/anaconda3',
            '/usr/local/miniconda3',
            '/usr/local/anaconda3'
        };
    end

    for i = 1:length(commonPaths)
        if ispc
            possiblePath = fullfile(commonPaths{i}, 'Scripts', condaExe);
        else
            possiblePath = fullfile(commonPaths{i}, 'bin', condaExe);
        end
        if exist(possiblePath, 'file')
            condaPath = possiblePath;
            disp(['Conda found at: ' condaPath]);
            return;
        end
    end

    % 4. Search user's home directory (for custom installations)
    if ispc
        [~, userProfile] = system('echo %UserProfile%');
        searchPath = strtrim(userProfile);
        [status, result] = system(['dir /s /b "' searchPath '\*' condaExe '"']);
    else
        [~, homeDir] = system('echo $HOME');
        searchPath = strtrim(homeDir);
        [status, result] = system(['find "' searchPath '" -name "' condaExe '"']);
    end
    if status == 0
        paths = strsplit(result, newline);
        for i = 1:length(paths)
            if ~isempty(strfind(paths{i}, condaExe))
                condaPath = strtrim(paths{i});
                disp(['Conda found in home directory: ' condaPath]);
                return;
            end
        end
    end

    % If Conda is not found, return empty string
    if isempty(condaPath)
        warning('Conda not found. Please ensure Conda is installed and in the system PATH.');
    end
end
function updateSystemPath(newPath)
    if ispc
        setenv('PATH', [getenv('PATH') ';' newPath]);
    else
        setenv('PATH', [getenv('PATH') ':' newPath]);
    end
end