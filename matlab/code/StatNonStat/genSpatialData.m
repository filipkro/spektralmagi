function y = genSpatialData(doaV, sigAmp,  N, m, cohS, pert)
    sig = zeros(m,N);
    tmp = ( randn(1,N) + 1i*randn(1,N) )/sqrt(2);
    for k=1:length(doaV)
        A  = exp( -pi*1i*sin(doaV(k)*pi/180)'*(0:m-1) ).';
        if pert
            A = A + sqrt(epsilon_pert)*(randn(m,1)+1i*randn(m,1))/sqrt(2);
        end
        if cohS
            sig = sig + A * sigAmp(k) * tmp * (randn+randn*1i);
        else
            sig = sig + A * sigAmp(k) * ( randn(1,N) + 1i*randn(1,N) )/sqrt(2);
        end
    end
    n = 2*( randn(m,N) + 1i*randn(m,N) )/sqrt(2);
    y = sig + n;
end