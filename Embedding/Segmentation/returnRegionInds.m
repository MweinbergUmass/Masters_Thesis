function region_inds = returnRegionInds(Y_embedded,XEDGES,YEDGES, L)

    region_inds = zeros(1,length(Y_embedded));
    for i = 1:length(Y_embedded)
        currentx = Y_embedded(i, 1);
        currenty = Y_embedded(i, 2);
        Xind = find(currentx <= XEDGES, 1, 'first'); 
        Yind = find(currenty <= YEDGES, 1, 'first'); 
        % Ensure indices are within the bounds of L
        if isempty(Xind) || isempty(Yind) || Xind > size(L, 1) || Yind > size(L, 2)
            region_inds(i) = 0; % Assign 0 or some indicator for out-of-bounds
        else
            region_inds(i) = L(Xind, Yind);
        end
    end 