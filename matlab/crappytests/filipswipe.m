clear all
close all

run setup.m

dsfactor = 1; % multiple of 2
fs = 44100;
fs = fs/dsfactor;


%%
voice = 3;
track = naainc(:,voice);
d    = 1; % peaks to look for
wtime = 0.04; % 40 ms
wlen = floor(fs*wtime); 
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^16;
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
swipert = zeros(51,wnum-1);

for t=1:wnum-1
    x = track((t-1)*wlen+1:t*wlen);
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    
%     [~, epeaks] = findpeaks(spect, 2);
%     eratio(t) = sum(epeaks)/sum(spect);
%     if sum(spect) > sum_rate && eratio(t) > e_rate
%     per = combFilter(spect,1,[],2); % -0.01
%     peaks(t) = ffP(sort(findpeaks(per,1)));
%     end
    [yin_peaks(t), a(t)] = yin_mgc(x,80,500,fs);
%     t1 = clock;
    %sp = swipep(x, fs, [80 500], wtime/5,[],[], 0.25);
%     swipert(:,t) = swipep(x, fs, [80 500], wtime/50,[],[], 0.25);
    
%     clock - t1
    %swipe_time = t2(6) -t1(6)
    %swipe_peaks(t) = mean(sp,'omitnan');
    %display(t)
    
%     if mod(t,10) == 0
%         spect_save = spect;
%         figure
%         semilogy(ffP,spect)
%     end
    
    per = combFilter(spect,0.9,[],4, 0, [2,0.8]); % -0.01
    peaks(t,1) = ffP(sort(findpeaks(per,1)));
    
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
[sp,tp,ss] = swipep(track, fs, [80 500], 0.04, 0.25);

medsp = movmedian(sp,10,'omitnan');

%%
close all
ttt = (wlen:wlen:N)./fs;
peaksP = [ttt' movmedian(peaks,2)];
figure
set(gca,'YScale', 'log')
compP = comparenotes(peaksP,notes{voice},1,1.03);
plot((wlen:wlen:N)./fs,peaks,".");
% title('Combfiltered periodo
xlabel('Time / s','FontSize',15)
ylabel('Frequency / Hz','FontSize',15)

peaksY = [ttt' movmedian(yin_peaks,2)];
figure
set(gca,'YScale', 'log')
compP = comparenotes(peaksY,notes{voice},1,1.03);
plot((wlen:wlen:N)./fs,yin_peaks,".");
xlabel('Time / s','FontSize',15)
ylabel('Frequency / Hz','FontSize',15)

peaksS = [tp movmedian(sp,2)];
figure
set(gca,'YScale', 'log')
compP = comparenotes(peaksS,notes{voice},1,1.03);
plot(tp,sp,".");
xlabel('Time / s','FontSize',15)
ylabel('Frequency / Hz','FontSize',15)


%%
close(findobj('type','figure','number',2))
figure(2)
plot(tp,sp,'.')
% hold on
%plot(tp,medsp,'.')
plotparts(midinotes,voice)
xlabel('Time / s','FontSize',16)
ylabel('Frequency / Hz','FontSize',16)
title('Swipe pitch estimates','FontSize',16)
%%
%peaks(end) = peaks(end)+1;
close(findobj('type','figure','number',1))
figure(1)
%plot(tp,sp,'.')
%hold on
plot((wlen:wlen:N)./fs,peaks,'.')%,'MarkerSize',12)
% hold on
% plot((wlen:wlen:N)./fs,yin_peaks,'.','MarkerSize',12)
%plot((wlen:wlen:N)./fs,swipe_peaks,'.')
% 
% plot(tp,medsp,'.')
hold on
plotparts(midinotes,voice)
% legend('Combfilter','Yin','FontSize',14)%,'swipe filtered')
xlabel('Time / s','FontSize',16)
ylabel('Frequency / Hz','FontSize',16)
title('Pitch estimates using combfilter','FontSize',16)
%%
close(findobj('type','figure','number',3))
figure(3)
plot((wlen:wlen:N)./fs,yin_peaks,'.')%,'MarkerSize',12)
hold on
plotparts(midinotes,voice)
xlabel('Time / s','FontSize',16)
ylabel('Frequency / Hz','FontSize',16)
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
figure
semilogy(ffP,spect_save)
xlabel('Frequency / Hz','FontSize',15)