

run setup.m % adds paths, sets fs, loads data and reads midi fil

% dont forget to set dsfactor and downsample as you like after running setup.m!

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
%         A  = exp( 2i*pi*(1:length(x))'*ff );
%         [p,~,R] = q_SPICE( x, A, 2, 1e-4 );             % q=2
%         tmp = R\x;

%         for m=1:length(x)
%             sSpice(m) = abs(p(m)*(A(:,m)'*tmp));
%         end
        
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
voice = 3;
track = naacor(:,voice);


d    = 1; % peaks to look for
wlen = floor(fs*0.02); % 20 ms
wnum = floor(length(track)/wlen); % number of windows
P    = 2.^12;
ff   = (0:(P/2-1))/P*fs; 
N    = length(track);
minfreq = 50;
maxfreq = 1500;


idx = midinotes(:,1)==voice;
chvoice = midinotes(idx,:);
minfreq = floor(0.9*min(chvoice(:,3))/ff(end)*length(ff));
%
peaks = zeros(wnum,2);
yin_peaks = zeros(wnum,1);

count = 0;
eratio = zeros(wnum-1,1);
for t=1:wnum-1
    x = track((t-1)*wlen+1:t*wlen);

    
    xacf = acf(x,floor(wlen/4));
    
%     if t == round(6.8961e+02)
%         figure
%         stem(xacf)
%     end

    
    
    spect = fftshift(abs(fft(x,P))/wlen).^2;   % periodogram
    spect = spect(P/2+1:end);
    [~, epeaks] = findpeaks(spect, 2);
    eratio(t) = sum(epeaks)/sum(spect);
    
    if sum(spect) > 1e-5 && max(abs(xacf(5:end))) > 0.1 && eratio(t) > 0.01
        per = combFilter(spect,1,[minfreq, length(spect)],4, 0, 0); % -0.01
        peaks(t,1) = ff(sort(findpeaks(per,1)));
        yin_peaks(t) = yin_mgc(x,80,500,fs);

%         if peaks(t,1) < 80 && count < 5
%             figure
%             stem(xacf)
%             count = count +1;
%             figure
%             semilogy(spect)
%         end
%         if count == 6 && peaks(t,1) > 120
%             figure
%             semilogy(spect)
%         end
    end
    if t==2810
        
        figure
        stem(xacf)
        
        
        figure
        plot(ff,spect)
        title('spect-t=2810')
        figure
        plot(ff,per)
        title('per-t=2810')
    end
    %peaks(t,2) = yin_mgc(x,180,350,fs);
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

plot((wlen:wlen:N)./fs,peaks,".")
hold on
plot((wlen:wlen:N)./fs,yin_peaks,'g.')
%plot((wlen:wlen:N)./fs,movmedian(peaks,37),".")

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