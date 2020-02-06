%% Adds all downsampeled recordings
addpath(genpath("../")); % add parent directory 
fs = 44100;
dsfactor = 5; % *2
fs = fs/(dsfactor*2);

clear txtcor naacor txtinc naainc
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/txtcor%i.wav",ch)));
    txtcor(:,ch) = decimate(sequence(1:2:end), dsfactor);
end
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/naacor%i.wav",ch)));
    naacor(:,ch) = decimate(sequence(1:2:end), dsfactor);
end
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/txtinc%i.wav",ch)));
    txtinc(:,ch) = decimate(sequence(1:2:end), dsfactor);
end
for ch=1:5
    sequence = hilbert(audioread(sprintf("/recordings/naainc%i.wav",ch)));
    naainc(:,ch) = decimate(sequence(1:2:end), dsfactor);
end
clear sequence

%% Adds midi file
midi = readmidi("/Users/erikstalberg/Documents/1Studier/Spektralanalys/project/score/correct.mid");
midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 2.25;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin

%%
voice = 4;
tones = zeros(sum(midinotes(:,1) == voice),4);

d    = 3; % peaks to look for
P    = 1024;
ff   = (0:(P/2-1))/P*fs; 
cut  = 0.0375;

k = 1;
for i=1:length(midinotes)
    if midinotes(i,1) == voice
        tstart = midinotes(i,5)+cut;
        tend   = midinotes(i,6)-cut;
        tindex = round(tstart*fs):round(tend*fs);
        tones(k,1) = mean([tstart tend]); % Mean time of note
        tones(k,2) = midinotes(i,3);
        x = txtcor(tindex,voice); % sound sequence
        spect = fftshift(abs(fft(x,P))/length(tindex)).^2; % periodogram
        [fRelax, ~] = relax(x,d);
        tones(k,4) = min(sort(fs*fRelax/2/pi));
        spect = spect(P/2+1:end);
        if sum(spect) > 1e-8
            per = combFilter(spect,1,4);
            tones(k,3) = ff(min(sort(findpeaks(spect,d)))); % estimated base freq
        end
        k = k+1;
    end
end

%%

figure
semilogy(tones(:,1),tones(:,3),"x")
hold on
semilogy(tones(:,1),tones(:,4),"o")
legend("Periodogram","Relax")
scatter(tones(:,1),tones(:,2)./qtone,"r^")
scatter(tones(:,1),tones(:,2).*qtone,"rV")



%%
d    = 5; % peaks to look for
wlen = floor(fs*0.02); % 20 ms
wnum = floor(length(txtcor)/wlen); % number of windows
P    = 1024;
ff   = (0:(P/2-1))/P*fs; 
N    = length(txtcor);

%%
voice = 4;

peaks = zeros(wnum,d);

for t=1:wnum-1
    %disp(t)
    x = txtcor((t-1)*wlen+1:t*wlen,voice);
    %spect = abs( miaa(x,wlen,1:wlen,P) ).^2; % IAA, P must be >= 2* N
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    if sum(spect) > 1e-4
        %per = combFilter(spect,0.5);
        peaks(t,:) = ff(sort(findpeaks(spect,d)));
    end
end

semilogy(tones(:,1),tones(:,2),".")

%%
yyaxis left
plot(real(txtcor(:,voice)))
hold on
yyaxis right
for i=1:1
    scatter((1:wnum)*length(txtcor)/length(peaks),movmedian(peaks(:,i),19))
end