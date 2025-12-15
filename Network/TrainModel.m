%% Train Dataset
clc; clear all; close all;

restoredefaultpath
addpath(genpath(fullfile(pwd, 'Dataset/Answers')));

datasetPath = fullfile(pwd, 'Dataset/Answers');
imds = imageDatastore(datasetPath,'IncludeSubfolders',true,'LabelSource','foldernames');

img = readimage(imds,1);
size(img);
labelCount = countEachLabel(imds);

numTrainFiles = 10000;
[imdsTrain,imdsValidation] = splitEachLabel(imds,numTrainFiles,'randomize');

layers = [
    imageInputLayer([81 81 1])

    convolution2dLayer(11,3,'Stride',4,'Padding','same')
    batchNormalizationLayer
    reluLayer

    convolution2dLayer(5,96,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(4,'Stride',2)

    convolution2dLayer(3,256,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,384,'Padding','same')
    batchNormalizationLayer
    reluLayer

    convolution2dLayer(3,384,'Padding','same')
    batchNormalizationLayer
    reluLayer

    convolution2dLayer(1,256,'Padding','same')
    batchNormalizationLayer
    reluLayer

    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer];

options = trainingOptions('sgdm', ...
    'InitialLearnRate',0.01, ...
    'MaxEpochs',100, ...
    'Shuffle','every-epoch', ...
    'ValidationData',imdsValidation, ...
    'ValidationFrequency',30, ...
    'Verbose',false, ...
    'Plots','training-progress');

net = trainNetwork(imdsTrain,layers,options);

save net imdsValidation

YPred = classify(net,imdsValidation);
YValidation = imdsValidation.Labels;

accuracy = sum(YPred == YValidation)/numel(YValidation)