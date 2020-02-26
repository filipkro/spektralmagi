function [Reny]=renyimeas(S,t0,f0,t1,f1);


Stest=S(f0+1:f1+1,t0+1:t1+1);
Stestn=Stest./sum(sum(Stest));
[m,n]=size(Stest);



% Curtosis
%Curt=sum(sum(Stestn.^2));

% Renyi-entropy
p=3;
Reny=1/(1-p)*log2(sum(sum((Stestn).^p)));



%Lp-norm  
%L=1;
%Lpno=(sum(sum(abs(Stestn).^(1/L))))^L;

