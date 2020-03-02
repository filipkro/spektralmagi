function [uopt,sopt,fiopt,FFiopt]=optimallsp(c,NN);

% OPTIMALLSP computes the mse-optimal multitapers
% and weights corresponding to a locally stationary process 
% with parameter c
%
% [uopt,sopt,fiopt,FFiopt]=optimallsp(c,NN); 
%
% uopt: LSP-optimal multitapers
% sopt: LSP-optimal weights
% fiopt: LSP-optimal ambiguity kernel
% FFiopt: LSP-optimal time-frequency kernel
%
% c: parameter of the LSP-process, c>1, typically 1.1, 1.5, 2, 10, 50  
% NN: multitaper window lengths


LL=2*NN;
N=NN/2;
F1=NN/15; %Scaling of the axes for appropriate calculations

f=[-NN:NN-1]'/(LL)*F1;
tl=[-NN:NN-1]'/F1;


% Optimal LSP-kernel

fiopt=1/2/pi./((1+c^(-0.5)*(exp((1-1/c)*((2*pi*f*ones(1,length(tl))).^2)+(c-1)/4*ones(length(f),1)*(tl'.^2)))));


Fiopt=zeros(LL,LL);
Giopt=zeros(LL,NN);

% Optimal time-lag-kernel

for i=1:LL
    Giopt(:,i)=fftshift((ifft([fiopt(NN+1:LL,i);fiopt(1:NN,i)])));
end
Giopt=Giopt(NN-N+1:NN+N,:);

%Optimal doppler-kernel

for i=1:LL
    Fiopt(i,:)=fftshift((fft([fiopt(i,NN+1:2*NN) zeros(1,LL-2*NN) fiopt(i,1:NN)]))); 
end

% Optimal TF-kernel

for i=1:LL
    FFiopt(:,i)=real(fftshift((ifft([Fiopt(NN+1:LL,i);Fiopt(1:NN,i)]))));
end


t=[-N:N-1]'/F1;

%Optimal multitapers uopt and weights sopt computed from the rotated time-lagkernel

for i=1:NN
    for ii=1:NN
        if abs((i-1)-(ii-1))/2-fix(abs((i-1)-(ii-1))/2)<0.1
            RRR(ii,i)=Giopt(((i-1)+(ii-1))/2+1,NN+(i-1)-(ii-1)+1);
        end    
     end
end

for i=1:NN
    for ii=1:NN
        if abs((i-1)-(ii-1))/2-fix(abs((i-1)-(ii-1))/2)>0.1
            if i>1 & ii>1 & i<NN & ii<NN
               RRR(i,ii)=(RRR(i-1,ii)+RRR(i+1,ii)+RRR(i,ii-1)+RRR(i,ii+1))/4;
            elseif i==1 & ii>1 & ii<NN
               RRR(1,ii)=(RRR(i+1,ii)+RRR(1,ii-1)+RRR(1,ii+1))/3;
            elseif ii==1 & i>1 & i<NN
               RRR(i,1)=(RRR(i-1,1)+RRR(i+1,1)+RRR(i,ii+1))/3;
            elseif i==NN & ii>1 & ii<NN
               RRR(NN,ii)=(RRR(i-1,ii)+RRR(NN,ii-1)+RRR(NN,ii+1))/3;
            elseif ii==NN & i>1 & i<NN
               RRR(i,NN)=(RRR(i-1,NN)+RRR(i+1,NN)+RRR(i,ii-1))/3;
            end
        end    
     end
end

[u1,s]=eig(RRR);
s=diag(real(s));
k=find(abs(s)>0.01);
uopt=u1(:,k);
sopt=s(k);

%figure

subplot(321)
plot(sopt)
title('Weights')
xlabel('k')
subplot(322)
plot(uopt)
title('multitapers')
xlabel('n')








