%==========================================================================
% 文件名: calculate_threshold.m
% 描述: 计算通用阈值 (VisuShrink)
%==========================================================================
function T = calculate_threshold(noise_var, img_size)
    sigma = sqrt(noise_var);
    N = prod(img_size); % 图像像素总数 M * N
    T = sigma * sqrt(2 * log(N)); 
end