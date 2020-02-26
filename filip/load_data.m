

for ch=1:5
    txtcor(:,ch) = decimate(audioread(sprintf("/recordings/txtcor%i.wav",ch)), dsfactor);
    naacor(:,ch) = decimate(audioread(sprintf("/recordings/naacor%i.wav",ch)), dsfactor);
    txtinc(:,ch) = decimate(audioread(sprintf("/recordings/txtinc%i.wav",ch)), dsfactor);
    naainc(:,ch) = decimate(audioread(sprintf("/recordings/naainc%i.wav",ch)), dsfactor);
end

midi = readmidi("project/score/correct.mid");

midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin
