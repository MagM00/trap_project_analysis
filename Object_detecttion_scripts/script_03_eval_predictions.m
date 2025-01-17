%% Preamble
% This script will evaluate the label predictions
% load configs
global GC
GC = general_configs();

% Load predictions
% if ispc
%     rootpath =  'C:\Users\acuna\OneDrive - Universitaet Bern\Coding_playground\Anna_playground\';
% else
%     rootpath = '/Users/marioacuna/Library/CloudStorage/OneDrive-UniversitaetBern/Coding_playground/Anna_playground';
% end

[prediction_names , predictions_loc] = uigetfile('.mat', 'predictions', 'H:\Mario\BioMed_students_2023\Anna\TRAP experiment\stimuli_detected');
% predictions_filename = 'detected_labels_v3.mat';
predictions_fullname = fullfile(predictions_loc, prediction_names);
load(predictions_fullname);

%% Evaluate predictions
% Load ground truth
% gtruth_filename = fullfile(rootpath, 'groundTruth.xlsx');
% gtruth = readtable(gtruth_filename);

% Initialize variables
startFrame = 1000; % Starting frame for analysis
emptyFramesThreshold = 20; % Threshold for empty frames between groups
minimumDurationThreshold = 15; % Minimum duration for a label to be considered valid
currentGroup = [];
currentGroupFrames = []; % To keep track of frame numbers for the current group
groupedLabels = {};
groupedFrames = {}; % To keep track of frame numbers for each grouped label

emptyFramesCounter = 0; % Counter for consecutive empty frames
currentGroupDuration = 0; % Counter for the duration of the current group

% Loop through the detected labels starting from the specified frame
for i = startFrame:length(detectedLabels)
    if ~isempty(detectedLabels{1,i})
        % Reset empty frames counter and add label and frame number to current group
        emptyFramesCounter = 0;
        currentGroup = [currentGroup, detectedLabels{1,i}];
        currentGroupFrames = [currentGroupFrames, detectedLabels{2,i}]; % Store frame number
        currentGroupDuration = currentGroupDuration + 1; % Increment duration
    else
       % Increment empty frames counter
       emptyFramesCounter = emptyFramesCounter + 1;
       if emptyFramesCounter > emptyFramesThreshold && ~isempty(currentGroup)
           % Check if current group duration meets minimum duration threshold
           if currentGroupDuration >= minimumDurationThreshold
               % Process and reset group if threshold is exceeded
               mostFrequentLabel = mode(currentGroup);
               mostFrequentLabelIndex = find(currentGroup == mostFrequentLabel, 1, 'first'); % Find index of most frequent label
               lastFrameOfGroup = max(currentGroupFrames); % Find the last frame of the current group
               frameBeforeLast = max(1, lastFrameOfGroup - 30); % Calculate the frame 1 seconds before the last frame (at 30Hz)

               % Ensure the frame number isn't less than the first frame of the video
               frameOfInterest = max(startFrame, frameBeforeLast);

               groupedLabels{end+1} = mostFrequentLabel;
               groupedFrames{end+1} = frameOfInterest; % Store the frame of interest
           end
           % Reset current group, its duration, and frame numbers
           currentGroup = [];
           currentGroupFrames = [];
           currentGroupDuration = 0;
           emptyFramesCounter = 0;
       end
    end
end

% Process the last group if it wasn't processed inside the loop
if ~isempty(currentGroup) && currentGroupDuration >= minimumDurationThreshold
    mostFrequentLabel = mode(currentGroup);
    mostFrequentLabelIndex = find(currentGroup == mostFrequentLabel, 1, 'first'); % Find index of most frequent label
    frameOfMostFrequentLabel = currentGroupFrames(mostFrequentLabelIndex); % Frame number of most frequent label
    groupedLabels{end+1} = mostFrequentLabel;
    groupedFrames{end+1} = frameOfMostFrequentLabel;
end

predicted_labels = groupedLabels';
predicted_frames = groupedFrames';

% Extract all the categorical labels inside each cell inside the cell array
predicted_labels = cellfun(@(x) x(1), predicted_labels, 'UniformOutput', true);
predicted_frames = cellfun(@(x) x(1), predicted_frames, 'UniformOutput', true);

% % Plot the diff of the frames
% diff_frames = diff(predicted_frames)./30;
% figure; plot(diff_frames); title('Diff of frames');
% xlabel('Stimulation number'); ylabel('Diff between stim in seconds');

%% Save csv
% Initialize the table with 'None' or empty strings for all frames
numFrames = length(detectedLabels); % Total number of frames
frameNumbers = (1:numFrames)'; % Column vector of frame numbers
labels = repmat({''}, numFrames, 1); % Cell array of empty strings for labels

% Assign the predicted labels to the corresponding frames
for i = 1:length(predicted_frames)
    frameIdx = predicted_frames(i); % Extract the frame index
    if frameIdx <= numFrames
        labels{frameIdx} = char(predicted_labels(i)); % Assign the label
    end
end

% Create the table
resultsTable = table(frameNumbers, labels, 'VariableNames', {'Frame', 'Label'});




outputFileName = [prediction_names, '.csv'];
outputFullPath = fullfile(predictions_loc, 'Yolo_predictions', outputFileName);

% Check if the output folder exists, if not, create it
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Write the table to a CSV file
writetable(resultsTable, outputFullPath);

disp(['Done writing for ', outputFullPath])
