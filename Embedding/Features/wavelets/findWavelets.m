function [amplitudes,f] = findWavelets(projections,numModes,project)
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

    
   
    numModes = length(projections(1,:));
    parameters = project.parameters.wavelets;

    setup_parpool(parameters.numProcessors)

    
    
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
    
    
    if parameters.numProcessors > 1 && parameters.closeMatPool
        close_parpool
    end
    
    
    
    
    