function [embeddingRows, fileName] = findEmbeddingRows(rowCorrespondence, fileIndex, originalRow)
    fileEntry = rowCorrespondence([rowCorrespondence.fileIndex] == fileIndex);
    if isempty(fileEntry)
        embeddingRows = [];
        fileName = '';
        return;
    end
    originalRowIndices = find(fileEntry.originalRows == originalRow);
    embeddingRows = fileEntry.embeddingRows(originalRowIndices);
    fileName = fileEntry.fileName;
end
