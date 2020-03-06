
close all
%%
clear all
%%

fs = 44100;

txtcor(:,1) = audioread("/project/recordings/txtcor1.wav");
txtcor(:,2) = audioread("/project/recordings/txtcor2.wav");
txtcor(:,3) = audioread("/project/recordings/txtcor3.wav");
txtcor(:,4) = audioread("/project/recordings/txtcor4.wav");
txtcor(:,5) = audioread("/project/recordings/txtcor5.wav");

amp = [1.3 1 1.1 1.3 1.2]; % Amplification
txtcor(:,6) = sum(amp.*txtcor(:,1:5),2);

df = 5;
song = decimate(txtcor(2.25*fs:end,4),df);
fs = fs/df;

midi = readmidi("correct.mid");
notes = midiInfo(midi,0);

notesFreq = notes;
notesFreq(:,3) = midi2freq(notes(:,3));

idx = notesFreq(:,1)==4;
ch4 = notesFreq(idx,:);

time = zeros(1,length(txtcor(:,6)));

%%
tskip = 0.05;
skip = floor(tskip*fs);
tstart = tskip;
d = 3;
wl = 0.05;
N = ceil(length(song)/fs/wl);
peaksR = zeros(N,d);
k=0;
for i=1:length(ch4)
    k = k+skip;
    tonelen = (ch4(i,6)-ch4(i,5)-2*tskip)*fs;
    istart = ceil(tstart*fs);
    wi = wl*fs;
    windows = floor(tonelen/fs/wl);
    
    for w=1:windows
        k=k+1;
        x = song(floor(istart+(w-1)*wi):istart+w*wi);
        xh = hilbert(x);
        [fRelax, ~] = relax(xh,d);
        peaksR(k,:) = sort(fs*(fRelax/2/pi));
    end
    
    tstart = tstart + tonelen/fs + 2*tskip;
    display(i)
end


%%
tskip = 0.05;
skip = floor(tskip*fs);
tstart = tskip;
wl = 0.05;
N = ceil(length(song)/fs/wl);
d=3;
peaksR = zeros(N,d);
k=0;
for i=1:length(ch4)
    k = k+skip;
    tstart = ch4(i,5);
    tstop = ch4(i,6);
    t = tstart+tskip;
    while t < tstop-tskip
        k = k+1;
        x = song(floor(t*fs+1):floor((t+wl)*fs));
        xh = hilbert(x);
        [fRelax, ~] = relax(xh,d);
        peaksR(k,:) = sort(fs*(fRelax/2/pi));
        t = t + wl;
    end
    k=k+skip;
    display(i)
end
%%

figure
filtparam = 0.75/2/(0.001*w_l);
hold on
for i=1:1
    scatter(1:length(peaksR),movmedian(peaksR(:,i),filtparam))
end
%legend('Per','Comb','Relax')
ylim([60 1000])
%ylim([65 600])