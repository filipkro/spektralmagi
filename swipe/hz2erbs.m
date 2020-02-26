

function erbs = hz2erbs(hz)
    erbs = 21.4 * log10( 1 + hz/229 );
end