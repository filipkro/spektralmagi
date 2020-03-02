function [omega,alpha] = relax(x,Kmax)%,Imax)

% 
% function [omega,alpha] = relax(x,Kmax)
%---------------------------------------------------------------|
% name:     One-Dimensional  RELAX                              |
%                                                               |
% Author:   Jian Li                                             |
%                                                               |
% purpose : This program implements the 1-D RELAX algorithm     |
%           for estimating the parameters of                    |
%           complex sinusoids in unknown colored noise.         |
% input:    Kmax:  number of complex sinusnoids.                |
%           x   :  input time sequence.                         |
% output:                                                       |
%           omega: the frequency vector,  1 X Kmax.             |
%           alpha: the amplitude  vector, 1 X Kmax,             |
%                  complex amplitude values for the             |
%                  corresponding frequency estimates.           | 
% Ref  : "Efficient mixed-spectrum estimation with applications |
%         to target feature extraction", J. Li and P. Stoica, to|
%         appear in IEEE Transaction on Signal Processing, Vol. |
%         44, No. 2, Feb. 1996.                                 |
%---------------------------------------------------------------|
%
 x = x(:).';

N = length(x);
Nmax = N*64;
Imax = 100;           % maximum number of iterations.
epsilon = 0.001;      % the iteration threshold is 0.001.

for k = 1:Kmax
  z = x;
  for k1 = 1:k-1
    z = z-alpha(k1)*exp(j*omega(k1)*(0:N-1)); 
  end
  y = fft(z,Nmax)/N;
  y = [y(Nmax/2+1:Nmax) y(1:Nmax/2)];
  y1 = y.*conj(y);
  [j1,j2] = max(y1);
  omega(k) = 2*pi*(j2-Nmax/2-1)/Nmax;
  alpha(k) = y(j2);

  zi = x;
  for k1 = 1:k
    zi = zi-alpha(k1)*exp(j*omega(k1)*(0:N-1));
  end
%
% --  Iteration Starts -- 
  for i1 = 1:Imax
    for kk = 1:k
      z = x;
      for k1 = 2:k
	    z = z-alpha(k1)*exp(j*omega(k1)*(0:N-1));
      end
      y = fft(z,Nmax)/N;
      y = [y(Nmax/2+1:Nmax) y(1:Nmax/2)];
      y1 = y.*conj(y);
      [j1,j2] = max(y1);
      omegat = 2*pi*(j2-1-Nmax/2)/Nmax;
      alphat = y(j2);
      omega = [omega(2:k) omegat];
      alpha = [alpha(2:k) alphat];
    end
 
    zt = x;
    for k1 = 1:k
      zt = zt-alpha(k1)*exp(j*omega(k1)*(0:N-1));
    end
%  i1
    if abs(norm(zt)-norm(zi))/norm(zi) <= epsilon 
      break
    else
      zi = zt;
    end
  end
end


