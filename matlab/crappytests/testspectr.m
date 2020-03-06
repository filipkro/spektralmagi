clear all
close all

run paths.m
%%
midi = readmidi("correct.mid");
notes = midiInfo(midi,0);
notesFreq = notes;
notesFreq(:,3) = midi2freq(notes(:,3));
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2);

%%
[mp3sine sampleRate] = audioread("sine.wav");
mp3sine = mean(mp3sine,2);
%%
[mp3voice sampleRate] = audioread("voice.wav");
mp3voice = mean(mp3voice,2);
%%
soundsc(mp3sine, sampleRate)

%%
txtcor(:,1) = audioread("txtcor1.wav");
txtcor(:,2) = audioread("txtcor2.wav");
txtcor(:,3) = audioread("txtcor3.wav");
txtcor(:,4) = audioread("txtcor4.wav");
txtcor(:,5) = audioread("txtcor5.wav");
 
amp = [1.3 1 1.1 1.3 1.2]; % Amplification
txtcor(:,6) = sum(amp.*txtcor(:,1:5),2);
fs = 44100;
%%
soundsc(txtcor(:,6), fs)


%%
figure
plot(txtcor(:,4))
%%
w_length = 0.02;
i_start = 500000;
s = txtcor(i_start:i_start+w_length*fs,4);
sh = hilbert(s);
N = length(s);
figure
plot(s)

P = 1024;
ff  = (0:P-1)/P-.5;                     % Frequency grid.
Y = fftshift( abs(fft(s, P))/N ).^2;
SS = fftshift( abs(fft(sh, P))/N ).^2;

figure
semilogy(ff*fs,Y)
figure
semilogy(ff*fs,SS)


[fRELAX, sRELAX] = relax(sh,3);
fRELAX = fs*fRELAX/2/pi



%%
figure
spectrogram(txtcor(:,4),fs*0.02,[],20000,fs,'yaxis')


%% downsampled

ch4d = decimate(txtcor(:,4),5);
fsd = fs/5;

w_length = 0.02;
i_start = 100000;
s = ch4d(i_start:i_start+w_length*fsd);
N = length(s);
figure
plot(s)

P = 1024;
ff  = (0:P-1)/P-.5;                     % Frequency grid.
Y = fftshift( abs(fft(s, P))/N ).^2;

figure
semilogy(ff*fsd,Y)