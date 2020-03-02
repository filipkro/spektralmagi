clear all
close all

addpath(genpath('../..'))

dsfactor = 1; % multiple of 2
fs = 44100;
fs = fs/dsfactor;
voice = 4;

run load_data
%%
track = naacor(:,voice);
d    = 1; % peaks to look for
wtime = 0.25; % 40 ms
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


close all
plotbool = 0;
sum_rate = 0;%1e-5;
e_rate = 0;%0.01;
swipert = zeros(51,wnum-1);

for t=1:wnum-1
    x = track((t-1)*wlen+1:t*wlen);
%     spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
%     spect = spect(P/2+1:end);
%     
%     [~, epeaks] = findpeaks(spect, 2);
%     eratio(t) = sum(epeaks)/sum(spect);
%     if sum(spect) > sum_rate && eratio(t) > e_rate
%         per = combFilter(spect,0.9,[],3); % -0.01
%         peaks(t) = sort(findpeaks(per,1));
%     end
%    [yin_peaks(t), a(t)] = yin_mgc(x,80,500,fs);
    t1 = clock;
    %sp = swipep(x, fs, [80 500], wtime/5,[],[], 0.25);
    swipert(:,t) = swipep(x, fs, [80 500], wtime/50,[],[], 0.25);
    
    clock - t1
    %swipe_time = t2(6) -t1(6)
    %swipe_peaks(t) = mean(sp,'omitnan');
    %display(t)
end
%%
sss = size(swipert);
swrt = reshape(swipert,sss(1)*sss(2),1);
trt = linspace(0,N/fs,length(swrt));
figure
plot(trt,swrt,'.')
%tp = linspace(0,N*fs-1
%%
fs = 44100;
[sp,tp,ss] = swipep(track, fs, [80 500], 0.005, 0.25);

medsp = movmedian(sp,100,'omitnan');

%%
%figure
hold on
plotparts(midinotes,voice)
%hold on
%plot((wlen:wlen:N)./fs,peaks,".")
plot((wlen:wlen:N)./fs,yin_peaks,'.')
%plot((wlen:wlen:N)./fs,swipe_peaks,'.')
plot(tp,sp,'.')
plot(tp,medsp,'.')
%legend('Combfilter','Yin','SWIPE')


%%
close all
fs = 44100;
dt = 0.01;
sTh = 0.3;
hilb = 0;
if hilb
    fs = fs/2;
    p = zeros(ceil(length(txtcor(:,1))/2/fs/dt),5);
    t = zeros(ceil(length(txtcor(:,1))/2/fs/dt),5);
    s = zeros(ceil(length(txtcor(:,1))/2/fs/dt),5);
    medp = p;
else
    p = zeros(ceil(length(txtcor(:,1))/fs/dt),5);
    t = zeros(ceil(length(txtcor(:,1))/fs/dt),5);
    s = zeros(ceil(length(txtcor(:,1))/fs/dt),5);
    medp = p;
end
for k=1:5
    if hilb
        x = hilbert(txtcor(:,k));
        x = x(1:2:end);
    else
        x = txtcor(:,k);
    end
    [p(:,k),t(:,k),s(:,k)] = swipep(x,fs,[30, 800],dt,[],[],sTh);
    medp(:,k) = movmedian(p(:,k),50,'omitnan');

    
    figure(k)
    plotparts(midinotes,k)
    hold on
    plot(t(:,k),p(:,k),'.')
    plot(t(:,k),medp(:,k),'.')
    title(strcat('Voice: ',sprintf('%d',k)))
end


%%
o = 10;
d = o/pi