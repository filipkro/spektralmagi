function simulated = simulateMicSetup(audio, fs, sources, mics, plotOn)

Ns = size(audio,2); % number of sources
Nm = size(mics,1);  % number of mics
L  = size(audio,1); % number of audio samples

if nargin < 5
   plotOn = 0; 
end

if size(audio,2) ~= size(sources,1)
    error("The source positions must be equal to the channels in the audio file")
end

soundSpeed = 340;

simulated = zeros(1,Nm);

for mic = 1:Nm
    for source = 1:Ns
        delay = round(norm(sources(source,:)-mics(mic,:))/soundSpeed*fs);
        if size(simulated,1) < L + delay
            simulated = [simulated; zeros(L + delay - size(simulated,1), Nm)];
        end
        simulated(1+delay:L+delay,mic) = simulated(delay+1:L+delay,mic)+audio(:,source);
    end
end

if plotOn
   figure
   title("Simulated mic setup")
   scatter(sources(:,1), sources(:,2),'x')
   text(sources(:,1),sources(:,2),sprintfc('%d',1:Ns),'VerticalAlignment','bottom','HorizontalAlignment','right')
   hold on
   scatter(mics(:,1), mics(:,2))
   text(mics(:,1),mics(:,2),sprintfc('%d',1:Nm),'VerticalAlignment','bottom','HorizontalAlignment','right')
   hold off
   legend("Sources","Mics")
end

end
