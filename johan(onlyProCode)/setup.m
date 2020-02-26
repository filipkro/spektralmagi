% add everything here that needs to be initialized!
% this script adds all the paths, sets fs, reads files and midinotes
%
% NOTE: set your own dsfactor and downsample with decimate after running
% this script!
% 

addpath(genpath("../")); % add parent directory 
fs = 44100;

clear txtcor naacor txtinc naainc
for ch=1:5
    txtcor(:,ch) = audioread(sprintf("/recordings/txtcor%i.wav",ch));
    naacor(:,ch) = audioread(sprintf("/recordings/naacor%i.wav",ch));
    txtinc(:,ch) = audioread(sprintf("/recordings/txtinc%i.wav",ch));
    naainc(:,ch) = audioread(sprintf("/recordings/naainc%i.wav",ch));
end

midi = readmidi("score/correct.mid");
midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin

























