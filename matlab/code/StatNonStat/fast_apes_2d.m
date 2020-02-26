function [apes_spectrum, asc_spectrum, psc_spectrum, W1,W2] = ...
    fast_apes_2d(Y,K,M, cholopt, spec )

% Fast computation of FB-APES, FB-ASC, FB-PSC and F-ASC 2D spectra.
% Implementation follows E. G. Larsson/P. Stoica:
% "Fast Implementation of Two-Dimensional APES and CAPON
% Spectral Estimators"
%
% Y             = data matrix
% K             = freq. grid (2-vector)    
% M             = filter lengths (2-vector)
% cholopt       = 0: use normal cholesky, 1: use fast cholesky
% spec          = 0: compute FB-PSC only
%                 1: compute FB-ASC and FB-PSC
%                 2: compute FB-APES, FB-ASC and FB-PSC
%                 3: compute F-ASC only
%
% apes_spectrum = amplitude spectrum matrix (APES)
% asc_spectrum  = amplitude spectrum matrix (ASC)
% psc_spectrum  = amplitude spectrum matrix (PSC)
% W1,W2         = frequency axis
%
% For 1D, set M(1)=K(1)=1 and make sure Y is a row vector.
%
% Erik G. Larsson
% Release: 6/6/01
%

if size(Y,2) == 1,
   error('fast apes dimension error: For 1D, set M(1)=K(1)=1 and make sure Y is a row vector.');
end

%disp('starting up fwbw spectrum computation algorithm...')

%if cholopt == 0,
%  disp('the algorithm will use normal cholesky factorization.');
%else
%  disp('the algorithm will use fast cholesky factorization.');
%end

M = M(:).';
N = size(Y);
L = N-M+1;

n = 2^ceil(log2(N(1)*N(2)));
np1 = [2^ceil(log2(2*M(1)-1)) 2^ceil(log2(2*M(2)-1))];
np2 = [2^ceil(log2(N(1))) 2^ceil(log2(N(2)))];
np3 = [2^ceil(log2(2*L(1)-1)) 2^ceil(log2(2*L(2)-1))];

y = Y(:);
Yf = fft([y; zeros(n-N(1)*N(2),1)]);
Yfh = fft([conj(flipud(y)); zeros(n-N(1)*N(2),1)]);
clear y

c_ind = find(mod((1:N(1)*N(2))-1,N(1))<=L(1)-1);
c_ind = c_ind(1:L(1)*L(2));

switch cholopt
case 0,
%   disp('computing sample covariance matrix...');
   
   if spec == 3,
%      disp('forward only');
      R = sampcov_2d(Y,M,eye(M(1)*M(2),M(1)*M(2)),1);
      R = sampcov_2d(Y,M,R,2);
      R = 1/(2*L(1)*L(2)) * R; %%%  * (R + flipud(fliplr(conj(R))));   
      
