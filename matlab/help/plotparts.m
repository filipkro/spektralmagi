% plots the boxes i.e. the allowed interval for the estimatied frequencies
%
% 

function plotparts(midinotes, parts, errormargin, col)

if nargin < 4
    color = ["r" "g" "b" "c" "m"];
end
if nargin < 3
    errormargin = 1.029302236643492;
end


%color = ["r" "g" "b" "c" "m"];

hold on
set(gca, 'YScale', 'log')
for i=1:length(midinotes)
    part = midinotes(i,1);
    if ismember(part, parts)
        
        f1 = midinotes(i,3)/errormargin;
        f2 = midinotes(i,3)*errormargin;
        t1 = midinotes(i,5);
        t2 = midinotes(i,6);
%         semilogy([t1 t2], [f1 f1], color(part))
%         semilogy([t1 t2], [f2 f2], color(part))
%         semilogy([t1 t1], [f1 f2], color(part))
%         semilogy([t2 t2], [f1 f2], color(part))
        semilogy([t1 t2], [f1 f1], color(5))
        semilogy([t1 t2], [f2 f2], color(5))
        semilogy([t1 t1], [f1 f2], color(5))
        semilogy([t2 t2], [f1 f2], color(5))
    end
end

end

