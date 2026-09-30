clc;
clear;
close all;

%% Load Files and Filter

dataFolder = 'data';
fs = 1000;

% Butterworth bandpass filter parameters
lowCutoff = 20;
highCutoff = 450;
filterOrder = 2;
[b, a] = butter(filterOrder, [lowCutoff, highCutoff] / (fs / 2), 'bandpass');

% Number of classes and trials
numClasses = 2;
numTrials = 10;

% Initialize storage for filtered signals
filteredSignals = zeros(numClasses, numTrials, 31000); % 31000 samples per trial

for classIdx = 1:numClasses
    for trialIdx = 1:numTrials
        % Generate file name
        fileName = sprintf('class_%d_trial_%d.mat', classIdx, trialIdx);
        filePath = fullfile(dataFolder, fileName);

        % Load data
        data = load(filePath);
        rawSignal = data.ch;

        % Filter the signal
        filteredSignal = filtfilt(b, a, rawSignal);

        % Store filtered signal
        filteredSignals(classIdx, trialIdx, :) = filteredSignal;
    end
end

% Remove Mean to Signals
for classIdx = 1:numClasses
    for trialIdx = 1:numTrials
        filteredSignals(classIdx, trialIdx, :) = filteredSignals(classIdx, trialIdx, :) - mean(filteredSignals(classIdx, trialIdx, :));
    end
end

%% Creating 100 signals for each class

% Extract Middle 10 Seconds
middleSignals = zeros(numClasses, numTrials, 10000); % 10,000 samples for 10 seconds

for classIdx = 1:numClasses
    for trialIdx = 1:numTrials
        middleSignals(classIdx, trialIdx, :) = filteredSignals(classIdx, trialIdx, 11001:21000);
    end
end

% Split Each 10-Second Signal into 1-Second Segments
numSegments = 10; % 10 segments of 1 second each
segmentLength = fs; % 1000 samples per second

class1Signals = zeros(100, segmentLength); % 100 signals for class 1
class2Signals = zeros(100, segmentLength); % 100 signals for class 2

for classIdx = 1:numClasses
    signalCounter = 1;
    for trialIdx = 1:numTrials
        for segmentIdx = 1:numSegments
            startIdx = (segmentIdx - 1) * segmentLength + 1;
            endIdx = segmentIdx * segmentLength;

            if classIdx == 1
                class1Signals(signalCounter, :) = middleSignals(classIdx, trialIdx, startIdx:endIdx);
            else
                class2Signals(signalCounter, :) = middleSignals(classIdx, trialIdx, startIdx:endIdx);
            end

            signalCounter = signalCounter + 1;
        end
    end
end

%% Ploting

%% Feature Extraction

featuresClass1 = zeros(100, 6);
featuresClass2 = zeros(100, 6);

for i = 1:100
    % features for Class 1
    signal1 = class1Signals(i, :);
    featuresClass1(i, 1) = var(signal1); % Variance
    featuresClass1(i, 2) = max(signal1); % Maximum value
    featuresClass1(i, 3) = mean(signal1); % Mean value
    featuresClass1(i, 4) = sum(signal1 .^ 2); % Energy
    featuresClass1(i, 5) = max(signal1) / var(signal1); % Max / Variance
    featuresClass1(i, 6) = sum(diff(signal1 > 0)); % Zero crossings

    % features for Class 2
    signal2 = class2Signals(i, :);
    featuresClass2(i, 1) = var(signal2); % Variance
    featuresClass2(i, 2) = max(signal2); % Maximum value
    featuresClass2(i, 3) = mean(signal2); % Mean value
    featuresClass2(i, 4) = sum(signal2 .^ 2); % Energy
    featuresClass2(i, 5) = max(signal2) / var(signal2); % Max / Variance
    featuresClass2(i, 6) = sum(diff(signal2 > 0)); % Zero crossings
end

% Scatter Plots
featureNames = {'Variance', 'Max', 'Mean', 'Energy', 'Max/Variance', 'Zero Crossing'};

figure;
for featureIdx = 1:6
    subplot(2, 3, featureIdx);
    scatter(featuresClass1(:, featureIdx), zeros(100, 1), 'o', 'filled'); % Class 1 (circles)
    hold on;
    scatter(featuresClass2(:, featureIdx), ones(100, 1), 's', 'filled'); % Class 2 (squares)
    title(featureNames{featureIdx});
    xlabel('Feature Value');
    ylabel('Class');
    legend('Class 1', 'Class 2');
    grid on;
end

sgtitle('Feature Distributions for Class 1 and Class 2');


%% Feature Selection

% Selecting features: Maximum (column 2) and Energy (column 4)
selectedFeaturesClass1 = featuresClass1(:, [2, 4]);
selectedFeaturesClass2 = featuresClass2(:, [2, 4]);

