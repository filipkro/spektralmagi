

function flagVector = correctTone(midinotes, freqest, fs, voice, errormargin)

if nargin < 5
    errormargin = 1.029302236643492;
end

flagVector = ones(1,sum(midinotes(:,1)==voice));
boxIndex = 0;
freqRefUpper = 0;
freqRefLower = 0;
for i=1:length(midinotes)
    reference = midinotes(i,1);
    if reference == voice
        boxIndex = boxIndex + 1;
        freqRefUpper = midinotes(i,3)/errormargin;
        freqRefLower = midinotes(i,3)*errormargin;
        startTime = midinotes(i,5);
        stopTime = midinotes(i,6);
        startIndex = ceil(startTime*fs);
        stopIndex = ceil(stopTime*fs);
        
        totSamplesInBox = stopIndex - startIndex;
        outliers = 0;
        for time = startIndex:stopIndex
            freqVoice = freqest(time,2)
            if (freqVoice > freqRefUpper | freqVoice < freqRefLower)
                outliers = outliers + 1;
            end
        end
        
        share = outliers/totSamplesInBox;
        if share > 0.2
            flagVector(boxIndex) = 0;
        end        
        
    end
end



