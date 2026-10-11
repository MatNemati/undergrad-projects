%% Initialization
clear;
clc;
close all;

%% Preprocessing

% Dataset Path
% datasetPath = '16000_pcm_speeches';
datasetPath = fullfile('data', '16000_pcm_speeches');

% Load Speaker Folders
folders = dir(datasetPath);
speakerNames = {};

for i = 1:length(folders)
    if folders(i).isdir && ~startsWith(folders(i).name,'.')
        if ~strcmp(folders(i).name,'other') && ...
           ~strcmp(folders(i).name,'_background_noise_')
            speakerNames{end+1} = folders(i).name;
        end
    end
end

% Count Files For Each Speaker
fileCount = zeros(length(speakerNames),1);
for i = 1:length(speakerNames)
    speakerPath = fullfile(datasetPath,speakerNames{i});
    files = dir(fullfile(speakerPath,'*.wav'));
    fileCount(i) = length(files);
end

speakerTable = table(speakerNames',fileCount,...
    'VariableNames',{'Speaker','NumberOfFiles'});

disp(speakerTable)

% Read One Sample From Each Speaker
figure;
for i = 1:length(speakerNames)
    speakerPath = fullfile(datasetPath,speakerNames{i});
    files = dir(fullfile(speakerPath,'*.wav'));
    filePath = fullfile(speakerPath,files(1).name);
    [signal,Fs] = audioread(filePath);
    signal = signal(:,1);
    subplot(length(speakerNames),1,i)
    plot(signal)
    title(speakerNames{i})
    xlabel('Sample')
    ylabel('Amplitude')
end

% Display Sampling Frequency
disp('Sampling Frequency:')
disp(Fs)

% Select One Audio Sample
speakerPath = fullfile(datasetPath,speakerNames{1});
files = dir(fullfile(speakerPath,'*.wav'));
filePath = fullfile(speakerPath,files(1).name);

[x,Fs] = audioread(filePath);
x = x(:,1);

% Normalize Signal
x_norm = x / max(abs(x));

% Energy Based Silence Removal
frameLength = round(0.02*Fs);
hopLength = round(0.01*Fs);

energy = zeros(1,floor((length(x_norm)-frameLength)/hopLength)+1);


index = 1;
for i = 1:hopLength:length(x_norm)-frameLength+1
    frame = x_norm(i:i+frameLength-1);
    energy(index) = sum(frame.^2);
    index = index + 1;
end



threshold = 0.1 * max(energy);

activeFrames = find(energy > threshold);

startSample = max(1,(activeFrames(1)-1)*hopLength+1);
endSample = min(length(x_norm),...
    (activeFrames(end)-1)*hopLength+frameLength);
x_clean = x_norm(startSample:endSample);

% Plot Preprocessing Result

figure;
subplot(3,1,1)
plot(x)
title('Original Signal')
xlabel('Sample')
ylabel('Amplitude')

subplot(3,1,2)
plot(x_norm)
title('Normalized Signal')
xlabel('Sample')
ylabel('Amplitude')

subplot(3,1,3)
plot(x_clean)
title('Signal After Silence Removal')
xlabel('Sample')
ylabel('Amplitude')

% Audio Information
disp('Original Signal Length:')
disp(length(x))

disp('Processed Signal Length:')
disp(length(x_clean))

disp('Duration Before Processing:')
disp(length(x)/Fs)

disp('Duration After Processing:')
disp(length(x_clean)/Fs)

%% Feature Extraction

% Select one sample

speakerPath = fullfile(datasetPath,speakerNames{1});
files = dir(fullfile(speakerPath,'*.wav'));
filePath = fullfile(speakerPath,files(1).name);

[x,Fs] = audioread(filePath);
x = x(:,1);

% Normalization
x = x / max(abs(x));

% Frame Parameters
frameLength = round(0.02*Fs);
overlapLength = round(0.01*Fs);

% Framing and Windowing
frames = buffer(x,frameLength,overlapLength,'nodelay');
window = hamming(frameLength);
windowedFrames = frames .* window;

% MFCC Extraction
mfccFeatures = mfcc(x,Fs,...
    'Window',window,...
    'OverlapLength',overlapLength);

mfccMean = mean(mfccFeatures,1);
mfccStd = std(mfccFeatures,0,1);

% Energy Feature
frameEnergy = sum(windowedFrames.^2,1);
energyFeature = mean(frameEnergy);

% Zero Crossing Rate
zcr = zeros(1,size(windowedFrames,2));

