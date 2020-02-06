function points = circularDistribution(n,offset)

if nargin < 2
    offset = 0;
end

angles = linspace(0, 2*pi, n+1)' + offset;
angles = angles(2:end);
points = [sin(angles) cos(angles)];
end