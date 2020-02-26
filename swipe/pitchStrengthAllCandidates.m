

function S = pitchStrengthAllCandidates( f, L, pc )
    % Normalize loudness
    warning off MATLAB:divideByZero
    L = L ./ repmat( sqrt( sum(L.*L) ), size(L,1), 1 );
    warning on MATLAB:divideByZero
    % Create pitch salience matrix
    S = zeros( length(pc), size(L,2) );
    for j = 1 : length(pc)
        S(j,:) = pitchStrengthOneCandidate( f, L, pc(j) );
    end
end
