function [X,T]=gausschirpdata(N,Nk,Tvect,F0vect,F1vect,Fs);

% GAUSSCHIRPDATA creates a complex-valued data vector with K different Gaussian components.
%   [X,T]=gausschirpdata(N,Nk,Tvect,F0vect,F1vect,Fs) generates a complex-valued signal of total length N 
%   including a number of Gaussian chirp-components, each of length Nk. The centre timepoints, 
%   is specified in the vector (K X 1) Tvect and the corresponding start and end frequencies in the 
%   (K X 1) F0vect and F1vect respectively.
%
%   X: output data vector of length N.
%   T: corresponding time vector of length N.
%   N: data vector length.
%   Nk: Length of each Gaussian component.
%   Tvect: K X 1 vector of centre values of each component, given
%   between 1/Fs and N/Fs.
%   F0vect: K X 1 vector of values of the initial frequencies of each component.
%   F1vect: K X 1 vector of values of the final frequencies of each component.
%   Fs: sample frequency, default=1.
%


if nargin<6
    Fs=1;
end

norm=1/(0.05*(Nk.^2));
w=exp(-norm*([-Nk/2:Nk/2-1]').^2);

X=zeros(N,1);
Tvect=fix(Tvect*Fs);
F0vect=F0vect/Fs;
F1vect=F1vect/Fs;


for i=1:length(Tvect)
    beta   = (F1vect(i)-F0vect(i))./Nk;
    t=[0:Nk-1]';
    yvalue = exp(j*2*pi * (beta./2.*(t.^2) + F0vect(i).*t)).*w;
    nvect=[max(Tvect(i)-Nk/2,1):min(Tvect(i)+Nk/2-1,N)]';
    X(nvect)=X(nvect)+yvalue(nvect-Tvect(i)+Nk/2+1);
end

T=[0:N-1]'/Fs;




    