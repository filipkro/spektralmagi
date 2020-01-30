% https://kenschutte.com/midi


%%
%midi = readmidi("/Users/erikstalberg/Documents/1Studier/Spektralanalys/project/score/correct.mid");
midi = readmidi("correct.mid");
notes = midiInfo(midi,0);

notesFreq = notes;
notesFreq(:,3) = midi2freq(notes(:,3));

qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2);

%%
notesSep = unique(notesFreq(:,5));
notesSep = [notesSep zeros(length(notesSep),5)];

notesRow = 1;
for row=1:length(notesFreq)
    if notesFreq(row,5) ~= notesSep(notesRow,1)
        notesRow = notesRow+1;
    end
    channel = notesFreq(row,1)+1;
    notesSep(notesRow,channel) = notesFreq(row,3);
end

%%
figure
hold on
for ch=2:6
    scatter(notesSep(:,1), notesSep(:,ch), ".")
end
set(gca, 'YScale', 'log')
%title("Iostorum anime");
ylabel("Frequency [Hz]");
xlabel("Time [s]");


%% compute piano-roll:
[PR,t,nn] = piano_roll(notes);

%% display piano-roll:
figure;
imagesc(t,nn,PR);
axis xy;
xlabel('time (sec)');
ylabel('note number');

%% also, can do piano-roll showing velocity:
[PR,t,nn] = piano_roll_channel(notes,1);

figure;
imagesc(t,midi2freq(nn),PR);
axis xy;
xlabel('Time [s]');
ylabel('Frequency [Hz]');
set(gca, 'YScale', 'log')
axis tight

%%

[mp3sine sampleRate] = audioread("sine.wav");
mp3sine = mean(mp3sine,2);

[mp3voice sampleRate] = audioread("voice.wav");
mp3voice = mean(mp3voice,2);
%%
window = sampleRate*0.75/2;

%%
S = spectrogram(mp3sine(:,1),window,0,500,sampleRate);

%%
figure
subplot(121)
spectrogram(mp3sine(:,1),window,0,sampleRate,sampleRate, 'yaxis')
axis([0 1.8 0 0.5])
title("Sine waves")
subplot(122)
spectrogram(mp3voice(:,1),window,0,sampleRate,sampleRate, 'yaxis')
axis([0 1.8 0 0.5])
title("MIDI voices")
%%
figure
plot(abs(S(:,10)))

%%
txtcor(:,1) = audioread("txtcor1.wav");
txtcor(:,2) = audioread("txtcor2.wav");
txtcor(:,3) = audioread("txtcor3.wav");
txtcor(:,4) = audioread("txtcor4.wav");
txtcor(:,5) = audioread("txtcor5.wav");

%%
%      
amp = [1.3 1 1.1 1.3 1.2]; % Amplification
txtcor(:,6) = sum(amp.*txtcor(:,1:5),2);
fs = 44100;

%%
soundsc(txtcor(:,6), fs);

%%
figure
spectrogram(txtcor(:,6),fs*0.02,[],20000,fs,'yaxis')
axis([0 1.1 0 2])


%%


%%
simulatedAudio = simulateMicSetup(txtcor(:,1:5),fs,2*circularDistribution(5),circularDistribution(3),1);

%%
