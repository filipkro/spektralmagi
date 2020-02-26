function [L,P]=findpeaks(X,nl,MAX,excl);
%FINDPEAKS   Finds peaks or valleys of non-negative data
%
% Syntax:
%   [l,p]=findpeaks(x,L,MAX,excl);
%
% About:
%   This file is part of the Multi-Pitch Estimation Toolbox for the book
%   M. G. Christensen and A. Jakobsson, Multi-Pitch Estimation, Morgan &
%   Claypool Publishers, 2009.
%
% Input:
%   x        input data (assumed non-negative)
%   L        number of peaks to find (default: all peaks)
%   MAX      search for maximum or minimum ({1,0}) (default: maximum)
%   excl     vector of locations to be excluded (default: empty)
%
% Output:
%   l        location of L largest peaks
%   p        L largest peaks in x
%
% Description:
%   Auxiliary function that finds the location and value of the largest (or
%   smallest) peaks in the data.
%
% Example:
%   [l,p]=findpeaks(abs(fft(x,8192)),3);
%
% Implemented By:
%   Mads G. Christensen (mgc@es.aau.dk)
%
if nargin<4,excl=[];end
if nargin<3,MAX=1;end
if nargin<2,nl=1;end

L = zeros(nl,size(X,2));
P = zeros(nl,size(X,2));
for t=1:size(X,2)
    x=X(:,t);
    df=diff(x);
    if MAX,
        ndx=find(diff(sign(df))<0)+1;
    else
        ndx=find(diff(sign(df))>0)+1;
    end
    if not(isempty(excl)),
        ndx=setdiff(ndx,excl);
    end
    p=x(ndx);
    [sort_p,sort_ndx]=sort(p);
    if MAX,
        sort_p=flipud(sort_p);
        sort_ndx=flipud(sort_ndx);
    end
    p=sort_p(1:min(nl,length(p)));
    l=ndx(sort_ndx(1:min(nl,length(p))));
    L(:,t) = l;
    P(:,t) = p;
end


