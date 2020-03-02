

function nailedIt = correctTone(midinotes, freqest, fs, voice, errormargin)

if nargin < 5
    errormargin = 1.029302236643492;
end

nailedIt = ones(1,sum(midinotes(:,1)==voice));
boxIndex = 0;
freqRefUpper = 0;
freqRefLower = 0;
k = 1;
for i=1:length(midinotes)
    reference = midinotes(i,1);
    
    if reference == voice
        boxIndex = boxIndex + 1;
        freqRefHigh = midinotes(i,3)/errormargin;
        freqRefLow = midinotes(i,3)*errormargin;
        startTime = midinotes(i,5);
        stopTime = midinotes(i,6);
        
        while freqest(k,1) < startTime
            k = k + 1;
        end        % when reaching this line, we are at the start of a box
        
        outliers = 0;
        nbrSampleInBox = 0;
        while frekest(k) <= stopTime
            nbrSampleInBox = nbrSampleInBox + 1;
            freqVoice = freqest(k,2)
            if (freqVoice > freqRefHigh | freqVoice < freqRefLow)
                outliers = outliers + 1;
            end
            k = k + 1;
        end
        share = outliers/nbrSampleInBox;
        if share > 0.2
            nailedIt(boxIndex) = 0;
        end
    end
end
end



