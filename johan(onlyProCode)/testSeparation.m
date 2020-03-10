
% downsample the soundfile
data = naacor;
dsfactor = 10;
dsData = zeros(ceil(length(data)/dsfactor),5);
for voice = 1:5
    dsData(:,voice) = decimate(data(:,voice), dsfactor);
end

data2 = dsData(:,1:2);
mixedData = simulateMicSetup(data2, 44100/dsfactor, [1 1; 1 2], [2 1; 2 4], 1);

% centering the data
dataCentered = mixedData - mean(mixedData);
dataCentered = dataCentered'; % putting the data in rows instead of columns

% figure()
% subplot(211)
% plot(dataCentered(1,:))
% subplot(212)
% plot(dataCentered(2,:))



%% PCA
% bandpass filtering, LP for noise reduction and HP to remove trends and
% making the components more independent. OBS same/worse results with filtering!

% BPfilter = designfilt('bandpassfir', 'StopbandFrequency1', 0.2, 'PassbandFrequency1', 0.7, ...
%     'PassbandFrequency2', 3.5, 'StopbandFrequency2', 5.5, 'StopbandAttenuation1', 60, ...
%     'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 250);
% dataCenteredBP = filter(BPfilter, dataCentered);

% manual PCA i.e. estimating the covariance matrix of the 8 measured
% signals (data2 - data9) and projecting the data
u = 2; % number of principal components chosen
Rxxhat = cov(dataCentered'); 
[Uhat, Dhat] = eigs(Rxxhat, u);       % we want the u most significant eigenvectors
X = dataCentered;                 % for notational convenience
A=Uhat';  %the projection matrix, already white
Y =A*X;  % linear projection

% PCA with matlabs own version
[PCcoeff a b c varVector] = pca(X'); % the PC coeffs, a b c not used and varVector weighting the variance
kPC = PCcoeff(:, 1:u);
Y_PCA = kPC'*X; % gives the same results as my own implemented PCA => works fine

figure()
for f = 1:u
subplot(u,1,f)
plot(data2(:,1)*2, Y_PCA(f,:))
end

%% FAST-ICA with PCA before
% whitening part even though it should be white already
Rxxhat = cov(Y_PCA'); 
[Uhat, Dhat] = eig(Rxxhat); %eigenvectors/eigenvalues from the estimated Rxx, i.e. Rxxhat
C = diag(diag(Dhat).^(-0.5));
V = C*Uhat'; % the whitening matrix
z = V*Y_PCA; % the whitened data

u = 5;
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

for k = 1:100
    for i=1:u
       % w=WFastICA(:,i);
        
        w=WFastICA(i,:);
        w=w';
        
        m1=zeros(u,1);
        m2=0;
        for t=1:2500
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
plot(data2(:,1)*2, Sout(p,:))
end

%% FAST-ICA no PCA
% whitening part
Rxxhat = cov(dataCentered'); 
[Uhat, Dhat] = eig(Rxxhat); %eigenvectors/eigenvalues from the estimated Rxx, i.e. Rxxhat
C = diag(diag(Dhat).^(-0.5));
V = C*Uhat'; % the whitening matrix
z = V*dataCentered; % the whitened data

u = 2;
m1 = zeros(u,1)
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

for k = 1:10
    for i=1:u
       % w=WFastICA(:,i);
        
        w=WFastICA(i,:);
        w=w';
        
        m1=zeros(u,1);
        m2=0;
        for t=1:302171
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
plot((dataCentered(1,:)'.l.l.)*2, Sout(p,:))
end






