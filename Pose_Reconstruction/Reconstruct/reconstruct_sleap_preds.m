function [proc_mice_pos_data] = reconstruct_sleap_preds(sleaph5path, project, processingType, overRide)
    % Default processing type if not specified
    if nargin < 3
        processingType = 'default_reconstruction';
    end
    if nargin < 4
        overRide = 0;
    end
    % Ensure we have a valid project
    if ~isa(project, 'Project')
        error('Second argument must be a Project object');
    end
    % Check if this file has already been processed with this processing type
    existingProcessedFile = project.getProcessedFile(sleaph5path, processingType);
    if ~isempty(existingProcessedFile) && overRide == 0
        disp(['File already processed. Loading: ' existingProcessedFile]);
        load(existingProcessedFile, 'processedData');
        proc_mice_pos_data = processedData;
        return;
    end
    % Get parameters from the project
    params = project.parameters;
    % Import Python module
    mod = project.module;
    % Preprocess data
    [sequences_fp, sequences_ri, proc_mice_pos_data, sequence_length] = preprocforVAE_T_Conv(project, sleaph5path, params.autoenc.model_parameters.sequence_length);
    % Convert to Python numpy arrays
    sequences_fp = py.numpy.array(sequences_fp);
    sequences_ri = py.numpy.array(sequences_ri);
    % Get predictions from Python model
    reconstructedDataPy_ri = mod.get_predictions(sequences_ri, params.autoenc.modelPath);
    reconstructedDataPy_fp = mod.get_predictions(sequences_fp, params.autoenc.modelPath);
    % Convert the returned data back into a MATLAB array
    proc_mice_pos_data.ri.reconstructedData = squeeze_recons(double(reconstructedDataPy_ri));
    proc_mice_pos_data.fp.reconstructedData = squeeze_recons(double(reconstructedDataPy_fp));
    % Invert ego center
    proc_mice_pos_data.ri.posdata_reconstructed = invert_ego_center_V3(proc_mice_pos_data.ri.reconstructedData', ...
        proc_mice_pos_data.ri.scale_factor, proc_mice_pos_data.ri.centroid.ref, ...
        proc_mice_pos_data.ri.centroid.frame, proc_mice_pos_data.ri.frame_rotation);
    proc_mice_pos_data.fp.posdata_reconstructed = invert_ego_center_V3(proc_mice_pos_data.fp.reconstructedData', ...
        proc_mice_pos_data.fp.scale_factor, proc_mice_pos_data.fp.centroid.ref, ...
        proc_mice_pos_data.fp.centroid.frame, proc_mice_pos_data.fp.frame_rotation);
    proc_mice_pos_data.sequence_length = sequence_length;
    % Add processed file to project and save
    processedFilePath = project.addProcessedFile(sleaph5path, proc_mice_pos_data, processingType);
    project.updateProcessingStatus(sleaph5path, 'sleap_extracted', 1)
    project.updateProcessingStatus(sleaph5path, 'autoencoder_completed', 1)
    % Update proc_mice_pos_data with the new file path
    proc_mice_pos_data.filepath = processedFilePath;
    project.saveProject()
end