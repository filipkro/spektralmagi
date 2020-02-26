%% a)
close all
clear all
clc

% Setup
F0 = 0.1;
Fs = 1;
N = 256;
c = [1.1 21 100];

%%
figure
subplot(221)
x  = sin((1:N)*F0);
Ry = xcov(x);
mesh(-N/2:N/2-1,-N/2:N/2-1,Ry)
shading interp
title('Covariance matrix, sinusoid')
zlabel("Covariance")
zlim([-1 1])
view([1 1 0])
%%

for i=1:3
    % Simulate locally stationary process
    [X,T,Ry] = lspdata(c(i),N,F0,Fs);
    
    % Plot realization
    % figure
    % plot(X)
    % title(['Realization, c = ' num2str(c)])
    % xlabel('Time (s)')

    % Plot covariance matrix
    subplot(2,2,i)
    mesh(-N/2:N/2-1,-N/2:N/2-1,Ry)
    shading interp
    view(-69,34)
    title(['Covariance matrix, LSP, c = ' num2str(c(i))])
    zlabel("Covariance")
    zlim([-1 1])
    view([1 1 0])
end

%% b)

c = [1.1 21];



for i=1:length(c)
    figure
    [X,T,Ry] = lspdata(c(i),N,F0,Fs);
    % Find multitapers and weights
    %subplot(221)
    [uopt,sopt,fiopt,FFiopt] = optimallsp(c(i),N);
    title(['c = ' num2str(c(i))])
    
    subplot(323)
    % Plot time-frequency kernel
    t = (-N:N-1)/4;
    f = t/N;
    
    pcolor(t,f,FFiopt')
    shading interp
    title(['Time-frequency kernel, c = ' num2str(c(i))])
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    % Plot ambiguity kernel
    subplot(324)
    pcolor(f,t,fiopt')
    shading interp
    title(['Ambiguity kernel, c = ' num2str(c(i))])
    ylabel('Lag (s)')
    xlabel('Doppler (Hz)')
    
    subplot(313)
    % Plot multitaper spectrogram by using 
    mtspectrogram(X,uopt,Fs,1024,1,sopt);
    print(strcat("6bc",num2str(c(i)),".eps"))
end
