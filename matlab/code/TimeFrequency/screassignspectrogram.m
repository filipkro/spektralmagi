function [SS,MSS]=screassignspectrogram(X,M,c,NFFT,e,Fs);

% SCREASSIGNSPECTROGRAM computes and plots the reassigned spectrogram
% [SS,MSS]=screassignspectrogram(X,M,c, NFFT,e,Fs); computes and plots the windowed 
% spectrogram and the scaled reassigned spectrogram.
% 
%
% SS: the windowed spectrogram
% MSS: the scaled reassigned windowed spectrogram
% X: data sequence 
% M: sample length of Hermite function 
% c: tuning parameter
% NFFT: The number of FFT-samples, default NFFT=2048.
% e: Smaller spectrum values than this number are not reassigned, default e=0.
% Fs: Sample frequency, default Fs=1 


if nargin<1
    'Error: No data input'
end
if nargin<6
    Fs=1;
end
if nargin<5
    e=0;
end
if nargin<4
    NFFT=2048;
end

[H,TH,DH]=hermitefunc(M,1,c);

if abs(M/2-fix(M/2))>0.1
    timevect=[-(M-1)/2:(M-1)/2]';
else
    timevect=[-M/2:M/2-1]';
end

data=X;
if isreal(data)
    data=hilbert(data);
end
data=data(:);

mvect=[0:NFFT-1];
data=[zeros(fix(M/2),1);data;zeros(fix(M/2),1)];
datal=length(data(:,1));

NSTEP=1;

timevect=[0:NSTEP:datal-M-1];
  TI=[];
  FF=[];
  TFF=[];
  DFF=[];
  MSS=zeros(NFFT/2,length(timevect));
  nmat0=zeros(NFFT/2,length(timevect));
  mmat0=zeros(NFFT/2,length(timevect));
  nmat=zeros(NFFT/2,length(timevect));
  mmat=zeros(NFFT/2,length(timevect));
  for i=0:NSTEP:datal-M-1
     testdata=data(i+1:i+M);
     F=fft(H(:,1).*testdata,NFFT);
     TF=fft(TH(:,1).*testdata,NFFT);
     DF=fft(DH(:,1).*testdata,NFFT);   
     FF=[FF F(1:NFFT/2)];
     TFF=[TFF TF(1:NFFT/2)];
     DFF=[DFF DF(1:NFFT/2)];
     TI=[TI i];
  end
  SS=abs(FF).^2;
  TI=TI/Fs;
  FI=[0:NFFT/2-1]'/NFFT*Fs;
  SSmax=e*max(max(SS));
  
  %Scaling factors
  
  fact=2
  fact2=2;
  
  %Reassignment
  for n=1:length(TI)
    for m=1:NFFT/2
        if SS(m,n)>SSmax
            nmat0(m,n)=1/c*fact*(real(TFF(m,n).*conj(FF(m,n))./SS(m,n)));
            mmat0(m,n)=NFFT/c/2/pi*fact2*(imag(DFF(m,n).*conj(FF(m,n))./SS(m,n)));
            nmat(m,n)=n+round(nmat0(m,n));
            mmat(m,n)=m-round(mmat0(m,n));
            if mmat(m,n)>0 & mmat(m,n)<=NFFT/2 & nmat(m,n)>0 & nmat(m,n)<=length(TI) 
              MSS(mmat(m,n),nmat(m,n))=MSS(mmat(m,n),nmat(m,n))+SS(m,n);
            else
               mmat(m,n)=0;
               nmat(m,n)=0;
            end
        end
     end
  end

  
% figure
% TI=TI/Fs;
% FI=[0:NFFT/2-1]'/NFFT*Fs;
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
% title('ScReSp-Scaled reassigned spectrogram')


