%==========================================================================
% 文件名: wavelet_denoise_wrapper.m
% 描述: 封装小波分解->阈值处理->重构的全流程 (接受外部阈值)
%==========================================================================
function denoised_img = wavelet_denoise_wrapper(noisy_img, wname, level, T_external, threshold_type)
    
    % --- 1. 小波分解 (DWT) ---
    [coeffs, S] = wavedec2(noisy_img, level, wname);
    
    % --- 2. 阈值设定 ---
    % 直接使用外部传入的 T 值
    T = T_external;
    
    % --- 3. 对细节系数进行阈值处理 ---
    L_A = prod(S(1, :)); 
    coeffs_out = coeffs;
    current_idx = L_A + 1;
    
    % 遍历所有细节系数 C_H, C_V, C_D (从最高层 level 到 level 1)
    for k = 1:level
        det_size = S(k + 1, :); 
        L = prod(det_size);
        
        % H, V, D 细节系数
        for m = 1:3 
            coeffs_out(current_idx : current_idx + L - 1) = ...
                apply_threshold(coeffs(current_idx : current_idx + L - 1), T, threshold_type);
            current_idx = current_idx + L;
        end
    end
    
    % --- 4. 小波重构 (IDWT) ---
    denoised_img = waverec2(coeffs_out, S, wname);

end