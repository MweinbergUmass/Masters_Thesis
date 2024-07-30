function setup_parpool(desiredPoolSize)
    % Set up a parallel pool of the desired number of workers
    %
    %  function setup_parpool(desiredPoolSize)
    %
    % Runs the correct parallel pool setup function for different versions 
    % of MATLAB.
    %
    % Inputs
    % desiredPoolSize - an integer specifying the desired number of workers
    %
    %
    % Rob Campbell - TENSS 2017


    % Is the parallel computing toolbox installed?
    if isempty(ver('parallel'))
        fprintf('No parallel computing toolbox installed\n')
        return
    end

    % Start the desired number of workers. Delete existing pool with wrong number
    % of workers if needed.
    g = gcp('nocreate'); % Get the current parallel pool without creating a new one
    if isempty(g) || g.NumWorkers ~= desiredPoolSize
        delete(g); % Delete the current pool if it exists
        if desiredPoolSize > 1
            parpool(desiredPoolSize); % Start a new pool with the desired number of workers
        end
    end
end