%% Recall Precision Curve
clc; close all; clear all;

load('Network.mat')
load('Testdata.mat')

% [YPred, err, posterior, logp, coeff] = classify(net,imdsValidation);
% [class,err] = classify(net,imdsValidation);

Threshold = 0.5;
YPred = Prob(:,1)>=Threshold;
YTruth = (YValidation == "Bubble");

TP = sum(YPred(1:2982) == YTruth(1:2982))/2982;
TN = sum(YPred(2982:end) == YTruth(2982:end))/17113;
FP = sum(YPred(1:2982) ~= YTruth(1:2982))/2982;
FN = sum(YPred(2982:end) ~= YTruth(2982:end))/17113;

recall = TP/(TP+FN);
precision = TP/(TP+FP);

[X,Y,T,AUC] = perfcurve(YValidation,Prob(:,1),'Bubble');

figure(1)
plot(X,Y,'Linewidth',1.5);

title('ROC for Answer Bubbles')
xlabel('False Positive Rate')
ylabel('True Positive Rate')


