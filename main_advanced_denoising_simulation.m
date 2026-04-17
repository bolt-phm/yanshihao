%==========================================================================
% 文件名: main_advanced_denoising_simulation.m
% 描述: 单场景多噪声、多方法去噪仿真与自动优选（论文实验增强版）
% 说明:
%   1) 只使用一个场景图像（cameraman.tif），按要求进行多噪声仿真
%   2) 对多种去噪方法进行定量对比（PSNR/MSE/SSIM/耗时）
%   3) 自动计算综合得分并选出每个噪声场景下的最优解
%   4) 自动保存可直接用于论文撰写的图表与数据文件
%==========================================================================

clc;
clear;
close all;

rng(20260417, "twister");

script_dir = fileparts(mfilename("fullpath"));
if isempty(script_dir)
    script_dir = pwd;
end

% --- 输出目录 ---
run_stamp = datestr(now, "yyyymmdd_HHMMSS");
output_root = fullfile(script_dir, "results");
if ~exist(output_root, "dir")
    mkdir(output_root);
end
output_dir = fullfile(output_root, "run_" + string(run_stamp));
if ~exist(output_dir, "dir")
    mkdir(output_dir);
end

diary_file = fullfile(output_dir, "run_log.txt");
diary(diary_file);
diary on;
cleanup_diary = onCleanup(@() diary("off")); %#ok<NASGU>

fprintf("============================================================\n");
fprintf("增强版仿真开始: %s\n", datestr(now, "yyyy-mm-dd HH:MM:SS"));
fprintf("输出目录: %s\n", output_dir);
fprintf("============================================================\n");

% --- 读取单场景图像 ---
candidate_inputs = {fullfile(script_dir, "cameraman.tif"), "cameraman.tif"};
original_img = [];
for i = 1:numel(candidate_inputs)
    if exist(candidate_inputs{i}, "file")
        original_img = imread(candidate_inputs{i});
        break;
    end
end

if isempty(original_img)
    error("未找到测试图像 cameraman.tif。");
end

original_img = im2double(original_img);
if size(original_img, 3) == 3
    original_img = rgb2gray(original_img);
end

% --- 多噪声场景配置（单场景，多噪声） ---
noise_cases = [ ...
    struct("Name", "Gaussian_sigma15",      "Type", "gaussian",        "Sigma", 15, "Density", NaN,  "Variance", NaN), ...
    struct("Name", "Gaussian_sigma25",      "Type", "gaussian",        "Sigma", 25, "Density", NaN,  "Variance", NaN), ...
    struct("Name", "SaltPepper_density005", "Type", "salt_pepper",     "Sigma", NaN,"Density", 0.05, "Variance", NaN), ...
    struct("Name", "Speckle_var002",        "Type", "speckle",         "Sigma", NaN,"Density", NaN,  "Variance", 0.02), ...
    struct("Name", "Mixed_G20_SP005",       "Type", "mixed_gaussian_sp","Sigma", 20, "Density", 0.05, "Variance", NaN) ...
];

% --- 去噪方法配置（含传统/小波增强/混合策略） ---
method_configs = [ ...
    struct("Name", "WaveletVisu_db4_L3_Hard",         "Id", "wavelet_visu",        "Wavelet", "db4",  "Level", 3, "ThresholdType", "hard"), ...
    struct("Name", "WaveletVisu_db4_L3_Soft",         "Id", "wavelet_visu",        "Wavelet", "db4",  "Level", 3, "ThresholdType", "soft"), ...
    struct("Name", "WaveletVisu_sym8_L4_Soft",        "Id", "wavelet_visu",        "Wavelet", "sym8", "Level", 4, "ThresholdType", "soft"), ...
    struct("Name", "WaveletBayes_db4_L3_Soft",        "Id", "wavelet_bayes",       "Wavelet", "db4",  "Level", 3, "ThresholdType", "soft"), ...
    struct("Name", "Hybrid_Median3_Bayes_db4_L3",     "Id", "hybrid_median_bayes", "Wavelet", "db4",  "Level", 3, "ThresholdType", "soft"), ...
    struct("Name", "Wiener2_5x5",                      "Id", "wiener2",             "Wavelet", "",     "Level", 0, "ThresholdType", ""), ...
    struct("Name", "Median_3x3",                       "Id", "median",              "Wavelet", "",     "Level", 0, "ThresholdType", ""), ...
    struct("Name", "Bilateral_Default",                "Id", "bilateral",           "Wavelet", "",     "Level", 0, "ThresholdType", "") ...
];

save(fullfile(output_dir, "run_config.mat"), "noise_cases", "method_configs");

all_metrics = table( ...
    'Size', [0, 8], ...
    'VariableTypes', {'string', 'double', 'string', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'NoiseCase', 'Rank', 'Method', 'PSNR', 'MSE', 'SSIM', 'TimeSec', 'CompositeScore'} ...
);

