function [X,T]=gaussdata(N,Nk,Avect,Tvect,Fvect,Fs);

% GAUSSDATA creates a complex-valued data vector with K different Gaussian components.
%   [X,T]=gaussdata(N,Nk,Avect,Tvect,Fvect,Fs) generates a complex-valued signal of total length N 
%   including a number of Gaussian components, each of length Nkomp. The centre timepoints, 
%   is specified in the vector (K X 1) Tvect and the corresponding frequencies in the (K X 1) Fvect.
%
%   X: output data vector of length N.
%   T: corresponding time vector of length N.
%   N: data vector length.
%   Nk: Length of each Gaussian component in samples.
%   Avect: K X 1 vector of amplitudes.
%   Tvect: K X 1 vector of centre values of each component, given
%   between 1/Fs and N/Fs.
%   Fvect: K X 1 vector of frequency values of each component
%   Fs: sample frequency, default=1.
%


if nargin<6
    Fs=1;
end


c=1/8*Nk;
w=exp(-0.5*([-Nk/2:Nk/2-1]'/c).^2);


X=zeros(N,1);
Tvect=fix(Tvect*Fs);
Fvect=Fvect/Fs;

for i=1:length(Tvect)
  nvect=[max(Tvect(i)-Nk/2,1):min(Tvect(i)+Nk/2-1,N)]';
  X(nvect)=X(nvect)+Avect(i)*exp(j*(2*pi*Fvect(i).*(nvect-Tvect(i)))).*w(nvect-Tvect(i)+Nk/2+1);
end

T=[0:N-1]'/Fs;


    