% FUNCTION [ phiRCB, phiB, phiC, thetaRange ] = rcb( R, L, [epsilon] )
% 
% The function calculates the robust Capon beamformer. This implementation 
% follows (please cite if used): 
%
% J. Li, P. Stoica, and Z. Wang, "On Robust Capon Beamforming and Diagonal
% Loading", IEEE Transactions on Signal Processing, Vol 51, No. 7, pp.
% 1702-1715, July 2003. 
%
% Parameters:
%   R           Input data.
%   L           Number of grid points to evaluate over.
%   epsilon     Size of the allowed uncertainty sphere (default 1.0).
%   phiRCB      The robust Capon beamformer.
%   phiR        The classical beamformer.
%   phiB        The Capon beamformer.
%   thetaRange  The considered frequency grid. 
%
% By Zhisong Wang. Last modified by Andreas Jakobsson, 160104.
%
function [ phiRCB, phiB, phiC, thetaRange ] = rcb( R, L, epsilon )
   
    if nargin<3,
        epsilon = 1;
    end
    thetaRange = linspace( -90, 90, L );
 
    [U,Gamma,V] = svd(R);
    Gamma       = real(Gamma);
    Gamma_vec   = diag(Gamma);
    lambda_max  = max(diag(Gamma));
    lambda_min  = min(diag(Gamma));
    num = 1; 
    m   = length(R);
    phiB = zeros(L,1);    phiC = phiB;    phiRCB = phiB;
    for assumed_theta=thetaRange,
        a_bar=exp(-pi*j*sin(assumed_theta*pi/180)*[0:m-1].');       % Assumed steering vector (without calibration errors).
        phiC(num)=real(1/(a_bar'*inv(R)*a_bar));                    % Capon estimate.
        Delay_sum_weight=a_bar/m;
        phiB(num)=real(Delay_sum_weight'*R*Delay_sum_weight);       % Classical beamformer estimate.

        % Compute RCB using Newton's method 
        z=U'*a_bar;
        error=10;       % Initially set a large number for the error

        % Lower bound for the optimal solution of lambda
        LowerBound=(norm(a_bar)/sqrt(epsilon)-1)/lambda_max;
        lambda_n=LowerBound;	
        while (abs(error)>1e-6) 
                 [lambda_m,error]=RCB_Newton(lambda_n,z,Gamma_vec,m,epsilon);
                 lambda_n=lambda_m;	
        end
        lambda_Newton=lambda_n;     % Optimal solution for lambda

        for qq=1:m 
          gamma_i=Gamma(qq,qq);
          QQ(qq,qq)=1/(1/lambda_Newton^2 + 2/lambda_Newton*gamma_i + gamma_i^2)*gamma_i;
          QQ_scale(qq,qq)=QQ(qq,qq)*gamma_i;
        end	

        Z = 1/(z'*QQ*z);	
        phiRCB(num) = real(Z*(z'*QQ_scale*z)/m); 

        num=num+1;
    end
end




function [lambda_new,error]=RCB_Newton(lambda,z,Gamma_vec,m,epsilon)
    f=sum(abs(z).^2./(lambda*Gamma_vec + ones(m,1)).^2)-epsilon;
    f_derivative= -2*sum(abs(z).^2.*Gamma_vec./(lambda*Gamma_vec + ones(m,1)).^3);
    lambda_new=lambda-(f/f_derivative);
    error=sum(abs(z).^2./(lambda_new*Gamma_vec + ones(m,1)).^2)-epsilon;
end