% Add class labels
labeledFeaturesClass1 = [selectedFeaturesClass1, ones(100, 1)]; % Class 1 label: 1
labeledFeaturesClass2 = [selectedFeaturesClass2, ones(100, 1) * 2]; % Class 2 label: 2

% Combine all features
allFeatures = [labeledFeaturesClass1; labeledFeaturesClass2];

% % Scatter Plot for Selected Features
% figure;
% scatter(selectedFeaturesClass1(:, 1), selectedFeaturesClass1(:, 2), 'o', 'filled'); % Class 1 with circles
% hold on;
% scatter(selectedFeaturesClass2(:, 1), selectedFeaturesClass2(:, 2), '^', 'filled'); % Class 2 with triangles
% title('Scatter Plot of Selected Features');
% xlabel('Feature 1 (Max)');
% ylabel('Feature 2 (Energy)');
% legend('Class 1', 'Class 2');
% grid on;



%% KNN Classification with 5-Fold Cross-Validation
k = 7; % for KNN
numFolds = 5;
indices = crossvalind('Kfold', allFeatures(:, end), numFolds); % Generate indices for 5-fold cross-validation
classificationErrors = zeros(numFolds, 1); % Store errors for each fold

for foldIdx = 1:numFolds
    % Split data into training and testing
    testIdx = (indices == foldIdx);
    trainIdx = ~testIdx;

    trainData = allFeatures(trainIdx, 1:2); % Features for training
    trainLabels = allFeatures(trainIdx, 3); % Labels for training
    testData = allFeatures(testIdx, 1:2); % Features for testing
    testLabels = allFeatures(testIdx, 3); % Labels for testing

    % Perform KNN classification
    numTestSamples = size(testData, 1);
    predictedLabels = zeros(numTestSamples, 1);

    for testSampleIdx = 1:numTestSamples
        % distances
        distances_euclidean = sqrt(sum((trainData - testData(testSampleIdx, :)).^2, 2));
        distances_manhattan = sum(abs(trainData - testData(testSampleIdx, :)), 2);
        p = 3;
        distances_minkowski = sum(abs(trainData - testData(testSampleIdx, :)).^p, 2).^(1/p);
        % Select distance metric 
        distances = distances_euclidean;

        % Sort distances
        [sortedDistances, sortedIndices] = sort(distances);

        % Find the k nearest 
        kNearestLabels = trainLabels(sortedIndices(1:k));

        % Assign the most label
        predictedLabels(testSampleIdx) = mode(kNearestLabels);
    end

    % Calculate classification error for this fold
    classificationErrors(foldIdx) = mean(predictedLabels ~= testLabels);
end

%% results

% Compute average classification error across all folds
averageError = mean(classificationErrors);

% Compute accuracy for each fold
classificationAccuracy = 1 - classificationErrors;


disp('Classification errors for each fold:');
disp(classificationErrors');
disp(['Average classification error: ', num2str(averageError)]);
disp('Classification accuracy for each fold:');
disp(classificationAccuracy');
disp(['Average classification accuracy: ', num2str(mean(classificationAccuracy))]);

%% Phase 2: Using MATLAB Built-in Classifier
% Perform classification using MATLAB built-in functions and compare accuracies

% Prepare data for MATLAB classifier
features = allFeatures(:, 1:2); % Selected features (columns 1 and 2)
labels = allFeatures(:, 3); % Class labels (column 3)

% MATLAB built-in KNN classifier with 5-fold cross-validation
k = 7; % Number of neighbors
mdl = fitcknn(features, labels, 'NumNeighbors', k); % Create KNN model
cvmdl = crossval(mdl, 'KFold', numFolds); % Cross-validation model

% Calculate accuracy
builtInAccuracy = 1 - kfoldLoss(cvmdl);

% Display results
fprintf('\n--- Phase 2: MATLAB Built-in Classifier ---\n');
fprintf('Classification accuracy using MATLAB built-in KNN: %.2f%%\n', builtInAccuracy * 100);

%% Comparison of Results
fprintf('\n--- Comparison of Results ---\n');
manualAverageAccuracy = mean(classificationAccuracy) * 100;
fprintf('Manual KNN Average Accuracy: %.2f%%\n', manualAverageAccuracy);
fprintf('MATLAB Built-in KNN Accuracy: %.2f%%\n', builtInAccuracy * 100);

if manualAverageAccuracy > builtInAccuracy * 100
    fprintf('Manual implementation performed better by %.2f%%.\n', manualAverageAccuracy - builtInAccuracy * 100);
elseif manualAverageAccuracy < builtInAccuracy * 100
    fprintf('MATLAB built-in implementation performed better by %.2f%%.\n', builtInAccuracy * 100 - manualAverageAccuracy);
else
    fprintf('Both implementations performed equally well.\n');
end
