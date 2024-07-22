function trainAuto(project)

project.parameters.autoenc.module.trainmodel(project.trainingsetpath, project.parameters.autoenc.features_means_path, project.modelpath)