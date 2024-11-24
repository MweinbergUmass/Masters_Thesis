function Embedalldata(project)
    % okay so we have the MLP now lets use it to embed the out of sample data
    % first we need to load the data
   proc_mice_pos_files = project.returnDefaultReconstructionFiles();
   for i = 1:length(proc_mice_pos_files)
    % first check if we have already embedded this data
    processing_status = project.getProcessingStatus(proc_mice_pos_files{i});
    if processing_status.embedded == 1
        sprintf('Data already embedded for %s', proc_mice_pos_files{i})
        continue
    end

    Embedoos(proc_mice_pos_files{i}, project);
    end 

end