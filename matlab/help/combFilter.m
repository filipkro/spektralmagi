function Y = combFilter(X, decay, limits, kmax)
N = length(X);

if (nargin <3) || (length(limits) ~= 2)
   limits = [1 N]; 
end

Y = zeros(limit,1);

for f=limits(1):limits(2)
    k=1;
    while (f*k <= N) || (k <= kmax)
        Y(f) = Y(f) + X(f*k)*decay.^(k-1);
        k = k+1;
    end
end
