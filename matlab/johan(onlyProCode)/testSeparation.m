
%% 
clear all
close all
clc

run setup.m

%% 
% downsample the soundfile
data = naacor;
dsfactor = 10;
dsData = zeros(ceil(length(data)/dsfactor),5);
for voice = 1:5
    dsData(:,voice) = decimate(data(:,voice), dsfactor);
end

% % sound original data
% sound(data(100000:320000,1),fs);
% sound(data(100000:320000,5),fs);
% 
% % sound dsData
% sound(dsData(10000:32000,1),fs/10);
% sound(dsData(10000:32000,5),fs/10);

% choose the voices you want to separate
data2 = zeros(length(dsData), 2); 
data2(:,1) = dsData(:,1);
data2(:,2) = dsData(:,5);

% % check for differences to compare with in the 2 signals 
% figure()
% subplot(211)
% plot(data2(50000:50200,1))
% subplot(212)
% plot(data2(50000:50200,2))


% mixed data with 5 mics
mixedData = simulateMicSetup(data2, 44100/dsfactor, [1 2; 1 3], [2 1; 2 2.5; 2 4; 2.5 1.75; 2.5 3.25 ], 0);
%axis([0 3 0 5])

dataCentered = mixedData - mean(mixedData); % centering the data

dataCentered2 = dataCentered'; % putting the data in rows instead of columns

dataCenteredChunk = dataCentered2(1:5, 10000:32000); % extracting a chunk of the 5 recordings



% figure()
% subplot(211)
% plot(dataCenteredChunk(1,:))
% subplot(212)
% plot(dataCenteredChunk(2,:))


%% PCA
% bandpass filtering, LP for noise reduction and HP to remove trends and
% making the components more independent. OBS same/worse results with filtering!

% BPfilter = designfilt('bandpassfir', 'StopbandFrequency1', 0.2, 'PassbandFrequency1', 0.7, ...
%     'PassbandFrequency2', 3.5, 'StopbandFrequency2', 5.5, 'StopbandAttenuation1', 60, ...
%     'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
% dataCenteredChunkBP = filter(BPfilter, dataCenteredChunk);

% manual PCA i.e. estimating the covariance matrix of the 8 measured
% signals (data2 - data9) and projecting the data
u = 2; % number of principal components chosen
Rxxhat = cov(dataCenteredChunk'); 
[Uhat, Dhat] = eigs(Rxxhat, u);       % we want the u most significant eigenvectors
X = dataCenteredChunk;                 % for notational convenience
A=Uhat';  %the projection matrix, already white
Y =A*X;  % linear projection

% PCA with matlabs own version
[PCcoeff a b c varVector] = pca(X'); % the PC coeffs, a b c not used and varVector weighting the variance
kPC = PCcoeff(:, 1:u);
Y_PCA = kPC'*X; % gives the same results as my own implemented PCA => works fine

figure()
for f = 1:u
subplot(u,1,f)
plot(Y_PCA(f,50000:50200))
end

%% FAST-ICA with PCA before
% whitening part even though it should be white already
Rxxhat = cov(Y_PCA'); 
[Uhat, Dhat] = eig(Rxxhat); %eigenvectors/eigenvalues from the estimated Rxx, i.e. Rxxhat
C = diag(diag(Dhat).^(-0.5));
V = C*Uhat'; % the whitening matrix
z = V*Y_PCA; % the whitened data

% u = 3; så många som jag får ut av PCAn
m1 = zeros(u,1)
m2 = 0;

WFastICA = rand(u,u)*5 - 2.5; % initiate any random separation matrix

% normalizing the vectors
for q = 1:u
WFastICA(:,q) = WFastICA(:,q)/norm(WFastICA(:,q));
end

% orthogonolizing the vectors
[E,D]=eig(WFastICA*WFastICA');
D=diag(diag(D).^(-0.5));
WFastICA=(E*D*E')*WFastICA;

for k = 1:50
    for i=1:u
       % w=WFastICA(:,i);
        
        w=WFastICA(i,:);
        w=w';
        
        m1=zeros(u,1);
        m2=0;
        for t=1:302159
            Ycolonn=z(:,t);
            m1=m1+(Ycolonn*tanh(w'*Ycolonn));
            m2=m2+(sech((w'*Ycolonn))^2);
        end
        
        WFastICA(i,:)=((m1/t)-((m2/t)*w))';
    end
    
    [E,D] = eig(WFastICA*WFastICA');
    D = diag(diag(D).^(-0.5));
    WFastICA =(E*D*E')* WFastICA
end

Sout = WFastICA*z;

figure()
for p = 1:u
subplot(u,1,p)
plot(Sout(p,50000:50200))
end

%% FAST-ICA no PCA
% whitening part
Rxxhat = cov(dataCenteredChunk'); 
[Uhat, Dhat] = eig(Rxxhat); %eigenvectors/eigenvalues from the estimated Rxx, i.e. Rxxhat
C = diag(diag(Dhat).^(-0.5));
V = C*Uhat'; % the whitening matrix
z = V*dataCenteredChunk; % the whitened data

u = size(mixedData,2); % same size as number of mics
m1 = zeros(u,1);
m2 = 0;

WFastICA = rand(u,u)*5 - 2.5;

% normalizing the vectors
for q = 1:u
WFastICA(:,q) = WFastICA(:,q)/norm(WFastICA(:,q));
end

% orthogonolizing the vectors
[E,D]=eig(WFastICA*WFastICA');
D=diag(diag(D).^(-0.5));
WFastICA=(E*D*E')*WFastICA;

count = 0;
for k = 1:80
    for i=1:u
       % w=WFastICA(:,i);
        
        w=WFastICA(i,:);
        w=w';
        
        m1=zeros(u,1);
        m2=0;
        for t=1:size(dataCenteredChunk,2)
            Ycolonn=z(:,t);
            m1=m1+(Ycolonn*tanh(w'*Ycolonn));
            m2=m2+(sech((w'*Ycolonn))^2);
        end
        
        WFastICA(i,:)=((m1/t)-((m2/t)*w))';
    end
    
    [E,D] = eig(WFastICA*WFastICA');
    D = diag(diag(D).^(-0.5));
    WFastICA =(E*D*E')* WFastICA
    count = count + 1
end

Sout = WFastICA*z;

% dividing the output with its max value
maxValues = zeros(1,u);
SoutNormalized = zeros(u, length(Sout));
for i = 1:u
    maxValues(i) = max(abs(Sout(i,:)));
    SoutNormalized(i,:) = Sout(i,:)/maxValues(i);
end

sound(SoutNormalized(1, 1:22001), fs/10);
sound(SoutNormalized(2, 1:22001), fs/10);
sound(SoutNormalized(3, 1:22001), fs/10);
sound(SoutNormalized(4, 1:22001), fs/10);
sound(SoutNormalized(5, 1:22001), fs/10);

% sound(data2(10000:32000, 1), fs/10);
% sound(data2(10000:32000, 2), fs/10);


%%
figure()
for p = 1:u
subplot(u,1,p)
plot(Sout(p,10000:10200))
end