best_summary = table( ...
    'Size', [0, 7], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'NoiseCase', 'BestMethod', 'PSNR', 'MSE', 'SSIM', 'CompositeScore', 'TimeSec'} ...
);

for n = 1:numel(noise_cases)
    case_cfg = noise_cases(n);
    case_name = string(case_cfg.Name);
    case_folder = fullfile(output_dir, "case_" + num2str(n, "%02d") + "_" + sanitize_filename(case_name));
    if ~exist(case_folder, "dir")
        mkdir(case_folder);
    end

    fprintf("\n[%d/%d] 场景: %s\n", n, numel(noise_cases), case_name);

    noisy_img = generate_noisy_image(original_img, case_cfg);
    [psnr_noisy, mse_noisy, ssim_noisy] = evaluate_metrics(original_img, noisy_img);

    imwrite(original_img, fullfile(case_folder, "00_original.png"));
    imwrite(noisy_img, fullfile(case_folder, "01_noisy.png"));

    num_methods = numel(method_configs);
    method_names = strings(num_methods, 1);
    denoised_images = cell(num_methods, 1);

    % 使用显式列初始化，避免 table 按行扩展触发警告
    case_metrics_raw = table( ...
        strings(num_methods, 1), ...
        nan(num_methods, 1), ...
        nan(num_methods, 1), ...
        nan(num_methods, 1), ...
        nan(num_methods, 1), ...
        nan(num_methods, 1), ...
        'VariableNames', {'Method', 'PSNR', 'MSE', 'SSIM', 'TimeSec', 'CompositeScore'} ...
    );

    for m = 1:num_methods
        method_cfg = method_configs(m);
        method_name = string(method_cfg.Name);

        t0 = tic;
        denoised_img = denoise_with_method(noisy_img, method_cfg);
        time_cost = toc(t0);

        [psnr_v, mse_v, ssim_v] = evaluate_metrics(original_img, denoised_img);

        method_names(m) = method_name;
        denoised_images{m} = denoised_img;

        case_metrics_raw.Method(m) = method_name;
        case_metrics_raw.PSNR(m) = psnr_v;
        case_metrics_raw.MSE(m) = mse_v;
        case_metrics_raw.SSIM(m) = ssim_v;
        case_metrics_raw.TimeSec(m) = time_cost;

        method_file = num2str(m + 1, "%02d") + "_" + sanitize_filename(method_name) + ".png";
        imwrite(denoised_img, fullfile(case_folder, method_file));
    end

    case_metrics_raw.CompositeScore = compute_composite_score( ...
        case_metrics_raw.PSNR, ...
        case_metrics_raw.MSE, ...
        case_metrics_raw.SSIM, ...
        case_metrics_raw.TimeSec ...
    );

    case_metrics_sorted = sortrows(case_metrics_raw, "CompositeScore", "descend");
    case_metrics_sorted.Rank = (1:height(case_metrics_sorted)).';
    case_metrics_sorted = movevars(case_metrics_sorted, "Rank", "Before", "Method");
    case_metrics_sorted.NoiseCase = repmat(case_name, height(case_metrics_sorted), 1);
    case_metrics_sorted = movevars(case_metrics_sorted, "NoiseCase", "Before", "Rank");

    noisy_metrics = table( ...
        case_name, psnr_noisy, mse_noisy, ssim_noisy, ...
        'VariableNames', {'NoiseCase', 'Noisy_PSNR', 'Noisy_MSE', 'Noisy_SSIM'} ...
    );

    writetable(noisy_metrics, fullfile(case_folder, "noisy_metrics.csv"));
    writetable(case_metrics_sorted, fullfile(case_folder, "metrics_ranked.csv"));

    top_row = case_metrics_sorted(1, :);
    best_row = table( ...
        top_row.NoiseCase(1), ...
        top_row.Method(1), ...
        top_row.PSNR(1), ...
        top_row.MSE(1), ...
        top_row.SSIM(1), ...
        top_row.CompositeScore(1), ...
        top_row.TimeSec(1), ...
        'VariableNames', {'NoiseCase', 'BestMethod', 'PSNR', 'MSE', 'SSIM', 'CompositeScore', 'TimeSec'} ...
    );
    best_summary = [best_summary; best_row];

    all_metrics = [all_metrics; case_metrics_sorted(:, all_metrics.Properties.VariableNames)];

    fig_file = fullfile(case_folder, "comparison_top6.png");
    save_case_comparison_figure( ...
        original_img, noisy_img, case_name, ...
        psnr_noisy, mse_noisy, ssim_noisy, ...
        case_metrics_sorted, method_names, denoised_images, fig_file ...
    );

    fprintf("  含噪图指标: PSNR=%.3f dB, MSE=%.6f, SSIM=%.4f\n", psnr_noisy, mse_noisy, ssim_noisy);
    fprintf("  最优方法: %s | PSNR=%.3f | MSE=%.6f | SSIM=%.4f | Score=%.4f\n", ...
        top_row.Method, top_row.PSNR, top_row.MSE, top_row.SSIM, top_row.CompositeScore);
