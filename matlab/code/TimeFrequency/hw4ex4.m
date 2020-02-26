
NFFT=2048;
ef=0.01; % Noise floor level for reassignment. 

% Gaussian multi-component signal (case B)
sigma=20;
Nk=sigma*8;   % A component length in gaussdata that corresponds to sigma;
[X,T] = gaussdata(600,Nk,[1 1 1],[150 300 450],[0.1 0.2 0.3]);

% Linear chirp signal (case A)
%[X,T]=gausschirpdata(600,600,300,0.01,0.25);


lambda=20; % lambda=sigma gives perfect localization. Change lambda for other window lengths.

[SSt1,RSS]=reassignspectrogram(X,100,NFFT,ef,1); 
[SSt1,SCRSS]=screassignspectrogram(X,512,lambda);

% Renyi measures
[Reny_ReSp]=renyimeas(RSS,0,0,599,512)
[Reny_ScReSp]=renyimeas(SCRSS,0,0,599,512)

