%==========================================================================
% 文件名: wavelet_denoise_universal.m
% 描述: 基于 VisuShrink 通用阈值的小波去噪（支持硬/软阈值）
%==========================================================================
function denoised_img = wavelet_denoise_universal(noisy_img, wname, level, threshold_type)

img = im2double(noisy_img);
[coeffs, S] = wavedec2(img, level, wname);

% 用最细尺度对角子带估计噪声标准差
[~, ~, D1] = detcoef2("all", coeffs, S, 1);
sigma_n = median(abs(D1(:))) / 0.6745;
if ~isfinite(sigma_n) || sigma_n <= 0
    sigma_n = sqrt(max(var(img(:)), eps));
end

T = sigma_n * sqrt(2 * log(numel(img)));

% 从最粗层近似系数开始，自顶向下逐层重构
A = appcoef2(coeffs, S, wname, level);
for lev = level:-1:1
    [H, V, D] = detcoef2("all", coeffs, S, lev);

    Ht = apply_threshold(H, T, threshold_type);
    Vt = apply_threshold(V, T, threshold_type);
    Dt = apply_threshold(D, T, threshold_type);

    target_size = S(level - lev + 3, :);
    A = idwt2(A, Ht, Vt, Dt, wname, target_size);
end

denoised_img = max(0, min(1, A));

end

