%==========================================================================
% 文件名: main_multiple_experiments.m
%==========================================================================

clc; clear all; close all;

%% --- 1. 参数设置与环境准备 ---
% 读取图像 (使用 Matlab 自带的 'cameraman.tif')
original_img = imread('cameraman.tif');
original_img = im2double(original_img); 
if size(original_img, 3) == 3
    original_img = rgb2gray(original_img);
end

% 基础仿真参数
decomp_level = 3;       % 小波分解层数
wavelet_name = 'db4';   % 小波基函数

% 结果存储初始化 (PSNR 表格，共 8 列)
Results_PSNR = table('Size', [0, 8], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'实验名称', 'PSNR_含噪', ...
                       '硬阈值_小', '硬阈值_优', '硬阈值_大', ...
                       '软阈值_小', '软阈值_优', '软阈值_大'});

% 结果存储初始化 (MSE 表格，共 8 列)
Results_MSE = table('Size', [0, 8], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'实验名称', 'MSE_含噪', ...
                       '硬阈值_小', '硬阈值_优', '硬阈值_大', ...
                       '软阈值_小', '软阈值_优', '软阈值_大'});

exp_count = 0;
% 存储所有图像数据 (用于多图对比)
Image_Data = {}; 

%% --- 2. 实验 A: 纯高斯噪声 (sigma=15 和 sigma=25) ---
GAUSSIAN_SIGMA = [15, 25]; 
for sigma = GAUSSIAN_SIGMA
    exp_count = exp_count + 1;
    
    % --- 2.1 阈值定义 (VisuShrink 基准 T) ---
    noise_var = (sigma / 255)^2;
    T_base = calculate_threshold(noise_var, size(original_img)); 
    
    T_small = 0.5 * T_base;   % 过小阈值
    T_opt = T_base;           % 最优阈值 (VisuShrink)
    T_large = 1.5 * T_base;   % 过大阈值

    % 生成含噪图像 (仅生成一次)
    noisy_img = original_img + sqrt(noise_var) * randn(size(original_img));
    noisy_img = max(0, min(1, noisy_img));
    
    % --- 2.2 执行去噪，计算 PSNR/MSE，并存储图像数据 ---
    
    [psnr_n, mse_n] = calculate_metrics(original_img, noisy_img);
    
    % 硬阈值处理
    H_small = wavelet_denoise_wrapper(noisy_img, wavelet_name, decomp_level, T_small, 'hard');
    [psnr_h_s, mse_h_s] = calculate_metrics(original_img, H_small);
    H_opt = wavelet_denoise_wrapper(noisy_img, wavelet_name, decomp_level, T_opt, 'hard');
    [psnr_h_o, mse_h_o] = calculate_metrics(original_img, H_opt);
    H_large = wavelet_denoise_wrapper(noisy_img, wavelet_name, decomp_level, T_large, 'hard');
    [psnr_h_l, mse_h_l] = calculate_metrics(original_img, H_large);
    
    % 软阈值处理
    S_small = wavelet_denoise_wrapper(noisy_img, wavelet_name, decomp_level, T_small, 'soft');
    [psnr_s_s, mse_s_s] = calculate_metrics(original_img, S_small);
    S_opt = wavelet_denoise_wrapper(noisy_img, wavelet_name, decomp_level, T_opt, 'soft');
    [psnr_s_o, mse_s_o] = calculate_metrics(original_img, S_opt);
    S_large = wavelet_denoise_wrapper(noisy_img, wavelet_name, decomp_level, T_large, 'soft');
    [psnr_s_l, mse_s_l] = calculate_metrics(original_img, S_large);

    % 存储定量结果 (PSNR 表)
    exp_name = ['纯高斯噪声, \sigma=', num2str(sigma)];
    Results_PSNR = add_row_to_table_multi(Results_PSNR, exp_name, psnr_n, ...
                                     psnr_h_s, psnr_h_o, psnr_h_l, ...
                                     psnr_s_s, psnr_s_o, psnr_s_l);
    
    % 存储定量结果 (MSE 表)
    Results_MSE = add_row_to_table_multi_mse(Results_MSE, exp_name, mse_n, ...
                                     mse_h_s, mse_h_o, mse_h_l, ...
                                     mse_s_s, mse_s_o, mse_s_l);

    % 存储图像数据用于绘图 (存储所有 6 种结果及 PSNR/MSE)
    Image_Data{exp_count} = struct('Name', exp_name, 'Noisy', noisy_img, ...
                                   'PSNR_N', psnr_n, 'MSE_N', mse_n, ...
                                   'H_S', H_small, 'H_O', H_opt, 'H_L', H_large, ...
                                   'S_S', S_small, 'S_O', S_opt, 'S_L', S_large, ...
                                   'PSNR_H_S', psnr_h_s, 'PSNR_H_O', psnr_h_o, 'PSNR_H_L', psnr_h_l, ...
                                   'PSNR_S_S', psnr_s_s, 'PSNR_S_O', psnr_s_o, 'PSNR_S_L', psnr_s_l, ...
                                   'MSE_H_S', mse_h_s, 'MSE_H_O', mse_h_o, 'MSE_H_L', mse_h_l, ...
                                   'MSE_S_S', mse_s_s, 'MSE_S_O', mse_s_o, 'MSE_S_L', mse_s_l);
