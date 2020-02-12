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
midi = readmidi("/Users/erikstalberg/Documents/1Studier/Spektralanalys/project/score/correct.mid");

midinotes = midiInfo(midi,0);
midinotes(:,5:6) = midinotes(:,5:6) + 3;
midinotes(:,3) = midi2freq(midinotes(:,3)); % mito notes to frequencies
qtone = exp((log(midi2freq(69))-log(midi2freq(68)))/2); % quarter tone, aka error margin

%% Spectral estimation for each tone
voice = 4;
tones = zeros(sum(midinotes(:,1) == voice),5);

d    = 3; % peaks to look for

P    = 512;
ff   = (0:(P-1))/P*fs; 
cut  = 0.0375;

qspice = zeros(sum(midinotes(:,1) == voice),4);
qspice = zeros(512,260);

k = 1;
for i=1:length(midinotes)
    if midinotes(i,1) == voice
        tstart = midinotes(i,5)+cut;
        tend   = midinotes(i,6)-cut;
        tindex = round(tstart*fs):round(tend*fs);
        N      = length(tindex);
        tones(k,1) = mean([tstart tend]); % Mean time of note
        tones(k,2) = midinotes(i,3);
        x = txtcor(tindex,voice); % sound sequence
        
        % Relax
        %[fRelax, ~] = relax(x,d);
        %tones(k,4) = min(sort(fs*fRelax/2/pi));
        
        % Periodogram
        spect = fftshift(abs(fft(x,P))/N).^2; % periodogram
        spect = spect(P/2+1:end);
        if sum(spect) > 1e-8
            per = combFilter(spect,1,4);
            tones(k,3) = ff(min(sort(findpeaks(spect,d)))); % estimated base freq
        end
        

        % Estimate the pseudo-spectra using q-SPICE.
        A  = exp( 2i*pi*(1:length(x))'*ff );
        [p,~,R] = q_SPICE( x, A, 2, 1e-4 );             % q=2
        tmp = R\x;

        for m=1:length(x)
            sSpice(m) = abs(p(m)*(A(:,m)'*tmp));
        end
        
        %qspice(k, = min(findpeaks(sSpice21,d));
        
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
    %spect = abs( miaa(x,wlen,1:wlen,P) ).^2; % IAA, P must be >= 2* N
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    if t == plotstop && ifplot
        plot(ff,spect)
        hold on
    end
    if sum(spect) > 1e-4
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
plot((wlen:wlen:N)./fs,peaks(:,1),".")

%%
yyaxis left
plot(real(txtcor(:,voice)))
hold on
yyaxis right
for i=1:1
    scatter((1:wnum)*length(txtcor)/length(peaks),movmedian(peaks(:,i),19))
end