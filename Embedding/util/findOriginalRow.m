function [fileIndex, fileName, originalRow] = findOriginalRow(rowCorrespondence, embeddingRow)
    for i = 1:length(rowCorrespondence)
        if any(rowCorrespondence(i).embeddingRows == embeddingRow)
            fileIndex = rowCorrespondence(i).fileIndex;
            fileName = rowCorrespondence(i).fileName;
            originalRowIndex = find(rowCorrespondence(i).embeddingRows == embeddingRow);
            originalRow = rowCorrespondence(i).originalRows(originalRowIndex);
            return;
        end
    end
    fileIndex = NaN;
    fileName = '';
    originalRow = NaN;
end