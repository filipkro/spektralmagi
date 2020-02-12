function Y = combFilter(X, decay, limits, kmax, bias)
N = length(X);

if (nargin <3) || (length(limits) ~= 2)
   limits = [1 N]; 
end
if nargin<4
   kmax = inf; 
end

inharmonicity = @(k, B) sqrt(1+B*k.^2);

Y = zeros(N,1);

for f=limits(1):limits(2)
    k=1;
    while  (k <= kmax) && (f*k <= N)
        Y(f) = Y(f) + X(round(f*k*inharmonicity(k,bias)))*decay.^(k-1);
        k = k+1;
    end
end

end