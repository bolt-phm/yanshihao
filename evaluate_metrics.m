%==========================================================================
% 文件名: evaluate_metrics.m
% 描述: 统一计算 PSNR / MSE / SSIM
%==========================================================================
function [psnr_val, mse_val, ssim_val] = evaluate_metrics(img_original, img_denoised)

[psnr_val, mse_val] = calculate_metrics(img_original, img_denoised);

ref = im2double(img_original);
out = im2double(img_denoised);

if exist("ssim", "file") == 2
    try
        ssim_val = ssim(out, ref);
    catch
        % 回退估计（避免因工具箱/版本差异导致中断）
        ref_var = max(var(ref(:)), eps);
        ssim_val = max(0, 1 - mse_val / ref_var);
    end
else
    ref_var = max(var(ref(:)), eps);
    ssim_val = max(0, 1 - mse_val / ref_var);
end

end

