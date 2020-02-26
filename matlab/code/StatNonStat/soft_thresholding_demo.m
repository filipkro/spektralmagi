%%%%%%%% VISUAL ILLUSTRATION OF THE SOFT THRESHOLDING OPERATION %%%%%%%
%
% Illustration of the proximal operator for the function \lambda |x| for
% positive \lambda, i.e., the solution to the problem
% minimize_x 0.5 (x-y)^2 + \lambda |x|
% which is given by the soft thresholding operation.
%
% Filip Elvander, December 2019.
%
clc,clear,close all

%%%%% USER PARAMETERS %%%%%%
pause_time = 0.0001;
lambda = 2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nbr_points_y = 100;
nbr_points_x = 150;

y_min = -2*lambda;
y_max = 2*lambda;
y_grid = linspace(y_min,y_max,nbr_points_y)';
x_min = 2*y_min;
x_max = 2*y_max;
x_grid = linspace(x_min,x_max,nbr_points_x)';

data_fit_func = @(x,y) 0.5*(x-y).^2;
pen_func = @(x) lambda*abs(x);
pen = pen_func(x_grid);
x_opt_vec = sign(y_grid).*max(abs(y_grid)-lambda,0);

%%%%%%%% Plotting %%%%%%%
figure(1)
%%%%%%%%
for k_grid = 1:nbr_points_y
    data_fit = data_fit_func(x_grid,y_grid(k_grid));
    tot_obj = data_fit+pen;
    x_opt = x_opt_vec(k_grid);
    %%%%%
    
    
    
    %%%%% Plot of quadratic term + gradient and first order approx %%%%
    subplot(231)
    cla
    plot(x_grid,data_fit,'linewidth',1.5)
    hold on
    plot(x_grid,x_grid-y_grid(k_grid),'--','linewidth',1.5)
    first_order_quad = (x_opt_vec(k_grid)-y_grid(k_grid))*(x_grid-x_opt_vec(k_grid))+0.5*(x_opt_vec(k_grid)-y_grid(k_grid))^2;
    plot(x_grid,first_order_quad,'k--','linewidth',1.5)
    plot(x_opt,0.5*(x_opt_vec(k_grid)-y_grid(k_grid))^2,'ko','linewidth',1.5)
    if k_grid ==1
        lgd = legend('1/2 (x-y)^2','\partial (1/2 (x-y)^2)',...
            'Location','South');
        lgd.FontSize = 12;
        xl = xlabel('x');
        xl.FontSize = 12;
    end
    xlim([x_min,x_max])
    ylim([x_min,x_max])
    grid on
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Plot of penalty term + gradient and first order approx %%%%
    subplot(234)
    cla
    plot(x_grid,pen,'linewidth',1.5)
    hold on
    plot(x_grid,lambda*sign(x_grid),'--','linewidth',1.5)
    if abs(x_opt_vec(k_grid))>0
        first_order_pen = lambda*sign(x_opt_vec(k_grid))*x_grid;
    else
        first_order_pen = (y_grid(k_grid))*x_grid;
    end
    plot(x_grid,first_order_pen,'k--','linewidth',1.5)
    plot(x_opt,lambda*abs(x_opt),'ko','linewidth',1.5)
    %hold off
    if k_grid == 1
        lgd = legend('\lambda |x|','\partial \lambda |x|',...
            'Location','South');
        lgd.FontSize = 12;
        xl = xlabel('x');
        xl.FontSize = 12;
    end
    xlim([x_min,x_max])
    ylim([x_min,x_max])
    grid on
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Plot of total objective + gradient and first order approx %%%%
    subplot(132)
    cla
    h_tot = plot(x_grid,tot_obj,'linewidth',1.5);
    hold on
    h_grad = plot(x_grid,lambda*sign(x_grid)+(x_grid-y_grid(k_grid)),'r--','linewidth',1.5);
    plot(x_grid,first_order_quad+first_order_pen,'k--','linewidth',1.5)
    hold on
    max_obj = max(data_fit+pen);
    h_opt = plot(x_opt,0.5*(x_opt-y_grid(k_grid))^2+lambda*abs(x_opt),'ko','linewidth',1.5);
    h_lambda = plot(x_grid,lambda*ones(size(x_grid)),'m:','linewidth',2);
    h_vec = [h_tot,h_grad,h_opt,h_lambda];
    grid on
    xlim([x_min,x_max])
    ylim(2*[x_min,x_max])
    
    if k_grid == 1
        str_cell = {'1/2 (x-y)^2 +\lambda |x|','\partial (1/2 (x-y)^2 +\lambda |x|)','x_{opt}','\lambda'};
        lgd = legend(h_vec,str_cell,'Location','South');
        lgd.FontSize = 12;
        xl = xlabel('x');
        xl.FontSize = 12;
    end
    
    % Lines marking optimal x, as well as zero
    if abs(x_opt)>0
        title(['\color{black}y = ',num2str(y_grid(k_grid)),', \lambda = ',num2str(lambda)])
        plot([x_opt,x_opt],20*[-1,1],'k:','linewidth',2)
        plot([x_min,x_max],[0,0],'k:','linewidth',2)
    else
        title(['\color{green}y = ',num2str(y_grid(k_grid)),', \lambda = ',num2str(lambda)])
        plot([x_opt,x_opt],20*[-1,1],'g:','linewidth',2)
        plot([x_min,x_max],[0,0],'g:','linewidth',2)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Plot of optimal x (soft thresholding) %%%%
    subplot(133)
    cla
    plot(y_grid(1:k_grid),x_opt_vec(1:k_grid),'color',[0,0.5,0],'linewidth',1.5)
    hold on
    plot(lambda*[1,1],[-5,5],'m:','linewidth',2)
    plot(-lambda*[1,1],[-5,5],'m:','linewidth',2)
    %hold off
    grid on
    xlim([y_min,y_max])
    ylim([x_opt_vec(1),x_opt_vec(end)])
    
    if k_grid ==1
        lgd = legend('x_{opt}','\pm \lambda');
        lgd.FontSize = 12;
        xl = xlabel('y');
        xl.FontSize = 12;
    end
    drawnow
    pause(pause_time)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end


