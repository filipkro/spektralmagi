%% Preparation
addpath(genpath("../")); % add parent directory 
fs = 44100;
dsfactor = 10; % multiple of 2
fs = fs/dsfactor;

%% Loads data
clear txtcor naacor txtinc naainc
for ch=1:5
    txtcor(:,ch) = decimate(audioread(sprintf("/recordings/txtcor%i.wav",ch)), dsfactor);
    naacor(:,ch) = decimate(audioread(sprintf("/recordings/naacor%i.wav",ch)), dsfactor);
    txtinc(:,ch) = decimate(audioread(sprintf("/recordings/txtinc%i.wav",ch)), dsfactor);
    naainc(:,ch) = decimate(audioread(sprintf("/recordings/naainc%i.wav",ch)), dsfactor);
end

%% Reads midi file
midi = readmidi("correct.mid");
midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin


%%
voice = 1;
track = naacor(:,voice);

wlen = floor(fs*0.05);            % 20 ms
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^12;
ff   = (0:(P/2-1))/P*fs; 
N    = length(track);
minfreq = 50;
maxfreq = 1500;

peaks = zeros(wnum,1);

for t=1:wnum-1
    x = track((t-1)*wlen+1:t*wlen);
    autocor = acf(x, wlen);                        % Is it a consonant?
    if max(autocor(floor(fs/maxfreq+1):end)) > 0.4 && var(x) > 1e-7
        spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
        spect = spect(P/2+1:end);
        per = combFilter(spect,1,[],4, -0.01);
        [freq, amp] = findpeaks(per,1);
        peaks(t,1) = ff(freq(1));
    end
end

newPeaks = zeros(size(peaks));
reldist = @(f1, f2) abs(f1/f2-1);
rdlimit = 0.05;
for i=2:(length(peaks)-1)
    if reldist(peaks(i), peaks(i-1)) < rdlimit && reldist(peaks(i), peaks(i-1)) < rdlimit
        newPeaks(i) = peaks(i);
    end
end

peaks = newPeaks;

figure
plotparts(midinotes,voice)
plot((wlen:wlen:N)./fs,peaks(:,1),".")
%plot((wlen:wlen:N)./fs,movmedian(peaks(:,1),40),".")

%% Using built in 

newPeaks = zeros(wnum,1);

spectro = spectrogram(track,wlen,0,P,fs,"reassigned");
spectro = abs(spectro);
spectro = combFilter(spectro,1,[],4, -0.01);

for i=1:wnum
    newPeaks(i) = findpeaks(spectro(:,i),1);
end

%%
figure
plotparts(midinotes,voice)
plot((wlen:wlen:N)./fs,newPeaks,".")