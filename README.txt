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

**
Currently working on this. It should work by having some modular function which just computes features.

-Train Embedding
	-Compute features for all datasets (done)
	-Persistent variable for tracking minmaxdata (done (changed to just saving it in the parameters))
(I'm imagining a func which looks something like train_embedding(project), which computes all the nescessary features)
train_embedding(project) 
	-Compute all features 
		-Find all proc_mice file, load it, for each:
			-compute features
			-update minmaxdata
			-update length cell array which is somehow coupled to the proc_mice_file (maybe use file registry for this?) (Done, used file registry for this)
			-save the data

			
			**
			Working Here!
		-Training subsampling procedure such that I grab only certain subsets of files
		-Normalize using minmaxdata
		-Compute Distance Matrix
		-Run tsne
		-Train Test Split
		-Train MLP to reembed
	mkdir in data folder for the project called Embeddingdata
	Embeddingdata
		-minmaxdata
		-MLP
		-Distance Matrix
		-Train Test Split
		-Features for Distance Matrix
return 0

**

-Embedding (Decision between autoencoder, tsne, or umap would be nice, for now we can just go with tsne)
-Pick a reembeding method (everything will be defaulted to what I used for my masters thesis)
-Embed all sleap files and make movies
 -Movie handling will be a big undertaking. How do we want to handle tracking the corresponding mp4's... Currently we are relying on the mp4 output filenames for tracking, that should continue to work. 
-Integration with fiber photometry
-Plotting functionality
-TACI integration
