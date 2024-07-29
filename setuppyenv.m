function PYENV = setuppyenv()
    % Check if pyenv is already configured
    try
        current_pyenv = pyenv;
        disp('Current Python environment:');
        disp(current_pyenv);
    catch
        error('pyenv is not configured. Please set up your Python environment first.');
    end
    
    % Store the current executable path
    pythonExecutable = current_pyenv.Executable;
    
    % Verify that the correct Python is being used
    disp(['Using Python version: ', char(py.sys.version)]);
    
    % Check and install required packages
    checkAndInstallRequiredPackages(pythonExecutable);
    
    % Reload the Python environment to recognize newly installed packages
    try
        % Terminate the current Python environment
        terminate(pyenv);
        % Recreate the Python environment
        PYENV = pyenv('Version', pythonExecutable);
        disp('Python environment reloaded successfully.');
    catch ME
        warning('Failed to reload Python environment. You may need to restart MATLAB to recognize new packages.');
        disp(['Error message: ' ME.message]);
        PYENV = current_pyenv;
    end
end

function checkAndInstallRequiredPackages(pythonExecutable)
    % Read requirements from requirements.txt
    reqFile = 'requirements.txt';
    fid = fopen(reqFile, 'r');
    if fid == -1
        error('Cannot open requirements.txt. Make sure it exists in the current directory.');
    end
    requirements = textscan(fid, '%s');
    fclose(fid);
    requirements = requirements{1};
    
    missingPackages = {};
    
    % Check each required package
    for i = 1:length(requirements)
        [package, version] = strtok(requirements{i}, '==');
        version = strtrim(version);
        
        % Use system command to check package status
        cmd = sprintf('"%s" -m pip show %s', pythonExecutable, package);
        [status, cmdout] = system(cmd);
        
        if status == 0
            installedVersion = regexp(cmdout, 'Version: ([\d\.]+)', 'tokens');
            if ~isempty(installedVersion)
                installedVersion = installedVersion{1}{1};
                if ~isempty(version) && ~strcmp(installedVersion, version(3:end))
                    disp(['Package ', package, ' is installed but version mismatch. Adding to update list.']);
                    missingPackages{end+1} = requirements{i};
                else
                    disp(['Package ', package, ' is already installed with version ', installedVersion, '.']);
                end
            else
                disp(['Package ', package, ' is installed but version could not be determined.']);
            end
        else
            disp(['Package ', package, ' is not installed. Adding to installation list.']);
            missingPackages{end+1} = requirements{i};
        end
    end
    
    % Install missing or outdated packages
    if ~isempty(missingPackages)
        disp('Installing/updating packages...');
        installCmd = sprintf('"%s" -m pip install --upgrade %s', pythonExecutable, strjoin(missingPackages, ' '));
        disp(['Running command: ', installCmd]);
        [status, cmdout] = system(installCmd);
        if status == 0
            disp('Successfully installed/updated packages.');
            disp(cmdout);
        else
            warning('Failed to install/update some packages. Please install them manually.');
            disp(cmdout);
        end
    else
        disp('All required packages are already installed with correct versions.');
    end
end