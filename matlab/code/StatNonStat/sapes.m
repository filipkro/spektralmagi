% FUNCTION [ sfb ] = sapes( y, Padd, [Rfb] )
%
% The function calculates the FB-SAPES beamformer. This implementation 
% follows (please cite if used): 
%
% A. Jakobsson and P. Stoica, "On the Forward-Backward Spatial APES",
% Signal Processing, Vol. 86, pp. 710-715, 2006. 
%
% Parameters:
%   y           Input data.
%   Padd        Number of frequency grid points to evaluate over.
%   Rfb         Forward-backward averaged covariance matrix (optional).
%   sfb         The estimated FB-SAPES spectrum 
%
% By Andreas Jakobsson, 050314.
%
function [ sfb ] = sapes( y, Padd, Rfb )

% Calculate R matrix.
[m,N] = size(y);
if nargin<3,
    J = fliplr(eye(m-1));
    Rf  = ( y(1:m-1,:)*y(1:m-1,:)' + y(2:m,:)*y(2:m,:)' )/N/2; 
    Rfb = ( Rf + J*Rf.'*J )/2;
end
    
sfb = zeros(Padd,1);
ff = linspace(-pi/2,pi/2,Padd);
for k=1:Padd,
    omega_s = pi*sin(ff(k));

    % Calculate G matrix
    Gf = zeros(m-1);    Gb = Gf;
    for t=1:N,        
        gk = y(1:m-1,t) + y(2:m,t) * exp(i*omega_s);
        gt = conj( flipud(y(2:m,t)) ) + conj( flipud(y(1:m-1,t)) ) * exp(i*omega_s);
        Gf = Gf + gk*gk';
        Gb = Gb + gt*gt';
    end
    Gb = Gb/N/4;
    Gf = Gf/N/4;

    % Steering vector for current DOA.
    a1 = exp(-i*omega_s*[0:m-2]).';

    % Evaluate spectra
    iQ = inv( Rfb - Gb/2 - Gf/2 );
    iQa = iQ*a1;   
    hfb = iQa /( a1'*iQa );     % FB filter
    sfb(k) = abs( hfb'*Gf*hfb );
end
