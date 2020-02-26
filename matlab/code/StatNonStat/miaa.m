% function phiIAA = miaa( data, N, mg, Padd, [noIter] )
%
% Fast implementation of the MIAA algorithm. This implementation 
% follows: 
%
% G. O. Glentis and A. Jakobsson, "Efficient Implementation of Iterative
% Adaptive Approach Spectral Estimation Techniques, IEEE Transactions on
% Signal Processing, Vol. 59, No. 9, pp. 4154-4167, Sept. 2011. 
%
% Parameters:
%   data	  Input data.
%   N         Total number of data points (if uniformly sampled).
%   mg        Given data time indices.
%   Padd      Number of frequency grid points to evaluate over. This should
%             be larger than 2N.
%   noIter    Number of IAA iterations (default 10).
%   phiIAA	  The estimated (complex-valued) IAA spectrum
%
% By G.O. Glentis, 2010.    
%
function phiIAA = miaa( data, N, mg, Padd, noIter )

data = data(:);

if nargin<6
    noIter = 10;
end
mg = logical(mg);
Ng = length(data);
Nm = N-Ng;
Qg = eye(Ng);
for k=1:noIter,
    iQg=inv(Qg);
    xxg=iQg*data;
    xxgn=zeros(N,1);
    xxgn(mg)=xxg;
    giaa_num=fft([xxgn;zeros(Padd-N,1)]);
    QQ=zeros(N,N);
    QQ(mg,mg)=iQg; % expand to NxN matrix
    fa1=[];
    for i=-N+1:N-1
       fa1=[fa1; sum(diag(QQ,i))];
    end
    Fa=fft([fa1;zeros(Padd-2*N+1,1)]);
    D=exp((j*2*pi*(N-1)/Padd)*[0:Padd-1]');
    Fa=real(D.*Fa);
    giaa_den=[Fa(1);Fa(end:-1:2)];
    gff=giaa_num./giaa_den;
    giaaf=abs(gff).^2; % IAA spectrum
    q=(ifft(giaaf))*Padd;
    QQ=toeplitz(q,conj(q));
    Qg=QQ(mg,mg); % extract from NxN matrix
end
%phiIAA = fftshift(giaaf);
phiIAA = fftshift(gff);