end


%% --- 3. 实验 B: 混合噪声 (高斯 + 椒盐) ---
MIXED_SIGMA = 20;    % 高斯噪声标准差
SP_DENSITY = 0.05;   % 椒盐噪声密度 5%

exp_count = exp_count + 1;
noise_var = (MIXED_SIGMA / 255)^2; 
T_opt = calculate_threshold(noise_var, size(original_img)); 

% 生成含噪图像 (高斯 + 椒盐)
noisy_img_g = original_img + sqrt(noise_var) * randn(size(original_img));
noisy_img_mixed = imnoise(noisy_img_g, 'salt & pepper', SP_DENSITY);
noisy_img_mixed = max(0, min(1, noisy_img_mixed));

% 执行去噪（仅使用最优阈值 T_opt）
H_opt = wavelet_denoise_wrapper(noisy_img_mixed, wavelet_name, decomp_level, T_opt, 'hard');
[psnr_h_o, mse_h_o] = calculate_metrics(original_img, H_opt);
S_opt = wavelet_denoise_wrapper(noisy_img_mixed, wavelet_name, decomp_level, T_opt, 'soft');
[psnr_s_o, mse_s_o] = calculate_metrics(original_img, S_opt);

[psnr_n, mse_n] = calculate_metrics(original_img, noisy_img_mixed);

% 存储定量结果 (非最优阈值结果用 NaN 占位)
exp_name = ['混合噪声(G:', num2str(MIXED_SIGMA), ', SP:', num2str(SP_DENSITY*100), '%)'];

% PSNR 表
Results_PSNR = add_row_to_table_multi(Results_PSNR, exp_name, psnr_n, ...
                                 NaN, psnr_h_o, NaN, ...
                                 NaN, psnr_s_o, NaN);
% MSE 表
Results_MSE = add_row_to_table_multi_mse(Results_MSE, exp_name, mse_n, ...
                                 NaN, mse_h_o, NaN, ...
                                 NaN, mse_s_o, NaN);

% 存储图像数据用于绘图 (非最优的图像/PSNR/MSE 置为 NaN)
Image_Data{exp_count} = struct('Name', exp_name, 'Noisy', noisy_img_mixed, ...
                               'PSNR_N', psnr_n, 'MSE_N', mse_n, ...
                               'H_S', NaN, 'H_O', H_opt, 'H_L', NaN, ...
                               'S_S', NaN, 'S_O', S_opt, 'S_L', NaN, ...
                               'PSNR_H_S', NaN, 'PSNR_H_O', psnr_h_o, 'PSNR_H_L', NaN, ...
                               'PSNR_S_S', NaN, 'PSNR_S_O', psnr_s_o, 'PSNR_S_L', NaN, ...
                               'MSE_H_S', NaN, 'MSE_H_O', mse_h_o, 'MSE_H_L', NaN, ...
                               'MSE_S_S', NaN, 'MSE_S_O', mse_s_o, 'MSE_S_L', NaN);


%% --- 4. 结果输出 (定量分析) ---
disp(' ');
disp('==================== PSNR 性能对比结果 (峰值信噪比，单位: dB) ====================');
disp(['小波基: ', wavelet_name, ', 分解层数: ', num2str(decomp_level)]);
disp(Results_PSNR);
disp('注：硬/软阈值后的 PSNR 分别对应：过小(0.5T), 最优(T), 过大(1.5T) 阈值');
disp('====================================================================================');

disp(' ');
disp('==================== MSE 性能对比结果 (均方误差) ====================');
disp(['小波基: ', wavelet_name, ', 分解层数: ', num2str(decomp_level)]);
disp(Results_MSE);
disp('注：硬/软阈值后的 MSE 越小越好。N/A 表示结果不适用或未计算');
disp('=====================================================================');


