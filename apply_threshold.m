%==========================================================================
% 文件名: apply_threshold.m
% 描述: 实现硬阈值和软阈值函数
%==========================================================================
function coeff_out = apply_threshold(coeff_in, T, type)
% coeff_in: 输入的小波系数
% T: 阈值
% type: 'hard' 或 'soft'

    if strcmpi(type, 'hard')
        % 硬阈值: 保留大于T的系数，小于T的系数置零
        coeff_out = coeff_in .* (abs(coeff_in) >= T);
        
    elseif strcmpi(type, 'soft')
        % 软阈值: 大于T的系数向零收缩 T，小于T的系数置零
        
        % 符号函数 sgn(w)
        sgn_w = sign(coeff_in);
        
        % 计算收缩值 |w| - T
        abs_w_minus_T = abs(coeff_in) - T;
        
        % 软阈值公式: sgn(w) * max(0, |w| - T)
        coeff_out = sgn_w .* max(0, abs_w_minus_T);
        
    else
        error('未知阈值类型: 必须是 "hard" 或 "soft"');
    end
end