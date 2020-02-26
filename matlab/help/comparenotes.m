function notes = comparenotes(tf, notes, threshold)
notes = [notes, zeros(size(notes,1),1)];

i = 1;
for note=1:zeros(size(notes,1),1)
    while tf(i,1) < notes(note,2)
        i=i+1;
    end
    total  = 0;
    inside = 0;
    while tf(i,1) < notes(note,3)
        if tf(i,2) ~= 0
            total = total+1;
            if notes(note,1)/threshold <= tf(i,2) && tf(i,2) <= notes(note,1)*threshold
                inside = inside+1;
            end
        end
        i=i+1;
    end
    notes(notes,4) = inside/total;
end

end