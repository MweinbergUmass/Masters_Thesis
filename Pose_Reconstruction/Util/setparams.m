function params = setparams()

params.autoenc.module = py.importlib.import_module('TC_Auto');
params.autoenc.model = 'TCONV'; %Can also be MLP
if strcmpi(params.autoenc.model, 'TCONV')
    params.autoenc.path = 'Models/conv_autoencoder_model.h5';
    params.autoenc.sequence_length = 15;
elseif strcmpi(params.autoenc.model, 'MLP')
    params.autoenc.path = 'Models/autoencoder_model.h5';
    params.autoenc.sequence_length = nan;
else 
    error('Need to pick either TCONV or MLP for the autoencoder model. TCONV = temporal convolution, MLP = regular symmetric autoencoder')
end

