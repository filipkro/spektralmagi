function semilogypart(midinotes, part, errormargin)

if nargin < 3
    errormargin = 1.029302236643492;
end

form = "r";

hold on
set(gca, 'YScale', 'log')
for i=1:length(midinotes)
    if midinotes(i,1) == part
        
        f1 = midinotes(i,3)/errormargin;
        f2 = midinotes(i,3)*errormargin;
        t1 = midinotes(i,5);
        t2 = midinotes(i,6);
        semilogy([t1 t2], [f1 f1], form)
        semilogy([t1 t2], [f2 f2], form)
        semilogy([t1 t1], [f1 f2], form)
        semilogy([t2 t2], [f1 f2], form)
    end
end

end

