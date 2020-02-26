function [p,sigma,R,iterEnd] = q_SPICE(y,B,q,precision)
%% 
% Fast implementation of the q-SPICE algorithm.
% Input:
% y - Signal
% B - Dictionary (only signal part and not noise)
% q - Choice of norm
% precision - Tolerance level for the algorithm
% -------------------------------------------------
% Outpu:
% p - Estimated p
% sigma - Estimated noise parameters
% R - The estimated covariance matrix
% iterEnd - Number of iterations until convergence
%% Johan Swärd, 20160921

if nargin<4
    precision = 1e-5;
end

% Initializing
N = length(y); % Number of samples
M = size(B,2); % Number of candidates in the dictionary
I = eye(N); 
A = [B I]; % Makeing the SPICE dictionary
% Calculating the different weights
W_M = norms(I,2,1).^2/norm(y,2)^2;
W_M = W_M(:);
W_P = norms(B,2,1).^2/norm(y,2)^2;
W_P = W_P(:);
%%
% Initial estimates of p and sigma
p = abs(B'*y).^2./(norms(B,2,1).^4).';
sigma = abs(y);%abs(I'*y);

pOld = inf*p;
sigmaOld = inf*sigma;

counter=0;

while norm([p;sigma]-[pOld;sigmaOld])>precision 
    pvec = p;
    % Which element in p are non-zero?
    ind = find(pvec>1e-3); 
    % Which elements in [p sigma] are non-zero?
    ind2 = [ind; (M+1:M+N)']; 
    % Removing the elements and columns corresponding to zero elements in
    % p.
    pvec2 = [p;sigma]; 
    P = diag(pvec2(ind2));
    Aind = A(:,ind2);
    % Estimating the covariance matrix
    R = Aind*P*Aind'; 
    % Precalculating the inverse of R times the signal.
    invRy = R\y;
    % Preallocating beta
    beta = zeros(M+N,1);
    % beta for the non-zero valued elements in p
    beta(ind2) = pvec2(ind2).*(A(:,ind2)'*invRy);
    % save old values
    pOld = p;
    sigmaOld = sigma;
    % precompute the denominator
    den = normsFast(sqrt(W_P).*beta(1:M),1)+normsFast(sqrt(W_M).*beta(M+1:end),2*q/(q+1));
    % estimate p
    p = abs(beta(1:M))/den./sqrt(W_P);
    % estimate sigma
    sigma = abs(beta(M+1:end)).^(2/(q+1))/den./W_M.^(q/(q+1))*norm(sqrt(W_M).*beta(M+1:end),2*q/(q+1))^((q-1)/(q+1));
    % completed another iteration
    counter = counter + 1;
end
% Total amount of iteration until convergence
iterEnd = counter;
end
function out = normsFast( x, p)
% Calculating the norm fast
out = sum( abs( x ) .^ p, 1 ) .^ ( 1 / p );
end