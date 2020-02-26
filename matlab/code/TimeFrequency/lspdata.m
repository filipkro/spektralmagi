function [X,T,Ry]=lspdata(c,N,F0,Fs);

% LSPDATA computes a data-vector of a locally stationary process (LSP)  
%   [X,T,Ry]=lspdata(c,N,F0,Fs); generates a LSP-process 
%         of total length N with centre frequency F0. 
%
%   X: output data vector of length N
%   T: corresponding time vector of length N
%   Ry: Covariance matrix
%   c: Model parameter, c>1 
%   N: data vector length
%   F0: centre frequency value between 0 to 0.5*Fs, default=0
%   Fs: sample frequency, default=1
%

if nargin<4
    Fs=1;
end

if nargin<3
    F0=0;
end

F1=N/10; %scaling factor

t=[-N/2:N/2-1]'/F1;
s=[-N/2:N/2-1]/F1;

RT=exp(-(c/8).*(t*ones(1,length(s))-ones(length(t),1)*s).^2);
QH=exp(-0.5*((t*ones(1,length(s))+ones(length(t),1)*s)/2).^2);

% Covariance matrix of the base-band lsp-process

Ry=(RT.*QH);

% Realisations from the filtered white noise realization b

b=randn(N,1); % Noise realization
c1=sqrtm(Ry);
%mesh(real(c1))
%pause

X=real(c1)*b; %lsp-realization

randornot = 0;
if c
    randornot = rand;
end

if F0>0
  X=X.*exp(i*2*pi*(F0/Fs*[0:N-1]'+randornot)); % Frequency translation and stochastic phase
end
X=real(X);
T=[0:N-1]'/F1; %Time vector

%Covariance matrix
Ry=Ry.*toeplitz(real(exp(i*2*pi*(F0/Fs*[0:N-1]'))));
    