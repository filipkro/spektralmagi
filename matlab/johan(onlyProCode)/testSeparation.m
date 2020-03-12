
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

data2 = dsData(:,1:2); % extract the first 2 voices

% check for differences to compare with in the 2 signals 
figure()
subplot(211)
plot(data2(50000:50200,1))
subplot(212)
plot(data2(50000:50200,2))


% mixed data with 3 mics
mixedData = simulateMicSetup(data2, 44100/dsfactor, [1 2; 1 3], [2 1; 2 2.5; 2 4; 2.5 1.75; 2.5 3.25 ], 1);
axis([0 3 0 5])

dataCentered = mixedData - mean(mixedData); % centering the data

dataCentered2 = dataCentered'; % putting the data in rows instead of columns

% figure()
% subplot(211)
% plot(dataCentered2(1,:))
% subplot(212)
% plot(dataCentered2(2,:))


%% PCA
% bandpass filtering, LP for noise reduction and HP to remove trends and
% making the components more independent. OBS same/worse results with filtering!

% BPfilter = designfilt('bandpassfir', 'StopbandFrequency1', 0.2, 'PassbandFrequency1', 0.7, ...
%     'PassbandFrequency2', 3.5, 'StopbandFrequency2', 5.5, 'StopbandAttenuation1', 60, ...
%     'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
% dataCentered2BP = filter(BPfilter, dataCentered2);

% manual PCA i.e. estimating the covariance matrix of the 8 measured
% signals (data2 - data9) and projecting the data
u = 2; % number of principal components chosen
Rxxhat = cov(dataCentered2'); 
[Uhat, Dhat] = eigs(Rxxhat, u);       % we want the u most significant eigenvectors
X = dataCentered2;                 % for notational convenience
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

for k = 1:20
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
Rxxhat = cov(dataCentered2'); 
[Uhat, Dhat] = eig(Rxxhat); %eigenvectors/eigenvalues from the estimated Rxx, i.e. Rxxhat
C = diag(diag(Dhat).^(-0.5));
V = C*Uhat'; % the whitening matrix
z = V*dataCentered2; % the whitened data

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

for k = 1:20
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
%%
figure()
for p = 1:u
subplot(u,1,p)
plot(Sout(p,50000:50200))
end






