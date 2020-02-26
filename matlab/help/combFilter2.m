function S = combFilter2(S, Nh)

for f=1:size(S,1)
    for k=2:Nh
        if f*k <= size(S,2)
            S(f,:) = S(f,:) + S(f*k,:) - S(round(f*(k-1/2)),:);
        else
            break
        end
    end
end