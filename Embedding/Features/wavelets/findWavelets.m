function [amplitudes,f,Frame_amps] = findWavelets(projections,project)
%findWavelets finds the wavelet transforms resulting from a time series
%
%   Input variables:
%
%       projections -> N x d array of projection values
%       parameters -> project which contains choices for parameters
%
%
%   Output variables:
%
%       amplitudes -> wavelet amplitudes (N x (pcaModes*numPeriods) )
%       f -> frequencies used in wavelet transforms (Hz)
%
%
% (C) Gordon J. Berman, 2014
%     Princeton University
%       modified by Max Weinberg 2024
%       University of Massachusetts Amherst

    
    if size(projections,2) > size(projections,1)
        projections = projections';
    end
    
    numModes = size(projections,2);
    parameters = project.parameters.wavelets;
    numProcessors = project.parameters.numProcessors;
    closeMatPool = project.parameters.closeMatPool;
    
    setup_parpool(numProcessors);

    
    
    omega0 = parameters.omega0;
    numPeriods = parameters.numPeriods;
    dt = 1 ./ parameters.samplingFreq;
    minT = 1 ./ parameters.maxF;
    maxT = 1 ./ parameters.minF;
    Ts = minT.*2.^((0:numPeriods-1).*log(maxT/minT)/(log(2)*(numPeriods-1)));
    f = fliplr(1./Ts);
    
    
    N = length(projections(:,1));
    amplitudes = zeros(N,numModes*numPeriods);
    for i=1:numModes
        amplitudes(:,(1:numPeriods)+(i-1)*numPeriods) = ...
            fastWavelet_morlet_convolution_parallel(...
            projections(:,i),f,omega0,dt)';
    end
    
    %normalize amplitudes by the sum of the amplitudes
    Frame_amps = sum(amplitudes,2);
    amplitudes = amplitudes./Frame_amps;

    
    if numProcessors > 1 && closeMatPool
        close_parpool
    end
    
    
    
    
    