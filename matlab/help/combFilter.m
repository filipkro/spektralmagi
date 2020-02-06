function Y = combFilter(X, decay, limit)
N = length(X);

if nargin <3
   limit = N; 
end

Y = zeros(limit,1);

for f=1:limit
    k=1;
    while f*k <= N
        Y(f) = Y(f) + X(f*k)*decay.^(k-1);
        k = k+1;
    end
    %Y(f) = Y(f)/(k+1);
end
