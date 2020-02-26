close all
%%
clear all


fs = 44100;

txtcor(:,1) = audioread("/project/recordings/txtcor1.wav");
txtcor(:,2) = audioread("/project/recordings/txtcor2.wav");
txtcor(:,3) = audioread("/project/recordings/txtcor3.wav");
txtcor(:,4) = audioread("/project/recordings/txtcor4.wav");
txtcor(:,5) = audioread("/project/recordings/txtcor5.wav");

amp = [1.3 1 1.1 1.3 1.2]; % Amplification
txtcor(:,6) = sum(amp.*txtcor(:,1:5),2);

fs = 44100;
midi = readmidi("correct.mid");
notes = midiInfo(midi,0);

notesFreq = notes;
notesFreq(:,3) = midi2freq(notes(:,3));

idx = notesFreq(:,1)==4;
ch4 = notesFreq(idx,:);

time = (0:1/fs:length(txtcor(:,5))/fs);

%%
dsfactor = 10;
txtcor2 = zeros(length(txtcor)/dsfactor,6);
for voice = 1:6
    txtcor2(:,voice) = decimate(txtcor(:,voice),dsfactor);
end
dsfs = fs/dsfactor;
time2 = (0:1/dsfs:length(txtcor2(:,5))/dsfs);

%%
w_l = 0.05; % window length in seconds
olf = 2/3;
wi = floor(w_l*dsfs);
windows = floor((length(txtcor2)/wi - 1)*(olf)+1);

%%
voice = 4;
P = 1024;
ff  = (0:P-1)/P-.5; 
A  = exp( 2i*pi*(1:wi)'*ff );
ss = zeros(windows,1024);
for i=1:windows
    istart = (i-1)*olf*wi+1;
    x = txtcor2(istart:istart+wi-1,voice);
    xh = hilbert(x);
    
    [p,~,R] = q_SPICE(xh,A,2,1e12);
    tmp = R\x;
    for m=1:P
        sSpice(m) = abs(p(m)*(A(:,m)'*tmp));
    end
    ss(i,:) = sSpice;
end
figure
stem(ff*dsfs,ss')