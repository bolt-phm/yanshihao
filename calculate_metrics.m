%==========================================================================
% 文件名: calculate_metrics.m
% 描述: 计算 MSE 和 PSNR
%==========================================================================
function [psnr_val, mse_val] = calculate_metrics(img_original, img_denoised)
    
    % 确保输入图像类型一致且归一化 (0-1)
    img_original = im2double(img_original);
    img_denoised = im2double(img_denoised);
    
    % --- 1. 计算均方误差 (MSE) ---
    % MSE = (1 / MN) * sum( (I(i,j) - I_hat(i,j))^2 )
    [M, N] = size(img_original);
    error = img_original - img_denoised;
    mse_val = sum(error(:).^2) / (M * N);
    
    % --- 2. 计算峰值信噪比 (PSNR) ---
    % PSNR = 10 * log10(MAX_I^2 / MSE)
    % 对于归一化图像 (0-1)，MAX_I = 1
    
    MAX_I = 1; 
    
    if mse_val == 0
        psnr_val = Inf; % 完美重建
    else
        psnr_val = 10 * log10(MAX_I^2 / mse_val);
    end
end