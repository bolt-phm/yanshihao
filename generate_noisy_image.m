%==========================================================================
% 文件名: generate_noisy_image.m
% 描述: 生成多种噪声类型的含噪图像
%==========================================================================
function noisy_img = generate_noisy_image(original_img, case_cfg)

img = im2double(original_img);
noise_type = lower(string(case_cfg.Type));

switch noise_type
    case "gaussian"
        sigma = case_cfg.Sigma / 255;
        noisy_img = img + sigma * randn(size(img));

    case "salt_pepper"
        noisy_img = imnoise(img, "salt & pepper", case_cfg.Density);

    case "speckle"
        noisy_img = imnoise(img, "speckle", case_cfg.Variance);

    case "mixed_gaussian_sp"
        sigma = case_cfg.Sigma / 255;
        temp = img + sigma * randn(size(img));
        noisy_img = imnoise(temp, "salt & pepper", case_cfg.Density);

    otherwise
        error("未知噪声类型: %s", case_cfg.Type);
end

noisy_img = max(0, min(1, noisy_img));

end

