All the code for my master's thesis exists here. The presentation and videos for each of the different behaviors have also been uploaded.

Everything is organized around a project class and a parameter dictionary.

The project class handles all the data and model tracking for individual use cases. The parameter dictionary is coupled with the project class to implement all the different parameter changes for the models one wants. All this will be updated as the project continues. 


Currently working is:
-Autoencoder Reconstruction
-Autoencoder Preprocessing
-Autoencoder Training

Next steps are:
-Feature Extraction (Somehow couple this with an excel sheet?)
	-Parameter changes (filtering, etc...)
-Embedding (Decision between autoencoder, tsne, or umap would be nice, for now we can just go with tsne)
-Pick a reembeding method (everything will be defaulted to what I used for my masters thesis)
-Embed all sleap files and make movies
 -Movie handling will be a big undertaking. How do we want to handle tracking the corresponding mp4's... Currently we are relying on the mp4 output filenames for tracking, that should continue to work. 
-Integration with fiber photometry
-Plotting functionality
-TACI integration
