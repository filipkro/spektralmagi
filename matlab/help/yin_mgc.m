function [pitch,minamp] = yin(frame,minpitch,maxpitch,fs)
% Pitch estimation based on 
% Cheveigne & Kawahara, "YIN, a fundamental frequency estimator for
% speech and music", J. Acoust. Soc. Am., Vol. 111, No. 4, 2002.
%
% Implementation with minor modifications by 
% Christoffer A. R�dbro, Aalborg University, email: car@kom.auc.dk
% Revised: November 19, 2002
%
% "Step 6" of the original paper is not implemented, instead a simpler
% approach of forward/backward estimation is used
%
% [pitch,minamp] = pitchEstimate_YIN(frame,setup)
%
% Input:
%       frame: Current frame of length L
%       setup: struct containing:
%              Fs: sampling frequency
%              minpitch: minimum allowable pitch in [Hz]
%              maxpitch: maximum  --------- " ----------  
% Output:
%       pitch: pitch estimate in current frame 
%       minamp: parameter for voicing detection
%

global saveold

if(~isfield(saveold,'oldframe'))
  oldframe = zeros(size(frame));
else
  oldframe = saveold.oldframe;
end

if(~isfield(saveold,'confidence'))
  oldconfidence = 0;
  confpitch = 100;
else
  oldconfidence = saveold.confidence;
  confpitch = saveold.confpitch;
end

L = length(frame);

saveold.oldframe = frame(1:L/2);

% If frame length short append previous samples
% This could/should be made adaptive to pitch search range
% if L < 200;
%   frame = [oldframe(end-39:end); frame];
%   L=length(frame);
% end

Fs=fs;

minp = minpitch;
maxp = maxpitch;

maxlag = floor(Fs/minp); % determines minimum pitch frequency 
minlag = ceil(Fs/maxp); % determines maximum pitch frequency 

W=L-maxlag;
K=maxlag+1;

% Low pass filtering
h=ones(8,1)/8;
frame=filter(h,1,frame);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Forward processing %%%%%%%%%%%%%%%%%%%%%%%%%%%
x1=frame(1:W);
X1=repmat(x1,1,K);
Xtau=hankel(frame(1:W),frame(W:end));
dtau = sum((X1-Xtau).^2)';
dtau = dtau(2:end); % Remove zero lag

% Step 3, Cumulative mean normalized difference function
H = hankel(flipud(dtau),[dtau(1);zeros(length(dtau)-1,1)]);
temp = flipud(sum(H)')./(1:length(dtau))';
dtau_m = dtau./temp;
dtau_t1 = dtau_m(minlag:maxlag);


% Step 4, Minimum peak
[minamp1,index] = min(dtau_t1);
diff = dtau_t1(1:end-1) - dtau_t1(2:end);
D1 = [1; (diff>0)];
D2 = [(diff<0); 1];
peaks = D1 & D2;
candmin =  peaks & ((dtau_t1 <= 1.1 * minamp1) | dtau_t1<0.05);
index1 = min(find(candmin));

candidates1 = find(peaks & ((dtau_t1 <= 5 * minamp1) | dtau_t1<0.05));
% Determine confidence in this estimate
if(length(candidates1)>1)
  temp=dtau_t1;
  temp(index1)=10;
  confidence1 = min(temp(candidates1))/minamp1;
else
  confidence1 = 10;
end


% Step 5, Parabollic Interpolation
if (index1+minlag)<=length(dtau) & var(frame)>10^-6
  p1=dtau(index1-1+minlag-1);
  p2=dtau(index1+minlag-1);
  p3=dtau(index1+1+minlag-1);
  top = (p1-p3)/(2*(p1-2*p2+p3));
  
  index1 = index1 + top;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% Same as above but backward %%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2, Difference function
frame = flipud(frame);

x1=frame(1:W);
X1=repmat(x1,1,K);
Xtau=hankel(frame(1:W),frame(W:end));
dtau = sum((X1-Xtau).^2)';
dtau = dtau(2:end); % Remove zero lag

% Step 3, Cumulative mean normalized difference function
H = hankel(flipud(dtau),[dtau(1);zeros(length(dtau)-1,1)]);
temp = flipud(sum(H)')./(1:length(dtau))';
dtau_m = dtau./temp;
dtau_t2 = dtau_m(minlag:maxlag);

% Step 4, Minimum peak
[minamp2,index] = min(dtau_t2);
diff = dtau_t2(1:end-1) - dtau_t2(2:end);
D1 = [1; (diff>0)];
D2 = [(diff<0); 1];
peaks = D1 & D2;
candmin =  peaks & ((dtau_t2 <= 1.1 * minamp2) | dtau_t2<0.05);
index2 = min(find(candmin));

candidates2 = find(peaks & ((dtau_t2 <= 5 * minamp2) | dtau_t2< ...
			    0.05));

% Determine confidence in this estimate
if(length(candidates2)>1)
  temp = dtau_t2;
  temp(index2)=10;
  confidence2 = min(temp(candidates2))/minamp2;
else
  confidence2 = 10;
end


% Step 5, Parabollic Interpolation
if (index2+minlag)<=length(dtau) & var(frame)>10^-6
  p1=dtau(index2-1+minlag-1);
  p2=dtau(index2+minlag-1);
  p3=dtau(index2+1+minlag-1);
  top = (p1-p3)/(2*(p1-2*p2+p3));
  index2 = index2 + top;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Pick best of forward or backward
if(minamp1<=minamp2)
  index=index1;
  confidence = confidence1;
else
  index=index2;
  confidence = confidence2;
end
minamp=min(minamp1,minamp2);
  
pitchPeriod = index + minlag - 1; 
pitch = Fs/pitchPeriod; %


% Compare current pitch to old confident pitch and update if
% reasonable (this is not a part of the original paper)
if minamp < 0.3 & var(frame)>10^-6
  if ((confidence > 2) | (confidence > oldconfidence)) & var(frame)>10^-4,
    saveold.confidence = confidence;
    saveold.confpitch = pitch;
  elseif oldconfidence % If confident pitch found
    % Check if pitch seems halved or doubled
    ratio = pitch/confpitch;
    if ratio>1.6 & ratio<2.5
      pitch = pitch/2;
    elseif ratio>0.4 & ratio<0.6
      % Lesser interval for halvations since these are rare
      pitch = 2*pitch;
    end
  end
end