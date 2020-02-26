clear all
close all

addpath(genpath('../'))
fs = 44100;
dsfactor = 8; % multiple of 2
fs = fs/dsfactor;
voice = 4;


for ch=1:5
    txtcor(:,ch) = decimate(audioread(sprintf("/recordings/txtcor%i.wav",ch)), dsfactor);
    naacor(:,ch) = decimate(audioread(sprintf("/recordings/naacor%i.wav",ch)), dsfactor);
    txtinc(:,ch) = decimate(audioread(sprintf("/recordings/txtinc%i.wav",ch)), dsfactor);
    naainc(:,ch) = decimate(audioread(sprintf("/recordings/naainc%i.wav",ch)), dsfactor);
end
track = naacor(:,voice);
d    = 1; % peaks to look for
wlen = floor(fs*0.02); % 20 ms
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^10;
ff   = (0:(P/2-1))/P*fs; 
N    = length(track);
peaks = zeros(wnum,2);
yin_peaks = zeros(wnum,1);
a = zeros(wnum,1);
%%
close all
st = 1;
en = wnum-1;
plotbool = 0;
nbrplots = 5;

for t=st:en
    x = track((t-1)*wlen+1:t*wlen);
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    per = combFilter(spect,0.9,[],3); % -0.01
    peaks(t,1) = sort(findpeaks(per,1));
    [yin_peaks(t) a(t)] = yin_mgc(x,80,500,fs);
    
    if mod(t,floor((en-st)/nbrplots)) == 0
        plotbool = 1;
    end
    
    if plotbool
        figure
        semilogy(ff,spect)
        hold on
        for k=1:4
            xline(ff(k*peaks(t,1)))
        end
        plotbool = 0;
    end
    
end

figure
plot(ff(peaks(1:end-1,1)),'.')

figure
plot(yin_peaks,'.')
figure
plot(a,'x')

