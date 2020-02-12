function Y = combFilter2(X, limits,decay,kmax)
N = length(X);

if nargin <2
    limits = [1 N];
end
if nargin <3
    decay = 1;
end

Y = zeros(N,1);

for f=limits(1):limits(2)
    k=1;
    while f*k <= N || k<kmax
        Y(f) = Y(f) + X(f*k)*decay.^(k-1);
        k = k+1;
    end
    %Y(f) = Y(f)/(k+1);
end