%     disp('computing cholesky factorization...');
      
      Ric = inv(chol((R+R')/2));
      clear R
      
   else   
      
      R = sampcov_2d(Y,M,eye(M(1)*M(2),M(1)*M(2)),1);
      R = sampcov_2d(Y,M,R,2);
      R = 1/(2*L(1)*L(2)) * (R + flipud(fliplr(conj(R))));   
      
%      disp('computing cholesky factorization...');
      
      Ric = inv(chol((R+R')/2));
      clear R
   end
   
case 1,
%   disp('initializing fast cholesky, computing covariances...');
   
   if spec==3, error('not implemented, please use conventional Cholesky instead'); end
   
   rtemp = sampcov_2d(Y,M,[eye(M(1),M(1)) zeros(M(1),M(1)*M(2)-M(1))],1);
   rf = sampcov_2d(Y,M,rtemp,2);

   rtemp = sampcov_2d(fliplr(flipud(conj(Y))),M,[eye(M(1),M(1)) zeros(M(1),M(1)*M(2)-M(1))],1);
   rb = sampcov_2d(fliplr(flipud(conj(Y))),M,rtemp,2);

   rfb = rf+rb;

   clear rf rb rtemp

%   disp('constructing displacement factorization...');

   P=sqrtm(rfb(:,1:M(1)));
   Pi=inv(P);
   Ru = rfb(:,1+M(1):M(2)*M(1));
   G =  [P  Pi*Ru Pi zeros(M(1),M(2)*M(1)-M(1));
     zeros(M(1),M(1)) Pi*Ru Pi zeros(M(1),M(2)*M(1)-M(1))]';
   clear P Pi Ru rfb

   Zl=complex(zeros(M(1)*M(2),L(1)));
   for n1=1:L(1)
      x = Y(n1:n1+M(1)-1,1:M(2));
      Zl(:,n1) = x(:);
   end
   G = [G [conj([zeros(M(1),L(1)); flipud(Zl(1:M(1)*M(2)-M(1),:))]); zeros(M(1)*M(2),L(1))]];
   G = [G [[zeros(M(1),L(1)); Zl(1:M(1)*M(2)-M(1),:)]; zeros(M(1)*M(2),L(1))]];
   clear Zl x     

   Zr=complex(zeros(M(1)*M(2),L(1)));
   for n1=1:L(1)
      x = Y(n1:n1+M(1)-1,L(2):N(2));
      Zr(:,n1) = x(:);
   end
   G = [G [conj([zeros(M(1),L(1)); flipud(Zr(1+M(1):M(1)*M(2),:))]); zeros(M(1)*M(2),L(1))]];
   G = [G [[zeros(M(1),L(1)); Zr(1+M(1):M(1)*M(2),:)]; zeros(M(1)*M(2),L(1))]];
   clear Zr x

   J = [ones(1,M(1)) -ones(1,M(1)) ones(1,L(1)) -ones(1,L(1)) -ones(1,L(1)) ones(1,L(1))].';
   J = J/2;
end
 
%disp('allocating memory for polynomials...');

v1v1 = complex(zeros(np1));
if spec >=1,
   v1v2 = complex(zeros(np2));
end	
if spec == 2,
  v2v3 = complex(zeros(np3));
  v2v2 = complex(zeros(np3));
end

%disp('running factorization and polynomial computation...');

for k=0:(M(1)*M(2)-1)
   %if mod(k,round((M(1)*M(2))/10))==0, disp([num2str(ceil(100*k/(M(1)*M(2)))) '% done']); end        

   % extract row k+1 of right cholesky factor in (C'*C)
   % and perform schur complement update if necessary
    
   switch cholopt
   case 0,
      c = Ric(:,k+1)';
   case 1,
      gi=G(1,:);   
      Jgi = J.*gi';
      li = G*Jgi; 
      di = gi*Jgi;
      gi = gi/di;
      u = li*gi;
      ind1 = min(M(1),M(1)*M(2)-k);  
      ind2 = ind1 + max(0,M(1)*M(2)-k-M(1))+M(1);
      G = G -u;
      G(ind1+1:ind1+M(1)*M(2)-k-M(1),:) = G(ind1+1:ind1+M(1)*M(2)-k-M(1),:) + u(1:M(1)*M(2)-k-M(1),:);
      G(ind2+1:end,:) = G(ind2+1:end,:) + u(M(1)*M(2)-k+1:end-M(1),:);
      G = G(2:end,:);
      
      c = conj( 2*i*sqrt(L(1)*L(2))*li(M(1)*M(2)-k+1:end)/sqrt(di) ); 
   end

   % update polynomials
  
   c = reshape(c, M(1),M(2));   
   fv1 = fft2(c,np1(1),np1(2));
   fv1h = fft2(fliplr(flipud(conj(c))),np1(1),np1(2));
   v1v1 = v1v1 + fv1h.*fv1;
   
   if spec >= 1,
   
     v23_temp = reshape([c; zeros(L(1)-1, M(2))], 1, M(2)*(M(1)+L(1)-1));  
     v23_temp = [v23_temp zeros(1, n-length(v23_temp))];    
     v23_temp = ifft(v23_temp)*n;
     v2 = ifft(v23_temp.*Yf.');
     v2 = v2(c_ind);
     v2 = reshape(v2, L(1), L(2));    
     v2 = fliplr(flipud(v2)); 

     if any(np1~=np2), 
        fv1h = fft2(fliplr(flipud(conj(c))),np2(1),np2(2));
     end
     fv2 = fft2(v2,np2(1),np2(2));
     v1v2 = v1v2 + fv1h.*fv2;
     
   end
     
   if spec == 2,
     if any(np2~=np3), 
       fv2 = fft2(v2,np3(1),np3(2));
     end
     v3 = ifft(v23_temp.*Yfh.');
     v3 = v3(c_ind);
     v3 = reshape(v3, L(1), L(2));   
     v3 = fliplr(flipud(v3)); 
     fv3 = fft2(v3,np3(1),np3(2));
     fv2h = fft2(fliplr(flipud(conj(v2))),np3(1),np3(2));

     v2v2 = v2v2 + fv2h.*fv2;
     v2v3 = v2v3 + fv2h.*fv3;
   end
end

clear G J gi Jgi li di u c v2 v3 v23_temp fv1 fv1h fv2 fv2h fv3 Ric

%disp('computing spectrum...');

apes_spectrum = [];
asc_spectrum = [];
psc_spectrum = [];

W1 = 2*pi*(0:K(1)-1)/K(1);
W2 = 2*pi*(0:K(2)-1)/K(2);

v1v1 = ifft2(v1v1);
v1v1 = v1v1(1:2*M(1)-1,1:2*M(2)-1);
v1v1 = abs(fft2(conj(v1v1),K(1),K(2)));

if spec >= 1,
  v1v2 = ifft2(v1v2)/(L(1)*L(2));
  v1v2 = v1v2(1:N(1),1:N(2));
  v1v2 = conj(v1v2);
  v1v2 = [v1v2(:,M(2):end) zeros(size(v1v2,1),K(2)-size(v1v2,2)) v1v2(:,1:M(2)-1)];
  v1v2 = [v1v2(M(1):end,:) ; zeros(K(1)-size(v1v2,1),size(v1v2,2)); v1v2(1:M(1)-1,:)];
  v1v2 = conj(fft2( v1v2));
  v1v2 = v1v2 .* exp(-j*(L(1)-1)*W1(:)*ones(1,K(2))) .* exp(-j*(L(2)-1)*ones(K(1),1)*W2(:).');
  
  asc_spectrum = v1v2./v1v1;
end

if spec == 2,
  v2v2 = ifft2(v2v2)/(L(1)*L(2))^2;
  v2v3 = ifft2(v2v3)/(L(1)*L(2))^2;
  v2v2 = v2v2(1:2*L(1)-1,1:2*L(2)-1);
  v2v3 = v2v3(1:2*L(1)-1,1:2*L(2)-1);

  v2v2 = conj(v2v2);
  v2v2 = [v2v2(:,L(2):end) zeros(size(v2v2,1),K(2)-size(v2v2,2)) v2v2(:,1:L(2)-1)];
  v2v2 = [v2v2(L(1):end,:) ; zeros(K(1)-size(v2v2,1),size(v2v2,2)); v2v2(1:L(1)-1,:)];
  v2v2 = conj(fft2( v2v2));

  v2v3= conj(v2v3);
  v2v3= [v2v3(:,L(2):end) zeros(size(v2v3,1),K(2)-size(v2v3,2)) v2v3(:,1:L(2)-1)];
  v2v3= [v2v3(L(1):end,:) ; zeros(K(1)-size(v2v3,1),size(v2v3,2)); v2v3(1:L(1)-1,:)];
  v2v3= conj(fft2( v2v3));

  det = (0.5*v2v2-1).*(0.5*v2v2-1) - 0.25*v2v3.*conj(v2v3);
  s11 = (0.5*v2v2 - 1) ./ det;
  s22 = (0.5*v2v2 - 1) ./ det;
  s12 = -0.5*v2v3 ./ det;
  clear det

  v1v3 = conj(v1v2) .* exp(-j*(N(1)-1)*W1(:)*ones(1,K(2))) .* exp(-j*(N(2)-1)*ones(K(1),1)*W2(:).');

  r1 = s11.*v2v2 + s12.*conj(v2v3);
  r2 = conj(s12).*v2v2 + s22.*conj(v2v3);
  clear v2v2 v2v3
  r3 = s11.*conj(v1v2) + s12.*conj(v1v3);
  r4 = conj(s12).*conj(v1v2) + s22.*conj(v1v3);
  clear s11 s22 s12

  num = v1v2 - 0.5*(v1v2.*r1 + v1v3.*r2);
  clear r1 r2
  denom = v1v1 - 0.5*(v1v2.*r3 + v1v3.*r4);
  clear r3 r4 v1v2 v1v3
  apes_spectrum = num ./ denom; 
end

psc_spectrum = 1./v1v1;

if spec == 3, psc_spectrum = []; apes_spectrum = []; end

return


% =========================================================

function Y = sampcov_2d(X, M, C, op)

% Operations on the rectangular factors of the
% 2d-sample covariance matrix
%
% X    = data matrix
% M    = dimension of covariance matrix
% C    = any matrix
% op   = operation requested:
%        1) compute C*Z
%        2) compute C*Z'
%        here Z is the snapshot matrix as defined in Liu99
%
% Y    = result
%
% Erik G Larsson, May 2000
%

M=M(:).';
N = size(X);
X = X(:);
n = 2^ceil(log2(N(1)*N(2)));
d = fft([X; zeros(n-length(X),1)]);
K = size(C,1);
L = N-M+1;

switch op
  case 1,  % feature 1: multiply C*X
     
     Y = complex(zeros(K,L(1)*L(2)));
     
     for k=1:K
     
        c = reshape(C(k,:), M(1), M(2));
        c = reshape([c; zeros((L(1)-1), M(2))], 1, M(2)*(M(1)+L(1)-1));  
        c = [c zeros(1, n-size(c,2))];    
        
        CT=ifft(c,[],2)*n;
%        keyboard
        CTD = CT.*d.';
        CTDT = ifft(CTD,[],2);
        
        ind = find(mod((1:N(1)*N(2))-1,N(1))<=L(1)-1);
        ind = ind(1:L(1)*L(2));
        CX = CTDT(:,ind);
        Y(k,:) = CX;
        
     end
     
  case 2, % feature 2: multiply C*X'
     
     Y = complex(zeros(K,M(1)*M(2)));
     
     for k=1:K
     
        c = reshape(C(k,:), L(1), L(2));
        c = reshape([c; zeros((M(1)-1), L(2))], 1, L(2)*(L(1)+M(1)-1));  
        c = [c zeros(1, n-size(c,2))];    
        
        CT=fft(c,[],2);
        CTD = CT.*d';
        CTDT = fft(CTD,[],2);
        ind = find(mod((1:N(1)*N(2))-1,N(1))<=M(1)-1);
        ind = ind(1:M(1)*M(2));
        CX = CTDT(:,ind)/n;
        Y(k,:) = CX;
     end

otherwise,
  error('sampcov_2d: unknown operation');
end


% ====

     function y=complex(x)
     y=x;

