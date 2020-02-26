% This script computes the (pseudo)-spectra and frequency estimates of the 
% periodogram, MUSIC, RELAX, ASC, PSC, APES, IAA, (q)-SPICE, and the LASSO.
%
% The function gives the frequency estimates for the different methods, as
% well as the root mean squared error (rMSE) for the sum of frequencies.
%
% Try changing some of the settings - such as the data length, the
% frequency spacing, the number of sinusoids, their amplitudes and/or the 
% noise power.  
%
% By Andreas Jakobsson, 200115
clear; close all;

N   = 100;                      % Number of samples.
f   = [.09 .12];                % Frequencies, these are on the grid!
amp = [1 1];                    % Amplitudes
dam = [0 0];                    % Damping parameters; begin with no damping.
P   = 1000;                     % Zeropadding used by the periodogram.
fL  = 16;                       % Filter length used by PSC, ASC, and APES.
%f = f + 1e-3*randn(1,2);        % Add this to ensure that you are off-grid.
d = 2;                          % This is the number of estimated peaks.

% Generate some data.
x = amp(1)*exp( 2i*f(1)*pi*(1:N)' + 2i*pi*rand - dam(1)*(1:N)' ) + amp(2)*exp( 2i*f(2)*pi*(1:N)' + 2i*pi*rand - dam(2)*(1:N)');
w = .1*( randn(N,1) + 1i*randn(N,1) )/sqrt(2);
y = x + w;
%plot( real(y) )
%title('Real part of the signal')

% Estimate the periodogram as well as the pseudo-spectra using MUSIC,
% RELAX, PSC, ASC, APES, and IAA. 
ff  = (0:P-1)/P-.5;                     % Frequency grid.
Y = fftshift( abs(fft(y, P))/N ).^2;
fMUSIC  = sort( rootmusic(y,d)/2/pi )';
fRELAX  = sort( relax(y,d)/2/pi );
[ sApes, sAsc, sPsc] = fast_apes_2d(y(:).',[1 P],[1 fL], 0, 2 );
sPsc  = abs( fftshift( sPsc.' ) ).^2;
sAsc  = abs( fftshift( sAsc.' ) ).^2;
sApes = abs( fftshift( sApes.' ) ).^2;
sIAA  = abs( miaa(y,N,1:N,P) ).^2;      % It is worth noting that this function can also be used if samples are missing.

% Estimate the pseudo-spectra using q-SPICE.
A  = exp( 2i*pi*(1:N)'*ff );
[p,~,R] = q_SPICE( y, A, 2, 1e-4 );             % q=2
tmp = R\y;
for m=1:P
    sSpice2(m) = abs( p(m)*(A(:,m)'*tmp) );
end

[p,~,R] = q_SPICE( y, A, 1, 1e-4 );             % q=1, i.e., SPICE
tmp = R\y;
for m=1:P
    sSpice1(m) = abs( p(m)*(A(:,m)'*tmp) );
end

% Estimate the LASSO estimate using cvx.
% To run cvx, you need to install cvx, available from http://cvxr.com/cvx/.
% After downloading it, you need to set it up (once), by calling cvx_setup.
%
% Note: there seems to be some issue with the latest version of Apples OS
% having a "too high" security setting - here is a solution if you run into
% this problem:
%
%   http://ask.cvxr.com/t/gurobi-mexmaci64-cannot-be-opened-because-the-developer-cannot-be-verified/6755/6
%
% That worked for me, but I sure hope they fix it soon...
%
lambda = 1;
cvx_quiet(true)
cvx_begin 
    variable z(P) complex;
    minimize( pow_pos( norm( y-A*z, 2), 2) + lambda*norm(z,1) ); 
cvx_end
sLasso = abs( z ).^2;

% Plot estimates
figure
semilogy( ff, Y )
hold on
semilogy( ff, sPsc,'r' )
semilogy( ff, sAsc,'x-' )
semilogy( ff, sApes,'m' )
semilogy( ff, sIAA, 'g' )
hold off
legend('Per','PSC','ASC','APES','IAA')
ylim([1e-5 10])

figure
semilogy( ff, Y )
hold on
stem( ff, sSpice1 )
hold off
legend('Per', 'SPICE')
ylim([1e-5 10])

figure
semilogy( ff, Y )
hold on
stem( ff, sSpice2 )
hold off
legend('Per', 'q-SPICE, q=2')
ylim([1e-5 10])

figure
semilogy( ff, Y )
hold on
stem( ff, sLasso ) 
hold off
legend('Per', 'LASSO')
ylim([1e-5 10])

% Find the d frequency estimates.
fPER = findpeaks(Y,d);              fPER  = ff(fPER);
fPsc = findpeaks(sPsc,d);           fPsc  = ff(fPsc);
fAsc = findpeaks(sAsc,d);           fAsc  = ff(fAsc);
fApes = findpeaks(sApes,d);         fApes = ff(fApes);
fIAA = findpeaks(sIAA,d);           fIAA  = ff(fIAA);
fSpice1 = findpeaks(sSpice1,d);     fSpice1 = ff(fSpice1);
fSpice2 = findpeaks(sSpice2,d);     fSpice2 = ff(fSpice2);
fLasso = findpeaks(sLasso,d);       fLasso  = ff(fLasso);

% Present results. 
fprintf('%s%s\b\b%s\n', 'True frequencies: ', sprintf('%f, ',sort(f)), '');
fprintf('%s%s\b\b%s\n', '  Periodogram:    ', sprintf('%f, ',sort(fPER)), '');
fprintf('%s%s\b\b%s\n', '  MUSIC:          ', sprintf('%f, ',sort(fMUSIC)), '');
fprintf('%s%s\b\b%s\n', '  RELAX:          ', sprintf('%f, ',sort(fRELAX)), '');
fprintf('%s%s\b\b%s\n', '  PSC:            ', sprintf('%f, ',sort(fPsc)), '');
fprintf('%s%s\b\b%s\n', '  ASC:            ', sprintf('%f, ',sort(fAsc)), '');
fprintf('%s%s\b\b%s\n', '  APES:           ', sprintf('%f, ',sort(fApes)), '');
fprintf('%s%s\b\b%s\n', '  IAA:            ', sprintf('%f, ',sort(fIAA)), '');
fprintf('%s%s\b\b%s\n', '  SPICE:          ', sprintf('%f, ',sort(fSpice1)), '');
fprintf('%s%s\b\b%s\n', '  q-SPICE, q=2:   ', sprintf('%f, ',sort(fSpice2)), '');
fprintf('%s%s\b\b%s\n', '  LASSO:          ', sprintf('%f, ',sort(fLasso)), '');
fprintf('Periodogram resolution: 1/N = %f (roughly)\n', 1/N )
fprintf('Grid resolution limit:  1/P = %f \n\n', 1/P )  

