function setuppyenv(yamlFile, envName)
    if nargin < 2
        envName = 'MotmautoEnv';
    end
    if nargin < 1
        yamlFile = 'environment.yml';
    end
    % Check if conda is installed
    [status, ~] = system('conda --version');
    if status ~= 0
        % Install Miniconda
        installMiniconda();
    end
    
    % Create the environment from YAML file
    [status, cmdout] = system(['conda env create -f ' yamlFile ' -n ' envName]);
    if status ~= 0
        error(['Failed to create environment. Error: ' cmdout]);
    end
    
    % Get the path to the new Python executable
    [~, cmdout] = system(['conda run -n ' envName ' which python']);
    pythonPath = strtrim(cmdout);
    
    % Set up the Python environment in MATLAB
    try
        pyenv('Executable', pythonPath);
        disp(['Successfully set up Python environment: ' pyenv.Executable]);
    catch
        error('Failed to set up Python environment in MATLAB.');
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
    
    websave(installer, url);
    
    % Install Miniconda
    if ispc
        system([installer ' /S /D=%UserProfile%\Miniconda3']);
    else
        system(['bash ' installer ' -b -p $HOME/miniconda3']);
    end
    
    % Add Miniconda to PATH
    if ispc
        setenv('PATH', [getenv('PATH') ';%UserProfile%\Miniconda3;%UserProfile%\Miniconda3\Scripts']);
    else
        setenv('PATH', [getenv('PATH') ':$HOME/miniconda3/bin']);
    end
end