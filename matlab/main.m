%% Preparation
addpath(genpath("../")); % add parent directory 
fs = 44100;
dsfactor = 8; % multiple of 2
fs = fs/dsfactor;

%% Loads data
clear txtcor naacor txtinc naainc
for ch=1:5
    txtcor(:,ch) = hilbert(audioread(sprintf("/recordings/txtcor%i.wav",ch)));
    naacor(:,ch) = hilbert(audioread(sprintf("/recordings/naacor%i.wav",ch)));
    txtinc(:,ch) = hilbert(audioread(sprintf("/recordings/txtinc%i.wav",ch)));
    naainc(:,ch) = hilbert(audioread(sprintf("/recordings/naainc%i.wav",ch)));
end

txtcor = decimate(txtcor(1:2:end,:), dsfactor/2);
naacor = decimate(naacor(1:2:end,:), dsfactor/2);
txtinc = decimate(txtinc(1:2:end,:), dsfactor/2);
naainc = decimate(naainc(1:2:end,:), dsfactor/2);


%% Reads midi file
midi = readmidi("correct.mid");
midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin


%%
voice = 5;
track = naacor(:,voice);

d    = 1; % peaks to look for
wlen = floor(fs*0.02); % 20 ms
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^12;
ff   = (0:(P/2-1))/P*fs; 
N    = length(track);

%%
peaks = zeros(wnum,1);

ifplot = 0;
plotstop = 1500;
for t=1:wnum-1
    %disp(t)
    x = track((t-1)*wlen+1:t*wlen);
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    if t == plotstop && ifplot
        plot(ff,spect)
        hold on
    end
    if sum(spect) > 1e-3
        per = combFilter(spect,1,[],4, -0.01); % -0.01
        peaks(t,1) = ff(sort(findpeaks(per,1)));
    end
    if t == plotstop && ifplot
        plot(ff,per,"--")
    end
    %peaks(t,2) = yin_mgc(x, 60, 500, fs); % Yin algorithm
end

figure
plotparts(midinotes,voice)
plot((wlen:wlen:N)./fs,peaks,".")
plot((wlen:wlen:N)./fs,movmedian(peaks,37),".")

%%

newPeaks = zeros(wnum,1);

spectro = spectrogram(track,wlen,0,P,fs,"reassigned");
spectro = abs(spectro);
spectro = combFilter(spectro,1,[],4, -0.01);

for i=1:wnum
    if sum(spectro(:,i)) > 1e-2
        newPeaks(i) = findpeaks(spectro(:,i),1);
    end
end

figure
plotparts(midinotes,voice)
plot((wlen:wlen:N)./fs,newPeaks,".")