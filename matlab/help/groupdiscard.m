function tfout = groupdiscard(tfin, threshold)

tfin = sort(tfin);
groups  = {};
ngroups = 1;

%group = zeros(size(tfin));
group(1,:) = tfin(1,:);
for i=2:length(tfin)
    if tfin(i,2)/tfin(i-1,2) > threshold
        groups{ngroups,1} = group;
        group = [];
        ngroups = ngroups+1;
    end
    group = [group; tfin(i,:)];
end
groups{ngroups,1} = group;

if size(groups,1) == 1
    tfout = groups{1,1};
else
    [~, I] = sort(cellfun(@length,groups,'UniformOutput',1),"descend");
    groups = groups(I);
    
    g1 = groups{1,1};
    mg1 = mean(g1(:,2));
    g2 = groups{2,1};
    mg2 = mean(g2(:,2));
    if     size(g2,1) >= size(g1,1)/3 && mg1/1.07 <= mg2*2 && mg2*2 <= mg1*1.07
        g2(:,2) = 2*g2(:,2);
        tfout = sortrows([g1; g2],1);
    elseif size(g2,1) >= size(g1,1)/3 && mg2/1.07 <= mg1*2 && mg1*2 <= mg2*1.07
        g1(:,2) = 2*g1(:,2);
        tfout = sortrows([g1; g2],1);
    else
        tfout = sortrows(g1,1);
    end
end

end