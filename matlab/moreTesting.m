fs = 44100;

txtcor(:,1) = audioread("/project/recordings/txtcor1.wav");
txtcor(:,2) = audioread("/project/recordings/txtcor2.wav");
txtcor(:,3) = audioread("/project/recordings/txtcor3.wav");
txtcor(:,4) = audioread("/project/recordings/txtcor4.wav");
txtcor(:,5) = audioread("/project/recordings/txtcor5.wav");

amp = [1.3 1 1.1 1.3 1.2]; % Amplification
txtcor(:,6) = sum(amp.*txtcor(:,1:5),2);

%%
dsfactor = 10;
txtcor2 = zeros(length(txtcor)/dsfactor,6);
for voice = 1:6
    txtcor2(:,voice) = decimate(txtcor(:,voice),dsfactor);
end
dsfs = fs/dsfactor;

%%
d = 2;
w_l = 50; % window length in ms
window  = floor(dsfs*3/(0.1*w_l)/18); % 20 ms
windows = floor(length(txtcor2)/window);
P   = 2*window;
ff  = (0:(P/2-1))/P*dsfs; 
N = length(txtcor2);

%%
voice = 4;

peaks = zeros(windows,d);
peaksR = zeros(windows,d);

for t=1:windows-1
    x = txtcor2((t-1)*window+1:t*window,voice);
    xh = hilbert(x);
   % xh2 = xh(1:2:end);
    %spect = abs( miaa(x,window,1:window,P) ).^2; % IAA, P must be >= 2* N
    spect = fftshift(abs(fft(x,P))/window).^2;   % periodogram
    spect = spect(P/2+1:end);
    [fRelax, ~] = relax(xh,d+1);
   % [fRelax2, ~] = relax(xh2,d+1);
    fRelax = sort(dsfs*(fRelax/2/pi));
   % fRelax2 = sort(dsfs*(fRelax2/2/pi));
    %per = combFilter(per,0.5);
    peaksR(t,:) = fRelax(1:end-1);
    peaks(t,:) = sort(findpeaks(spect,d));
end
peaks = peaks + 1;

%%
wdw2 = 18;

peaks2  = zeros(size(peaks));
for i=wdw2/2:length(peaks)-wdw2/2
    peaks2(i,1) = median(peaks(i-wdw2/2+1:i+wdw2/2));
end

%%
figure
filtparam = 0.75/2/(0.001*w_l);
hold on
for i=1:1
    scatter(1:windows,movmedian(ff(peaks(:,i)),filtparam))
    scatter(1:windows,movmedian(peaksR(:,i),filtparam))
end
legend('Per','Relax')
ylim([60 1000])
%ylim([65 600])

%%
ff  = ((0:P-1)/P-.5)*fs; 
%%
A  = exp( 2i*pi*(1:window)'*ff );
[p,~,R] = q_SPICE( a, A, 1, 1e-4 );          % q=1, i.e., SPICE
tmp = R\a;
for m=1:P
    sSpice1(m) = abs( p(m)*(A(:,m)'*tmp) );
end