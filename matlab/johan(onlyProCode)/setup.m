% add everything here that needs to be initialized!
% this script adds all the paths, sets fs, reads files and midinotes. It
% also exctracts the valuable information from midinotes (stored in
% "midiNoTrash") and also divide midiNoTrash into 5 matrices, 1 matrix with
% information for each singing voice
%
% NOTE: set your own dsfactor and downsample with decimate after running
% this script! This will allow you to play around as you like with the
% original recordings. 
% 

addpath(genpath("../")); % add parent directory 
fs = 44100;

% 
clear txtcor naacor txtinc naainc
for ch=1:5
    txtcor(:,ch) = audioread(sprintf("/recordings/txtcor%i.wav",ch));
    naacor(:,ch) = audioread(sprintf("/recordings/naacor%i.wav",ch));
    txtinc(:,ch) = audioread(sprintf("/recordings/txtinc%i.wav",ch));
    naainc(:,ch) = audioread(sprintf("/recordings/naainc%i.wav",ch));
end

midi = readmidi("score/correct.mid");
midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3; % song starts at time t = 3 seconds, not t = 0
midinotes(:,3) = midi2freq(midinotes(:,3)); % midi notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin

midiNoTrash = midinotes(:, [1 3 5 6]);
midinotesVoice1 = zeros(51,3);
midinotesVoice2 = zeros(52,3);
midinotesVoice3 = zeros(52,3);
midinotesVoice4 = zeros(54,3);
midinotesVoice5 = zeros(51,3);
currentRow1 = 1;
currentRow2 = 1;
currentRow3 = 1;
currentRow4 = 1;
currentRow5 = 1;

for i = 1:length(midiNoTrash)
    
    if midiNoTrash(i,1) == 1
        midinotesVoice1(currentRow1,:) = midiNoTrash(i,2:end);
        currentRow1 = currentRow1 + 1;
    elseif midiNoTrash(i,1) == 2
        midinotesVoice2(currentRow2,:) = midiNoTrash(i,2:end);
        currentRow2 = currentRow2 + 1;
    elseif midiNoTrash(i,1) == 3
        midinotesVoice3(currentRow3,:) = midiNoTrash(i,2:end);
        currentRow3 = currentRow3 + 1;
    elseif midiNoTrash(i,1) == 4
        midinotesVoice4(currentRow4,:) = midiNoTrash(i,2:end);
        currentRow4 = currentRow4 + 1;
    elseif midiNoTrash(i,1) == 5
        midinotesVoice5(currentRow5,:) = midiNoTrash(i,2:end);
        currentRow5 = currentRow5 + 1;
    end
    
end












