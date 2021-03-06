

run setup.m % adds paths, sets fs, loads data and reads midi file and store
% every voice in cell object

% dont forget to set dsfactor and downsample as you like after running setup.m!

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
%%
for t=1:wnum-1
    x = track((t-1)*wlen+1:t*wlen);
    autocor = acf(x, wlen);                        % Is it a consonant? No!
    if max(autocor(floor(fs/maxfreq+1):end)) > 0.4 && var(x) > 1e-7
        spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
        spect = spect(P/2+1:end);
        per = combFilter(spect,1,[],4, -0.01);
        [freq, ~] = findpeaks(per,1);
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

%%

[s, w, t] = spectrogram(track,kaiser(2.^9,5),2.^5,2.^12,fs,'yaxis');
s = abs(s).^2;
image(t,w,s*1000);
ax = gca;
ax.YDir = "normal";

figure
image(t,w,combFilter(s,1,[],5, -0.01)*1000);
ax = gca;
ax.YDir = "normal";

figure
image(t,w,combFilter2(s,5)*1000);
ax = gca;
ax.YDir = "normal";
%%
peaks = [t' findpeaks(combFilter2(s,5))'];

%%
figure
hold on
plot(t,findpeaks(s),".")
plot(t,findpeaks(combFilter(s,1,[],5, -0.01)),".")
plot(t,findpeaks(combFilter2(s,5)),".")
plotparts(midinotes,voice)
legend(["Original" "Comb filter 1" "Comb filter 2"])

%%
plotparts(midinotes,voice)
plot(t,min(findpeaks(s,2),[],1),".")

%%
figure
parbeta = 0.0000000;
cs = (combFilter(s,1,[],10, parbeta)*1000).^2./10000;
image(t,w,cs);
title(parbeta)
ax = gca;
ax.YDir = "normal";
%%
threshold = 0.001;
npeaks = 20;
peaks = zeros(size(s,2),1);
for i = 1:size(s,2)
    [l, p] = findpeaks(s(i,:),10);
    l = l(p>threshold);
    p = p(p>threshold);
    [~, minimum] = min(l);
    if ~isempty(l)
        peaks(i) = w(l(minimum));
    end
end
plot(t,peaks,".")
%%



plotparts(midinotes,voice)
hold on

%%
voice = 4;
track = naacor(:,voice);

algs = ["NCF","PEF","CEP","LHS","SRH"];%
hold on
for i=1:length(algs)
    [f0,loc] = pitch(track,fs, ...
        'Method',algs(i), ...
        'Range',[50 800], ...
        'WindowLength',round(fs*0.1), ...
        'OverlapLength',round(fs*0.05));

    t = loc/fs;
    plot(t,f0,".")
    ylabel('Pitch (Hz)')
    xlabel('Time (s)')
end

plotparts(midinotes,voice)
legend(algs)

%%
[s,t,ff] = SIH(track,fs,5);
peaks    = findpeaks(s,fs);

%%
voice = 3;
track = txtcor(:,voice);
[f, t] = swipep(track,fs,[30, 800],0.005,[],[],0.3);
%plotparts(midinotes,voice)
%plot(t,f,".")
peaks = [t movmedian(f,10)];
comparison = comparenotes(peaks,notes{voice},1,1.03)
plot(t,peaks(:,2),".")