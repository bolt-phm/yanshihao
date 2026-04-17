%==========================================================================
% 文件名: denoise_with_method.m
% 描述: 根据方法配置执行去噪
%==========================================================================
function denoised_img = denoise_with_method(noisy_img, method_cfg)

img = im2double(noisy_img);
method_id = lower(string(method_cfg.Id));

switch method_id
    case "wavelet_visu"
        denoised_img = wavelet_denoise_universal( ...
            img, method_cfg.Wavelet, method_cfg.Level, method_cfg.ThresholdType ...
        );

    case "wavelet_bayes"
        denoised_img = wavelet_denoise_bayes( ...
            img, method_cfg.Wavelet, method_cfg.Level, method_cfg.ThresholdType ...
        );

    case "hybrid_median_bayes"
        pre_img = medfilt2(img, [3, 3], "symmetric");
        denoised_img = wavelet_denoise_bayes( ...
            pre_img, method_cfg.Wavelet, method_cfg.Level, method_cfg.ThresholdType ...
        );

    case "wiener2"
        denoised_img = wiener2(img, [5, 5]);

    case "median"
        denoised_img = medfilt2(img, [3, 3], "symmetric");

    case "bilateral"
        if exist("imbilatfilt", "file") == 2
            denoised_img = imbilatfilt(img);
        else
            % 兼容无 imbilatfilt 环境的回退
            denoised_img = medfilt2(img, [3, 3], "symmetric");
        end

    otherwise
        error("未知去噪方法: %s", method_cfg.Id);
end

denoised_img = max(0, min(1, denoised_img));

end

