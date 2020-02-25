function Y = combFilter(X, decay, limits, kmax, bias,nbrSum)
N = length(X);

if (nargin <3) || (length(limits) ~= 2)
   limits = [1 N]; 
end
if nargin<4
   kmax = inf; 
end
if nargin<5
    bias = 0;
end
if nargin<6
    nbrSum = 0;
end


inharmonicity = @(k, B) sqrt(1+B*k.^2);

Y = zeros(size(X));

for f=limits(1):limits(2)
    k=1;
    while  (k <= kmax) && (f*k <= N)
        Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)),:)*decay.^(k-1);
        if nbrSum>0
            for l=1:nbrSum
                if round(f*k*inharmonicity(k,bias)+l) < length(X)
                    Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)-l),:)*decay.^(k-1)*0.4.^(l-1);
                    Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)+l),:)*decay.^(k-1)*0.4.^(l-1);
                end
            end
        end
        k = k+1;
    end
end

end