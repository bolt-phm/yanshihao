%==========================================================================
% 文件名: compute_composite_score.m
% 描述: 计算综合评分（越大越优）
%==========================================================================
function score = compute_composite_score(psnr_vec, mse_vec, ssim_vec, time_vec)

psnr_n = normalize_minmax(psnr_vec);
mse_n  = 1 - normalize_minmax(mse_vec);   % MSE 越小越好
ssim_n = normalize_minmax(ssim_vec);
time_n = 1 - normalize_minmax(time_vec);  % 时间越小越好

% 权重说明：以质量为主、效率为辅
score = 0.40 * psnr_n + 0.30 * ssim_n + 0.20 * mse_n + 0.10 * time_n;

end

function y = normalize_minmax(x)

x = double(x(:));
valid_mask = isfinite(x);
y = zeros(size(x));

if ~any(valid_mask)
    y(:) = 0;
    return;
end

x_valid = x(valid_mask);
x_min = min(x_valid);
x_max = max(x_valid);

if abs(x_max - x_min) < eps
    y(valid_mask) = 1;
else
    y(valid_mask) = (x_valid - x_min) / (x_max - x_min);
end

y(~valid_mask) = 0;

end