%% --- 5. 可视化对比 (生成多张图 - 包含所有阈值对比) ---
for k = 1:length(Image_Data)
    data = Image_Data{k};
    figure('Name', ['实验结果对比 - ', data.Name]);
    
    % 使用 2 行 4 列的布局 (2x4)
    
    % 第一行：原图，含噪图，硬阈值 (小, 优)
    subplot(2, 4, 1); imshow(original_img); title('1. 原始图像');
    subplot(2, 4, 2); 
    imshow(data.Noisy); 
    title(['2. 含噪图 (PSNR: ', conditional_psnr_str(data.PSNR_N), ' dB)']);
    
    % 硬阈值
    psnr_h_s_str = conditional_psnr_str(data.PSNR_H_S);
    psnr_h_o_str = conditional_psnr_str(data.PSNR_H_O);
    psnr_h_l_str = conditional_psnr_str(data.PSNR_H_L);
    
    subplot(2, 4, 3); imshow(data.H_S); title(['3. 硬阈值-小 (', psnr_h_s_str, ')']);
    subplot(2, 4, 4); imshow(data.H_O); title(['4. 硬阈值-优 (', psnr_h_o_str, ')']);
    
    % 第二行：硬阈值 (大)，软阈值 (小, 优, 大)
    psnr_s_s_str = conditional_psnr_str(data.PSNR_S_S);
    psnr_s_o_str = conditional_psnr_str(data.PSNR_S_O);
    psnr_s_l_str = conditional_psnr_str(data.PSNR_S_L);
    
    subplot(2, 4, 5); imshow(data.H_L); title(['5. 硬阈值-大 (', psnr_h_l_str, ')']);
    
    % 软阈值
    subplot(2, 4, 6); imshow(data.S_S); title(['6. 软阈值-小 (', psnr_s_s_str, ')']);
    subplot(2, 4, 7); imshow(data.S_O); title(['7. 软阈值-优 (', psnr_s_o_str, ')']);
    subplot(2, 4, 8); imshow(data.S_L); title(['8. 软阈值-大 (', psnr_s_l_str, ')']);
    
    sgtitle(['【', num2str(k), '】实验对比：', data.Name, ' (PSNR单位：dB)']);
end

%% --- 6. 辅助函数 ---

% 运行指定阈值的去噪
function [psnr_out, mse_out] = run_and_evaluate_threshold(original_img, noisy_img, wname, level, T_value, threshold_type)
    % 检查 T_value 是否为 NaN (对应混合噪声中不适用的阈值)
    if isnan(T_value)
        psnr_out = NaN;
        mse_out = NaN;
        return;
    end
    % 调用修改后的 wavelet_denoise_wrapper，传入 T_value
    denoised_img = wavelet_denoise_wrapper(noisy_img, wname, level, T_value, threshold_type);
    [psnr_out, mse_out] = calculate_metrics(original_img, denoised_img);
end

% 添加多阈值对比结果行到 PSNR 表格
function T = add_row_to_table_multi(T, exp_name, psnr_n, psnr_h_s, psnr_h_o, psnr_h_l, psnr_s_s, psnr_s_o, psnr_s_l)
    NewRow = table({exp_name}, psnr_n, psnr_h_s, psnr_h_o, psnr_h_l, psnr_s_s, psnr_s_o, psnr_s_l, ...
        'VariableNames', {'实验名称', 'PSNR_含噪', ...
                           '硬阈值_小', '硬阈值_优', '硬阈值_大', ...
                           '软阈值_小', '软阈值_优', '软阈值_大'});
    T = [T; NewRow];
end

% 新增辅助函数：添加多阈值对比结果行到 MSE 表格
function T_mse = add_row_to_table_multi_mse(T_mse, exp_name, mse_n, mse_h_s, mse_h_o, mse_h_l, mse_s_s, mse_s_o, mse_s_l)
    NewRow = table({exp_name}, mse_n, mse_h_s, mse_h_o, mse_h_l, mse_s_s, mse_s_o, mse_s_l, ...
        'VariableNames', {'实验名称', 'MSE_含噪', ...
                           '硬阈值_小', '硬阈值_优', '硬阈值_大', ...
                           '软阈值_小', '软阈值_优', '软阈值_大'});
    T_mse = [T_mse; NewRow];
end

% 辅助函数：根据 PSNR 值是否为有限值 (非 NaN) 来格式化输出字符串
function psnr_str = conditional_psnr_str(psnr_val)
    if isfinite(psnr_val)
        psnr_str = num2str(psnr_val, '%.2f');
    else
        psnr_str = 'N/A';
    end
end
