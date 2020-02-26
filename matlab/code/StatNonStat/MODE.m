function thhat = MODE(R,d,spatial,dprime,Iter);
% 
% function thhat = MODE(R, d, [spatial], [ dprime ],[ Iter ]);
%
% Implementation of the MODE algorithm. This implementation 
% follows P. Stoica and K.C. Sharman IEE Proceedings vol 137 Feb 1990.
% See also ASSP-38 p.1132-  , and ASSP-34 p 1081-
%
% R		    sample covariance matrix of the observed data
% d		    Number of emitters / sinusoids
% spatial   Set to 1 if spatial MODE, 0 for temporal (default 0).
% dprime    rank of signal covariance matrix (optinal, default set to d).
% Iter		Number of iterations, usually 2 (optional, default set to 2).
%
% thhat		estimated directions or frequencies (in absolute frequencies).
%
%%
%% By Magnus Jansson 940329   
%% Modified by Andreas Jakobsson 160122
%%

if nargin<3,
    spatial = 0;
end
if nargin<4,
    dprime = d;     
end
if nargin<5,
    Iter = 2;
end

m = size(R,1);
[uu,ss,vv] = svd(R);
lam = ss(1:dprime,1:dprime);
es = uu(:,1:dprime);
sighat = mean(diag(ss(dprime+1:m,dprime+1:m)));
wchol = diag(1./sqrt(diag(lam)))*diag(diag(lam)-sighat);
L = es*wchol;
f = dprime;
q=floor((d-1)/2);
j=sqrt(-1);
b=zeros(d+1,1);
It=fliplr(eye(q+1));
St=zeros(m-d,f*(d+1));
for n=1:f
    St(1:m-d,(n-1)*(d+1)+1:n*(d+1)) = toeplitz(L(d+1:m,n),L(d+1:-1:1,n));
end

wsqrtinv=eye(m-d);
for i=1:Iter
    H=zeros(f*(m-d),d+1);
    for n=1:f
        H((n-1)*(m-d)+1:n*(m-d),1:d+1) = wsqrtinv\St(:,n*(d+1)-d:n*(d+1));
    end

    H1=H(:,1:q+1);
    H2K=H(:,d-q+1:d+1)*It;
    if (d==2*q+1)
        F=[real(H1+H2K) imag(H2K-H1);imag(H1+H2K) real(H1-H2K)];
    else
        F=[ real(H1+H2K) imag(H2K-H1) real(H(:,q+2));...
            imag(H1+H2K) real(H1-H2K) imag(H(:,q+2))];
    end;

    % Constraint: real(beta(1))=1 see Stoica Sharman for comments
    [row,col]=size(F);
    L=F(:,2:col);
    c=F(:,1);
    my=-L\c;
    if max(abs(my))>5 | my(1)==0	%Change constraint (my==0 is included to
                                    %handle th=0 (d=1) however this is not good
                                    %for symmetrically located sources and R=Rtrue)
        %disp('Element in b large, constraint in IQWSF is changed')
        L=F(:,[1:q+1 q+3:col]);
        c=F(:,q+2);
        my=-L\c;
        if (d==2*q+1)
            b(1)=my(1)+j;
            b(2:q+1)=my(2:q+1)+j*my(q+2:2*q+1);
            b(q+2:2*q+2)=It*conj(b(1:q+1));
        else
            b(1)=my(1)+j;
            b(2:q+1)=my(2:q+1)+j*my(q+2:2*q+1);
            b(q+2)=my(2*q+2);
            b(q+3:2*q+3)=It*conj(b(1:q+1));
        end;
    else
        if (d==2*q+1)
            b(1)=1+j*my(q+1);
            b(2:q+1)=my(1:q)+j*my(q+2:2*q+1);
            b(q+2:2*q+2)=It*conj(b(1:q+1));
        else
            b(1)=1+j*my(q+1);
            b(2:q+1)=my(1:q)+j*my(q+2:2*q+1);
            b(q+2)=my(2*q+2);
            b(q+3:2*q+3)=It*conj(b(1:q+1));
        end;
    end

    if i<Iter
        B=toeplitz([b(d+1);zeros(m-d-1,1)],[flipud(b);zeros(m-d-1,1)])';
        wsqrtinv=chol(B'*B)';   %%  the inversion is made above , in the "multiplication"
    end
end	% iter

if spatial,
    thhat = sort(asin(angle(roots(b))/pi));
else
    thhat = angle(roots(b))/pi/2;
end

