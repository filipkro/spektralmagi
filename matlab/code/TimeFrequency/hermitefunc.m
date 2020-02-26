function [H,TH,DH]=hermitefunc(N,K,c);

KK=K+2;
rvect=[-N/2:N/2-1]'/c;

oneK=ones(KK,1);
M=length(rvect);
oneM=ones(M,1);
SSmat=zeros(M,KK);
for k=1:KK
  SSmat(:,k)=1./(2.^((k-1)*oneM).*(factorial(k-1)*oneM)).*(rvect.^(2*(k-1))).*exp(-0.5*(rvect.^2));
end

Wigg=2*exp(-rvect.^2);

clear h H

h(:,1)=ones(M,1);
h(:,2)=2*rvect;

for i=2:KK
    h(:,i+1)=2*rvect.*h(:,i)-2*(i-1)*h(:,i-1);
end

for i=0:KK
  H(:,i+1)=(h(:,i+1).*exp(-(rvect.^2)/2)/sqrt(sqrt(pi)*2^(i)*factorial(i)));
end

for i=1:KK
    TH(:,i)=H(:,i).*rvect;
end

for i=1:KK
    DH(:,i)=(TH(:,i)-sqrt(2*(i))*H(:,i+1));
end

TH=TH*(c.^2);
H=H/sqrt(c);
TH=TH/sqrt(c);
DH=DH/sqrt(c);

H=H(:,1:K);
TH=TH(:,1:K);
DH=DH(:,1:K);

