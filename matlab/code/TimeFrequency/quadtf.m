function [W,TI,FI,G]=quadtf(X,METHOD,par,Fs,NFFT);

% QUADTF Quadratic time-frequency distributions
%    [W,TI,FI,G]=quadtf(X,METHOD,par,Fs,NFFT) calculates different time-frequency distributions 
%    in Cohen's (the quadratic) class of the (NN X 1) data vector X using s specified METHOD.
%
%    W:      Output time-frequency distribution, matrix of size (NN X NFFT).
%    TI:     Time vector (NN X 1).
%    FI:     Frequency vector (NFFT X 1).
%    G:      Time-lag kernel, given with time as the x-axis and lag as the y-axis,(NN X NN). 
%    X:      Data sequence, must be of shorter length than NFFT. 
%    METHOD: Different kernels for quadratic tf, default method is
%    'wigner'(Wigner-Ville). Other methods are 'w-wig' (Psudo-Wigner, doppler-independent kernel),
%    'l-ind' (lag-independent kernel), 'choi' (Choi-Williams), 
%    'spect' (hanning spectrogram kernel), 'rihaczek', 'w-rih' (windowed Rihaczek), 'levin',
%    'w-levin' (windowed Levin), 'page', 'sinc' (alfa=0.5). 
%    par:    Parameter choice for Choi-Williams, (default=1) 
%            and length of Hanning window of Psudo-Wigner, lag-independent kernel
%            spectrogram and windowed Levin and Rihachek, (default=NN/10).
%    Fs:     Sample frequency, default Fs=1. 
%    NFFT:   The number of FFT-samples, default NFFT=1024.




if nargin<1
    'Error: No data input'
end
if nargin<5
    NFFT=1024;
end
if nargin<4
    Fs=1;
end
if nargin<2
    METHOD='wigner';
end


od=0;
[NN,M]=size(X);
if M>NN
    X=transpose(X);
    NN=M;
end

if abs(NN/2-fix(NN/2))>0.1
    N=fix((NN+1)/2);
    od=1;
    NN=NN+1;
    X=[X;0];
else
    N=fix(NN/2);
end

if nargin<3 
    par=2*fix(NN/20);
end


if nargin<3 & (strcmp(METHOD(1:3),'cho') | strcmp(METHOD(1:3),'CHO'))
    par=1;
end

size(X)


METHOD

G=zeros(NN,NN);
if  strcmp(METHOD(1:3),'wig') | strcmp(METHOD(1:3),'WIG')
      G(N+1,:)=ones(1,NN);
elseif strcmp(METHOD(1:3),'w-w') | strcmp(METHOD(1:3),'W-W')
      win=zeros(NN,1);
      w=hanning(par+1);
      win(N-par/2:N+par/2)=w/max(w);
      G(N+1,:)=win';
elseif strcmp(METHOD(1:3),'l-i') | strcmp(METHOD(1:3),'L-I')
      win=zeros(NN,1);
      w=hanning(par+1);
      win(N-par/2:N+par/2)=w/sum(w);
      G=win*ones(1,NN);
elseif strcmp(METHOD(1:3),'cho') | strcmp(METHOD(1:3),'CHO')
     for n=-N:N-1
       for m=-N:N-1
         G(n+N+1,m+N+1)=sqrt(pi*par./(4*m^2+pi*par))*exp(-(pi^2*par*n^2)./(4*m^2+pi*par));
       end
     end
     G(:,N+1)=zeros(NN,1);
     G(N+1,N+1)=1;
elseif strcmp(METHOD(1:3),'spe') | strcmp(METHOD(1:3),'SPE') 
    win=zeros(NN,1);
    w=hanning(par+1);
    win(N-par/2:N+par/2)=w/sqrt(w'*w);
    winn=[zeros(N,1);win;zeros(N,1)];
    for i=-N:N-1
       G(i+N+1,:)=winn(i+N+1:i+NN+N).*conj(winn(i+NN+N+1:-1:i+N+2));
    end 
elseif strcmp(METHOD(1:3),'lev') | strcmp(METHOD(1:3),'LEV')
    for n=-N:N-1
      for m=-N:N-1
        if n==m
            G(n+N+1,m+N+1)=0.5;
        end
        if n==-m
            G(n+N+1,m+N+1)=0.5;
        end
      end
    end
    G(N+1,N+1)=1;
elseif strcmp(METHOD(1:3),'w-l') | strcmp(METHOD(1:3),'W-L')
    win=zeros(NN,1);
    w=hanning(par+1);
    win(N-par/2:N+par/2)=w/sqrt(w'*w);
    for n=-N:N-1
      for m=-N:N-1
        if n==m
            G(n+N+1,m+N+1)=0.5*win(m+N+1);
        end
        if n==-m
            G(n+N+1,m+N+1)=0.5*win(-m+N+1);
        end
      end
    end
elseif strcmp(METHOD(1:3),'rih') | strcmp(METHOD(1:3),'RIH')
    for n=-N:N-1
      for m=-N:N-1
        if n==m
            G(n+N+1,m+N+1)=1;
        end
      end
    end
elseif strcmp(METHOD(1:3),'w-r') | strcmp(METHOD(1:3),'W-R')  
    win=zeros(NN,1);
    w=hanning(par+1);
    win(N-par/2:N+par/2)=w/sqrt(w'*w);
    for n=-N:N-1
      for m=-N:N-1
        if n==m
            G(n+N+1,m+N+1)=win(m+N+1);
        end
      end
    end
elseif strcmp(METHOD(1:3),'pag') | strcmp(METHOD(1:3),'PAG')
    for n=-N:N-1
      for m=-N:N-1
        if n==abs(m)
            G(n+N+1,m+N+1)=1;
        end
      end
    end
elseif strcmp(METHOD(1:3),'sin') | strcmp(METHOD(1:3),'SIN')
    for n=-N:N-1
      for m=-N:N-1
        if abs(n)<=abs(m)
            G(n+N+1,m+N+1)=1./(abs(2*m)+1);
        end
      end
    end

end


X=X(:);

x=[zeros(N,1);X;zeros(N,1)];


K=zeros(NN,NN);
for i=-N:N-1
        K(i+N+1,:)=x(i+N+1:i+NN+N).*conj(x(i+NN+N+1:-1:i+N+2));
end
KG=zeros(2*NN-1,NN);
for m=1:NN
    KG(:,m)=conv(K(:,m),G(:,m));
end

KG=KG(N+1:N+NN,:); 

W=zeros(NN,NFFT);

for i=1:NN
  W(i,:)=2*(fft([KG(i,N+1:NN) zeros(1,NFFT-NN+1) KG(i,2:N)]));
end


if od==1
    NN=NN-1;
    X=X(1:NN);
    KG=KG(1:NN,1:NN);
    G=G(1:NN,1:NN);
    W=W(1:NN,:);
end


% Correction for sampling frequency

W=W/Fs;


figure

TI=[0:NN-1]';
TI=TI/Fs;
FI=[0:2:NFFT-1]'/2/NFFT*Fs;
W=real(W(:,1:2:NFFT));

c=[min(min(W)) max(max(W))];
pcolor(TI,FI,W')  
caxis(c)
shading interp
ylabel('Frequency (Hz)')
xlabel('Time (s)')
title('Time-frequency distribution')


