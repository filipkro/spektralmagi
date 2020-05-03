function Y = combFilter(X, decay, limits, kmax,bias,xtraTerms)
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
    xtraTerms = [0,0];
elseif length(xtraTerms) < 2
    xtraTerms(2) = 1;
end



inharmonicity = @(k, B) sqrt(1+B*k.^2);

Y = zeros(size(X));

for f=limits(1):limits(2)
    k=1;
    while  (k <= kmax) && (f*k <= N-1)
        Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)),:)*decay.^(k-1)/(2*xtraTerms(1)+1);
%         for l=1:xtraTerms(1)
%             if round(f*k*inharmonicity(k,bias)-l) > 0
%                 Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)-l),:)*decay.^(k-1)*xtraTerms(2).^l;
%             end
%             if round(f*k*inharmonicity(k,bias)+l) < length(X)
%                 Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)+l),:)*decay.^(k-1)*xtraTerms(2).^l;
%             end
%         end
        for l=1:xtraTerms(1)
            if round(f*k*inharmonicity(k,bias)-l) > 0
                Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)-l),:)*decay.^(k-1)*xtraTerms(2).^l/(2*xtraTerms(1)+1);
            end
            if round(f*k*inharmonicity(k,bias)+l) < length(X)
                Y(f,:) = Y(f,:) + X(round(f*k*inharmonicity(k,bias)+l),:)*decay.^(k-1)*xtraTerms(2).^l/(2*xtraTerms(1)+1);
            end
        end
        k = k+1;
    end
end

end