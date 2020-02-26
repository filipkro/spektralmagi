

function hz = erbs2hz(erbs)
    hz = ( 10 .^ (erbs./21.4) - 1 ) * 229;
end