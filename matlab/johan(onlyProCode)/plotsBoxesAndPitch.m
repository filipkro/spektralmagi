%% plots for recorded voices with swipe

run setup.m
%% 
% NOTE: TAKES ABOUT 5 MINUTES TO RUN THIS SCRIPT

superTitle = cell(5,1);
superTitle{1} = 'Counter tenor';
superTitle{2} = 'Tenor';
superTitle{3} = 'High baritone';
superTitle{4} = 'Low baritone';
superTitle{5} = 'Bass';
fileName = ['naacor'; 'naainc'; 'txtcor'; 'txtinc']; % works since same nbr of chars

for voice = 1:5 % for every voice
    figure(voice)
    sgtitle(superTitle{voice})
    
    for k = 1:4     % for every track
        if k == 1
            track = naacor(:,voice);
        elseif k == 2
            track = naainc(:,voice);
        elseif k == 3
            track = txtcor(:,voice);
        else
            track = txtinc(:,voice);
        end
        [f, t] = swipep(track,fs,[30, 800],0.005,[],[],0.3);
        peaks = [t movmedian(f,10)];
        
        subplot(2,2,k) % 2x2 subplots
        set(gca,'YScale', 'log') % set log scale 
        comparison = comparenotes(peaks,notes{voice},1,1.03);
        plot(t,peaks(:,2),".");
        title(fileName(k,:));
        ylabel('Frequency (Hz)')
        xlabel('Time (s)')
        axis([0 70 120 600]) % 0-70 xaxis and 120-600 yaxis

    end
end