for i = 1:size(windowedFrames,2)
    frame = windowedFrames(:,i);
    zcr(i) = sum(abs(diff(sign(frame))))/(2*length(frame));
end

zcrFeature = mean(zcr);

% Pitch Feature

pitchValues = pitch(x,Fs,...
    'WindowLength',frameLength,...
    'OverlapLength',overlapLength,...
    'Range',[50 400],...
    'Method','SRH');

pitchValues = pitchValues(~isnan(pitchValues));
pitchFeature = mean(pitchValues);

% Feature Vector
featureVector = [
    mfccMean ...
    mfccStd ...
    energyFeature ...
    zcrFeature ...
    pitchFeature
];

% Display Results
disp('MFCC Feature Size:')
disp(size(mfccFeatures))

disp('Feature Vector Length:')
disp(length(featureVector))

disp('Pitch Mean:')
disp(pitchFeature)

disp('Energy Mean:')
disp(energyFeature)

disp('ZCR Mean:')
disp(zcrFeature)

% MFCC Plot
figure;
imagesc(mfccFeatures')
axis xy
xlabel('Frame')
ylabel('Coefficient')
title('MFCC Features')
colorbar

% Pitch and Energy Plot
figure;
subplot(2,1,1)
plot(pitchValues)
title('Pitch')
xlabel('Frame')
ylabel('Frequency (Hz)')

subplot(2,1,2)
plot(frameEnergy)
title('Frame Energy')
xlabel('Frame')
ylabel('Energy')

%% Extract Features From All Speakers

features = [];
labels = [];

% Speaker Loop
for speakerID = 1:length(speakerNames)
    speakerPath = fullfile(datasetPath,speakerNames{speakerID});
    files = dir(fullfile(speakerPath,'*.wav'));
    disp(['Processing Speaker: ',speakerNames{speakerID}])

    % File Loop
    for fileID = 1:length(files)
        filePath = fullfile(speakerPath,files(fileID).name);
        [x,Fs] = audioread(filePath);
        x = x(:,1);

        % Normalization
        x = x / max(abs(x));

        % Frame Parameters
        frameLength = round(0.02*Fs);
        overlapLength = round(0.01*Fs);

        % Windowing
        frames = buffer(x,frameLength,overlapLength,'nodelay');
        window = hamming(frameLength);
        windowedFrames = frames .* window;

        % MFCC
        mfccFeatures = mfcc(x,Fs,...
            'Window',window,...
            'OverlapLength',overlapLength);

        mfccMean = mean(mfccFeatures,1);
        mfccStd = std(mfccFeatures,0,1);

        % Energy
        frameEnergy = sum(windowedFrames.^2,1);
        energyFeature = mean(frameEnergy);

        % ZCR
        zcr = zeros(1,size(windowedFrames,2));
        for k = 1:size(windowedFrames,2)
            frame = windowedFrames(:,k);
            zcr(k) = sum(abs(diff(sign(frame))))/(2*length(frame));
        end
        zcrFeature = mean(zcr);

        % Pitch
        pitchValues = pitch(x,Fs,...
            'WindowLength',frameLength,...
            'OverlapLength',overlapLength,...
            'Range',[50 400],...
            'Method','SRH');
        pitchValues = pitchValues(~isnan(pitchValues));
        pitchFeature = mean(pitchValues);

        % Feature Vector
        featureVector = [
            mfccMean ...
            mfccStd ...
            energyFeature ...
            zcrFeature ...
            pitchFeature
        ];

        % Save Data
        features = [features; featureVector];
        labels = [labels; speakerID];
    end
end

% Dataset Information
disp('Feature Matrix Size:')
disp(size(features))
disp('Label Vector Size:')
disp(size(labels))
disp('Number Of Samples:')
disp(length(labels))

%% Dataset Split and Cross Validation

% Feature normalization
X = normalize(features);

% Train and test split
cv = cvpartition(labels,'HoldOut',0.2);
trainIndex = training(cv);

testIndex = test(cv);

X_train = X(trainIndex,:);
Y_train = labels(trainIndex);

X_test = X(testIndex,:);
Y_test = labels(testIndex);

% K-fold cross validation
kFold = cvpartition(Y_train,...
    'KFold',5);

% Display information
disp('Training Data Size:')
disp(size(X_train))
disp('Training Labels Size:')
disp(size(Y_train))
disp('Testing Data Size:')
disp(size(X_test))
disp('Testing Labels Size:')
disp(size(Y_test))
disp('Number of Cross Validation Folds:')
disp(kFold.NumTestSets)

%% KNN Classification
kValues = [1 3 5 7 9 11];
accuracyKNN = zeros(length(kValues),1);

for i = 1:length(kValues)
    knnModel = fitcknn(X_train,Y_train,...
        'NumNeighbors',kValues(i),...
        'Standardize',true);
    prediction = predict(knnModel,X_test);
    accuracyKNN(i) = mean(prediction == Y_test) * 100;
end

% Display KNN Results
knnTable = table(kValues',accuracyKNN,...
    'VariableNames',{'K','Accuracy'});

disp(knnTable)

% Select Best K
[bestAccuracy,bestIndex] = max(accuracyKNN);
bestK = kValues(bestIndex);

disp('Best K:')
disp(bestK)
disp('Best Accuracy:')
disp(bestAccuracy)

% Confusion Matrix
bestKNNModel = fitcknn(X_train,Y_train,...
    'NumNeighbors',bestK,...
    'Standardize',true);

knnPrediction = predict(bestKNNModel,X_test);

figure;
confusionchart(Y_test,knnPrediction)
title('KNN Confusion Matrix')

% Accuracy Plot
figure;
plot(kValues,accuracyKNN,'-o')
xlabel('K Value')
ylabel('Accuracy (%)')
title('KNN Accuracy For Different K Values')
grid on

%% SVM Classification
svmModel = fitcecoc(X_train,Y_train,...
    'Learners','linear',...
    'Coding','onevsone');

svmPrediction = predict(svmModel,X_test);
svmAccuracy = mean(svmPrediction == Y_test) * 100;

% Display SVM Result
disp('SVM Accuracy:')
disp(svmAccuracy)

% Confusion Matrix
figure;
confusionchart(Y_test,svmPrediction)
title('SVM Confusion Matrix')

%% Performance Evaluation Metrics

% Confusion Matrix Values
cm = confusionmat(Y_test,svmPrediction);
numClasses = size(cm,1);
precision = zeros(numClasses,1);
recall = zeros(numClasses,1);
f1Score = zeros(numClasses,1);

for i = 1:numClasses
    TP = cm(i,i);
    FP = sum(cm(:,i)) - TP;
    FN = sum(cm(i,:)) - TP;
    precision(i) = TP / (TP + FP);
    recall(i) = TP / (TP + FN);
    f1Score(i) = 2 * ...
        (precision(i)*recall(i)) / ...
        (precision(i)+recall(i));
end



% Average Metrics
meanPrecision = mean(precision)*100;
meanRecall = mean(recall)*100;
meanF1 = mean(f1Score)*100;

disp('Precision:')
disp(meanPrecision)
disp('Recall:')
disp(meanRecall)
disp('F1-Score:')
disp(meanF1)

% Display Metric Table
metricTable = table(meanPrecision,...
    meanRecall,...
    meanF1,...
    'VariableNames',...
    {'Precision','Recall','F1_Score'});

disp(metricTable)


%% Frequency Domain Analysis
selectedSpeakers = {
    'Benjamin_Netanyau'
    'Jens_Stoltenberg'
    'Nelson_Mandela'
};

% FFT Spectrum
figure;
for i = 1:length(selectedSpeakers)
    speakerPath = fullfile(datasetPath,selectedSpeakers{i});
    files = dir(fullfile(speakerPath,'*.wav'));
    filePath = fullfile(speakerPath,files(1).name);
    [x,Fs] = audioread(filePath);
    x = x(:,1);
    x = x / max(abs(x));
    N = length(x);
    X = fft(x);
    magnitude = abs(X/N);
    frequency = Fs*(0:N-1)/N;

    subplot(3,1,i)
    plot(frequency(1:floor(N/2)),...
        magnitude(1:floor(N/2)))
    xlabel('Frequency (Hz)')
    ylabel('Magnitude')
    title(selectedSpeakers{i})
    grid on
end



% Spectrogram
figure;
for i = 1:length(selectedSpeakers)
    speakerPath = fullfile(datasetPath,selectedSpeakers{i});
    files = dir(fullfile(speakerPath,'*.wav'));
    filePath = fullfile(speakerPath,files(1).name);
    [x,Fs] = audioread(filePath);
    x = x(:,1);
    x = x / max(abs(x));

    subplot(3,1,i)
    spectrogram(x,...
        hamming(round(0.02*Fs)),...
        round(0.01*Fs),...
        512,...
        Fs,...
        'yaxis')
    title(selectedSpeakers{i})
end


disp('Sampling Frequency:')
disp(Fs)
