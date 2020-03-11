function notes = comparenotes(tf, notes, ploton, threshold)

if nargin < 3
    ploton = 0;
end
if nargin < 4
    threshold = 1.029302236643492;
end

notes = [notes, zeros(size(notes,1),1)];
i = 1;

if ploton
   hold on
end

for note=1:size(notes,1)
    while tf(i,1) < notes(note,2) && i<=size(tf,1)
        i=i+1;
    end
    total  = 0;
    inside = 0;
    while tf(i,1) < notes(note,3) && i<=size(tf,1)
        if tf(i,2) ~= 0 && ~isnan(tf(i,2))
            total = total+1;
            if notes(note,1)/threshold <= tf(i,2) && tf(i,2) <= notes(note,1)*threshold
                inside = inside+1;
            end
        end
        i=i+1;
    end
    notes(note,4) = inside/total;
    %notes(note,4) = notes(note,4) > 0.5;
    if ploton
        rectangle('Position',[notes(note,2),notes(note,1)/threshold,notes(note,3)-notes(note,2),notes(note,1)*threshold-notes(note,1)/threshold],...
            'FaceColor',[1-notes(note,4) notes(note,4) 0])
    end
end



end