%==========================================================================
% 文件名: wavelet_denoise_bayes.m
% 描述: BayesShrink 自适应阈值小波去噪（按子带自适应）
%==========================================================================
function denoised_img = wavelet_denoise_bayes(noisy_img, wname, level, threshold_type)

img = im2double(noisy_img);
[coeffs, S] = wavedec2(img, level, wname);

% 用最细尺度对角子带估计噪声标准差
[~, ~, D1] = detcoef2("all", coeffs, S, 1);
sigma_n = median(abs(D1(:))) / 0.6745;
if ~isfinite(sigma_n) || sigma_n <= 0
    sigma_n = sqrt(max(var(img(:)), eps));
end

% 从最粗层近似系数开始，自顶向下逐层重构
A = appcoef2(coeffs, S, wname, level);
for lev = level:-1:1
    [H, V, D] = detcoef2("all", coeffs, S, lev);

    Th = local_bayes_threshold(H, sigma_n);
    Tv = local_bayes_threshold(V, sigma_n);
    Td = local_bayes_threshold(D, sigma_n);

    Ht = apply_threshold(H, Th, threshold_type);
    Vt = apply_threshold(V, Tv, threshold_type);
    Dt = apply_threshold(D, Td, threshold_type);

    target_size = S(level - lev + 3, :);
    A = idwt2(A, Ht, Vt, Dt, wname, target_size);
end

denoised_img = max(0, min(1, A));

end

function T = local_bayes_threshold(subband, sigma_n)
sigma_y2 = mean(subband(:).^2);
sigma_x = sqrt(max(sigma_y2 - sigma_n^2, 0));
T = (sigma_n^2) / max(sigma_x, eps);
if ~isfinite(T)
    T = sigma_n;
end
end

