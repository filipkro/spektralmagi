%% Preparation
addpath(genpath("../")); % add parent directory 
fs = 44100;
dsfactor = 8; % multiple of 2
fs = fs/dsfactor;

%% Loads data
clear txtcor naacor txtinc naainc
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/txtcor%i.wav",ch)));
    txtcor(:,ch) = decimate(sequence, dsfactor);
end
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/naacor%i.wav",ch)));
    naacor(:,ch) = decimate(sequence, dsfactor);
end
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/txtinc%i.wav",ch)));
    txtinc(:,ch) = decimate(sequence, dsfactor);
end
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/naainc%i.wav",ch)));
    naainc(:,ch) = decimate(sequence, dsfactor);
end
clear sequence

%% Reads midi file
midi = readmidi("correct.mid");
midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin


%%
voice = 1;
track = naacor(:,voice);

d    = 1; % peaks to look for
wlen = floor(fs*0.02); % 20 ms
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^12;
ff   = (0:(P/2-1))/P*fs; 
N    = length(track);

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


