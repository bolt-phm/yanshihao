%==========================================================================
% 文件名: save_case_comparison_figure.m
% 描述: 保存单个噪声场景下的 Top-6 可视化对比图
%==========================================================================
function save_case_comparison_figure( ...
    original_img, noisy_img, case_name, ...
    psnr_noisy, mse_noisy, ssim_noisy, ...
    case_metrics_sorted, method_names, denoised_images, output_file)

fig = figure("Visible", "off", "Position", [100, 100, 1500, 2000]);
tl = tiledlayout(fig, 4, 2, "TileSpacing", "compact", "Padding", "compact");
out_dir = fileparts(output_file);
tile_dir = fullfile(out_dir, "annotated_tiles");
if ~exist(tile_dir, "dir")
    mkdir(tile_dir);
end

% 4 行 2 列布局：每行两个子图，共 8 幅（紧凑排版）
title_01 = "1. 原始图像";
nexttile(tl, 1);
imshow(original_img);
title(title_01, "Interpreter", "none", "FontSize", 16);
export_single_annotated_panel(original_img, title_01, fullfile(tile_dir, "tile_01_original_labeled.png"));

title_02 = sprintf("2. 含噪图像\nPSNR=%.2f MSE=%.4g SSIM=%.4f", psnr_noisy, mse_noisy, ssim_noisy);
nexttile(tl, 2);
imshow(noisy_img);
title(title_02, "Interpreter", "none", "FontSize", 16);
export_single_annotated_panel(noisy_img, title_02, fullfile(tile_dir, "tile_02_noisy_labeled.png"));

max_show = min(6, height(case_metrics_sorted));
for k = 1:max_show
    method_name = case_metrics_sorted.Method(k);
    method_name_cn = cn_method_name(method_name);
    idx = find(method_names == method_name, 1);
    if isempty(idx)
        continue;
    end

    nexttile(tl, k + 2);
    imshow(denoised_images{idx});
    method_title = sprintf("%d. %s\nPSNR=%.2f MSE=%.4g SSIM=%.4f", ...
        k + 2, method_name_cn, case_metrics_sorted.PSNR(k), case_metrics_sorted.MSE(k), case_metrics_sorted.SSIM(k));
    title(method_title, ...
        "Interpreter", "none", "FontSize", 16);

    tile_name = sprintf("tile_%02d_method_%s_labeled.png", k + 2, safe_filename(string(method_name)));
    export_single_annotated_panel(denoised_images{idx}, method_title, fullfile(tile_dir, tile_name));
end

for k = max_show+1:6
    ax = nexttile(tl, k + 2);
    axis(ax, "off");
end

case_name_cn = cn_noise_case(case_name);
title(tl, "场景：" + case_name_cn + " | 综合评分前六方法对比", "Interpreter", "none", "FontSize", 20);
exportgraphics(fig, output_file, "Resolution", 300);
close(fig);

end

function export_single_annotated_panel(img, title_text, file_path)
f = figure("Visible", "off", "Position", [100, 100, 900, 760]);
imshow(img);
title(title_text, "Interpreter", "none", "FontSize", 12);
exportgraphics(f, file_path, "Resolution", 300);
close(f);
end

function out = cn_method_name(name_in)
name_str = string(name_in);
switch name_str
    case "WaveletVisu_db4_L3_Hard"
        out = "小波Visu(db4,L3)-硬阈值";
    case "WaveletVisu_db4_L3_Soft"
        out = "小波Visu(db4,L3)-软阈值";
    case "WaveletVisu_sym8_L4_Soft"
        out = "小波Visu(sym8,L4)-软阈值";
    case "WaveletBayes_db4_L3_Soft"
        out = "小波Bayes(db4,L3)-软阈值";
    case "Hybrid_Median3_Bayes_db4_L3"
        out = "中值预处理+Bayes";
    case "Wiener2_5x5"
        out = "维纳滤波(5x5)";
    case "Median_3x3"
        out = "中值滤波(3x3)";
    case "Bilateral_Default"
        out = "双边滤波(默认)";
    otherwise
        out = name_str;
end
end

function out = safe_filename(text_in)
text_val = char(string(text_in));
out = regexprep(text_val, '[^\w\-]', '_');
out = regexprep(out, '_+', '_');
out = regexprep(out, '^_+|_+$', '');
if isempty(out)
    out = 'unnamed';
end
end

function out = cn_noise_case(name_in)
name_str = string(name_in);
switch name_str
    case "Gaussian_sigma15"
        out = "纯高斯噪声(σ=15)";
    case "Gaussian_sigma25"
        out = "纯高斯噪声(σ=25)";
    case "SaltPepper_density005"
        out = "椒盐噪声(密度=0.05)";
    case "Speckle_var002"
        out = "斑点噪声(方差=0.02)";
    case "Mixed_G20_SP005"
        out = "混合噪声(G20 + 椒盐5%)";
    otherwise
        out = name_str;
end
end
