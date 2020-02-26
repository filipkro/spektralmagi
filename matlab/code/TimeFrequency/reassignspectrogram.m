function [SS,MSS,TI,FI]=reassignspectrogram(X,WIN,NFFT,e,Fs);

% REASSIGNSPECTROGRAM computes and plots the reassigned spectrogram
% [SS,MSS]=reassignspectrogram(X,WIN,e,Fs,NFFT); computes and plots the windowed spectrogram and the
% reassigned windowed spectrogram.
% 
%
% SS: the windowed spectrogram
% MSS: the reassigned windowed spectrogram
% X: data sequence 
% WIN: window vector or if given as a number,
%     a Hanning window of length WIN is used, (default datalength/10).  
% NFFT: The number of FFT-samples, default NFFT=2048.
% e: Smaller spectrum values than this number are not reassigned, default e=0.
% Fs: Sample frequency, default Fs=1 

if nargin<1
    'Error: No data input'
end
if nargin<5
    Fs=1;
end
if nargin<4
    e=0;
end
if nargin<3
    NFFT=2048;
end
if nargin<2
    WIN=round(length(X)/10);
end
if length(WIN)==1
   WIN=hanning(WIN); 
end

M=length(WIN);

if abs(M/2-fix(M/2))>0.1
    timevect=[-(M-1)/2:(M-1)/2]';
else
    timevect=[-M/2:M/2-1]';
end

    
WINT=WIN.*timevect;
WIND=diff([WIN;0]);

if isreal(X)
    X=hilbert(X);
end
X=X(:);

mvect=[0:NFFT-1];
data=[zeros(fix(M/2),1);X;zeros(fix(M/2),1)];
datal=length(data(:,1));

NSTEP=1;


FF=[];
TFF=[];
DFF=[];
TI=[];
for i=0:NSTEP:datal-M-1
   testdata=data(i+1:i+M);
   F=fft(WIN.*testdata,NFFT);
   TF=fft(WINT.*testdata,NFFT);
   DF=fft(WIND.*testdata,NFFT);   
   FF=[FF F(1:NFFT/2)];
   TFF=[TFF TF(1:NFFT/2)];
   DFF=[DFF DF(1:NFFT/2)];
   TI=[TI i];
end

SS=abs(FF).^2;
TSS=TFF.*conj(FF);
DSS=DFF.*conj(FF);

MSS=zeros(NFFT/2,datal-M);



for n=1:length(TI)
    for m=1:NFFT/2
        if SS(m,n)>e
            nmat0(m,n)=(real(TFF(m,n).*conj(FF(m,n))./SS(m,n)));
            mmat0(m,n)=(NFFT/2/pi*imag(DFF(m,n).*conj(FF(m,n))./SS(m,n)));
            nmat(m,n)=n+round(nmat0(m,n));
            mmat(m,n)=m-round(mmat0(m,n));
            if mmat(m,n)>0 & mmat(m,n)<=NFFT/2 & nmat(m,n)>0 & nmat(m,n)<=length(TI)
              MSS(mmat(m,n),nmat(m,n))=MSS(mmat(m,n),nmat(m,n))+SS(m,n);
            end
        end
    end
end

% figure
TI=TI/Fs;
FI=[0:NFFT/2-1]'/NFFT*Fs;
% subplot(211)
% c=[min(min(SS)) max(max(SS))];
% pcolor(TI,FI,SS)  
% shading interp
% caxis(c)
% ylabel('Frequency (Hz)')
% xlabel('Time (s)')
% title('Spectrogram')
% 
% subplot(212)
% c=[min(min(MSS)) max(max(MSS))];
% pcolor(TI,FI,MSS)  
% shading interp
% caxis(c)
% ylabel('Frequency (Hz)')
% xlabel('Time (s)')
% title('ReSp-Reassigned spectrogram')

