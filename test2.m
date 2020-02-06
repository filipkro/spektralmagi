clear all
close all

run paths.m

%% load midi - eval one channel
midi = readmidi("correct.mid");
notes = midiInfo(midi,0);

notesFreq = notes;
notesFreq(:,3) = midi2freq(notes(:,3));

idx = notesFreq(:,1)==4;
ch4 = notesFreq(idx,:);

%% load song

song4 = audioread("txtcor4.wav");
song4d = decimate(song4,10);
fs = 44100;
fsd = fs/10;

%%
figure
spectrogram(song4d,fsd*0.02,[],20000,fsd,'yaxis')
axis([0 1.1 0 2])
ylim([0 1])

%%
figure
plot(song4d)
a = 1

%%
y = song4d(13245:end);
N = length(y);
w_length = 0.02;
max_itrs = N/(w_length*fsd);

% for i=1:max_itrs
%     
% end

%%
s = y(10:10+w_length*fsd);
figure
plot(s)
N = length(s)

P = 512;
ff  = (0:P-1)/P-.5;                     % Frequency grid.
Y = fftshift( abs(fft(s, P))/N ).^2;
figure
semilogy(ff,Y)

% Estimate the pseudo-spectra using q-SPICE.
% A  = exp( 2i*pi*(1:N)'*ff );
% [p,~,R] = q_SPICE( s, A, 2, 1e-4 );             % q=2
% tmp = R\s;
% for m=1:P
%     sSpice2(m) = abs(p(m)*(A(:,m)'*tmp));
% end


[fRELAX arelax]  = sort( relax(s,4)/2/pi );