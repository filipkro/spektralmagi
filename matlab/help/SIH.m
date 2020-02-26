function [s,t,ff] = SIH(x,fs, Nh)

if nargin < 3
    Nh = 4;
end

%  Extraction of Impulse-like Excitation Source
k = round(0.025*fs);
y = ILES(ILES(x,k),k);
e = ([0; y].*[y; 0] < 0).*([0; y] > [y; 0]);
e = e(1:end-1);
e = abs(y.*[0; e(1:end-1)]-y.*[e(2:end); 0]);

% Spectral estimation
wlen    = round(0.05*fs);
overlap = round(0.04*fs);
wnum    = floor(length(e)/(wlen-overlap) - wlen/((wlen-overlap)));
window  = hamming(wlen);
padding = 2.^12;
E = zeros(wnum,padding);

for frame=1:wnum
    start  = 1+(frame-1)*(wlen-overlap);
    finish = start+wlen-1;
    E(frame,:) = fftshift(abs(fft(e(start:finish).*window,padding)).^2)';
end

E = E(:,size(E,2)+1/2:end);

% Comb filtration
s = E;
for f=1:size(E,2)
    for k=2:Nh
        if f*k <= size(E,2)
            s(:,f) = s(:,f) + s(:,f*k) - s(:,f*round(k-1/2));
        else
            break
        end
    end
end

% Other data
t  = (1:wnum*(wlen-overlap))/fs;
ff = (0:(padding/2-1))/padding*fs; 

end