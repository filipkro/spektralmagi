clear all
close all

addpath(genpath('../..'))

dsfactor = 1; % multiple of 2
fs = 44100;
fs = fs/dsfactor;
voice = 4;

run load_data

track = naacor(:,voice);
d    = 1; % peaks to look for
wtime = 0.04; % 40 ms
wlen = floor(fs*wtime); 
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^12;
ffP   = (0:(P/2-1))/P*fs; 
N    = length(track);
peaks = zeros(wnum,1);
yin_peaks = zeros(wnum,1);
swipe_peaks = zeros(wnum,1);
a = zeros(wnum-1,1);
eratio = zeros(wnum,1);

%%
close all
plotbool = 0;
sum_rate = 0;%1e-5;
e_rate = 0;%0.01;

for t=1:wnum-1
    x = track((t-1)*wlen+1:t*wlen);
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    
    [~, epeaks] = findpeaks(spect, 2);
    eratio(t) = sum(epeaks)/sum(spect);
    if sum(spect) > sum_rate && eratio(t) > e_rate
        per = combFilter(spect,0.9,[],3); % -0.01
        peaks(t) = sort(findpeaks(per,1));
    end
    [yin_peaks(t), a(t)] = yin_mgc(x,80,500,fs);
    %[swipe_peaks(t),tswipe,s] = swipep(x, fs, [80 500], wtime, 0.3);
end
%%
[sp,tp,ss] = swipep(track, fs, [80 500], 0.01, 0.4);

%%
figure
plotparts(midinotes,voice)
hold on
%plot((wlen:wlen:N)./fs,peaks,".")
%plot((wlen:wlen:N)./fs,yin_peaks,'.')
%plot((wlen:wlen:N)./fs,swipe_peaks,'.')
plot(tp,sp,'.')
%legend('Combfilter','Yin','SWIPE')