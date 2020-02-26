

function S = pitchStrengthOneCandidate( f, L, pc )
    n = fix( f(end)/pc - 0.75 ); % Number of harmonics
    k = zeros( size(f) ); % Kernel
    q = f / pc; % Normalize frequency w.r.t. candidate
    for i = [ 1 primes(n) ]
        a = abs( q - i );
        % Peak's weigth
        p = a < .25;
        k(p) = cos( 2*pi * q(p) );
        % Valleys' weights
        v = .25 < a & a < .75;
        k(v) = k(v) + cos( 2*pi * q(v) ) / 2;
    end
    % Apply envelope
    k = k .* sqrt( 1./f );
    % K+-normalize kernel
    k = k / norm( k(k>0) );
    % Compute pitch strength
    S = k' * L;
end