end

% --- 全局汇总 ---
writetable(all_metrics, fullfile(output_dir, "all_metrics_ranked.csv"));
writetable(best_summary, fullfile(output_dir, "best_method_by_noise.csv"));

global_summary = varfun( ...
    @mean, all_metrics, ...
    'InputVariables', {'PSNR', 'MSE', 'SSIM', 'TimeSec', 'CompositeScore', 'Rank'}, ...
    'GroupingVariables', 'Method' ...
);
global_summary = sortrows(global_summary, "mean_CompositeScore", "descend");
writetable(global_summary, fullfile(output_dir, "global_method_summary.csv"));

% --- 汇总图 ---
noise_list = unique(all_metrics.NoiseCase, "stable");
method_list = unique(all_metrics.Method, "stable");
noise_labels_cn = arrayfun(@(x) cn_noise_case(x), noise_list, "UniformOutput", false);
method_labels_cn = arrayfun(@(x) cn_method_name(x), method_list, "UniformOutput", false);

psnr_mat = nan(numel(noise_list), numel(method_list));
ssim_mat = nan(numel(noise_list), numel(method_list));

for i = 1:numel(noise_list)
    for j = 1:numel(method_list)
        row = all_metrics(all_metrics.NoiseCase == noise_list(i) & all_metrics.Method == method_list(j), :);
        if ~isempty(row)
            psnr_mat(i, j) = row.PSNR(1);
            ssim_mat(i, j) = row.SSIM(1);
        end
    end
end

fig1 = figure("Visible", "off", "Position", [100, 100, 1600, 900]);
bar(psnr_mat, "grouped");
grid on;
set(gca, "XTickLabel", noise_labels_cn, "XTickLabelRotation", 15);
xlabel("噪声场景");
ylabel("PSNR (dB)");
title("多噪声场景下各方法 PSNR 对比", "Interpreter", "none");
legend(method_labels_cn, "Location", "eastoutside", "Interpreter", "none");
exportgraphics(fig1, fullfile(output_dir, "summary_psnr.png"), "Resolution", 300);
close(fig1);

fig2 = figure("Visible", "off", "Position", [100, 100, 1600, 900]);
bar(ssim_mat, "grouped");
grid on;
set(gca, "XTickLabel", noise_labels_cn, "XTickLabelRotation", 15);
xlabel("噪声场景");
ylabel("SSIM");
title("多噪声场景下各方法 SSIM 对比", "Interpreter", "none");
legend(method_labels_cn, "Location", "eastoutside", "Interpreter", "none");
exportgraphics(fig2, fullfile(output_dir, "summary_ssim.png"), "Resolution", 300);
close(fig2);

% --- 运行总结文本 ---
fid = fopen(fullfile(output_dir, "run_summary.txt"), "w");
fprintf(fid, "增强版仿真运行时间: %s\n", datestr(now, "yyyy-mm-dd HH:MM:SS"));
fprintf(fid, "输出目录: %s\n\n", output_dir);
fprintf(fid, "每个噪声场景的最优方法:\n");
for i = 1:height(best_summary)
    fprintf(fid, "- %s | %s | PSNR=%.3f | MSE=%.6f | SSIM=%.4f | Score=%.4f\n", ...
        best_summary.NoiseCase(i), best_summary.BestMethod(i), best_summary.PSNR(i), ...
        best_summary.MSE(i), best_summary.SSIM(i), best_summary.CompositeScore(i));
end

if ~isempty(global_summary)
    best_global = global_summary(1, :);
    fprintf(fid, "\n全局平均最优方法:\n");
    fprintf(fid, "- %s | mean_PSNR=%.3f | mean_MSE=%.6f | mean_SSIM=%.4f | mean_Score=%.4f\n", ...
        best_global.Method, best_global.mean_PSNR, best_global.mean_MSE, ...
        best_global.mean_SSIM, best_global.mean_CompositeScore);
end
fclose(fid);

save(fullfile(output_dir, "all_workspace_data.mat"), ...
    "noise_cases", "method_configs", "all_metrics", "best_summary", "global_summary", ...
    "noise_list", "method_list", "psnr_mat", "ssim_mat");

fprintf("\n============================================================\n");
fprintf("仿真完成: %s\n", datestr(now, "yyyy-mm-dd HH:MM:SS"));
fprintf("结果已保存到: %s\n", output_dir);
fprintf("============================================================\n");

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
