function y = ILES(x, k)

a = [2, -1];
n = [-1 -2]';

y0 = x;
for i=3:length(x)
    y0(i) = a*x(i+n);
end

y = y0 - movmean(y0,2*k+1);

end