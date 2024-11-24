function sequences = create_sequences(data,sequence_length)
    for j = 1:length(data)-sequence_length
        sequences{j} = data(j:j+sequence_length-1,:);
    end 
    % sequences = reshape(cell2mat(sequences), [length(data)-sequence_length, sequence_length, size(sequences{1},2)]);
    num = zeros(size(sequences,2), size(sequences{1},1), size(sequences{1},2));
    for jj = 1 : length(sequences)
        num(jj,:,:) = sequences{jj}; 
    end
    sequences = num;
end 