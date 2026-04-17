# MATLAB 图像去噪基准项目

一个面向工程与研究复现的 MATLAB 图像去噪基准仓库，提供统一的噪声构造、算法调用、指标评估、结果汇总与图像导出流程。  
你可以把它当作一个可直接扩展的去噪实验框架：新增算法后即可在同一套测试场景下进行横向对比。

## 项目定位

- 统一比较多种传统图像去噪方法在不同噪声下的表现
- 输出可追溯的实验结果（日志、CSV、图像、MAT 文件）
- 保持低耦合结构，便于快速替换算法或新增评价指标

## 核心能力

- 多噪声场景自动化生成
- 多方法批量运行与统一评估
- 支持质量指标与时间指标的综合排名
- 自动输出总图与单图（含中文标注）
- 结果目录按时间戳归档，方便复现实验与版本对比

## 已集成方法

- 小波阈值去噪（VisuShrink）
  - 硬阈值（Hard Threshold）
  - 软阈值（Soft Threshold）
- 小波去噪（BayesShrink）
- 中值预处理 + BayesShrink 混合方案
- Wiener 滤波
- 中值滤波
- 双边滤波

## 支持的噪声类型

- 高斯噪声（可设置标准差）
- 椒盐噪声（可设置密度）
- 斑点噪声（可设置方差）
- 混合噪声（高斯 + 椒盐）

## 仓库结构

```text
.
├── main_advanced_denoising_simulation.m   # 增强版主入口（推荐）
├── main_denoising_simulation.m            # 基础版入口
├── generate_noisy_image.m                 # 噪声生成
├── denoise_with_method.m                  # 算法调度器
├── wavelet_denoise_universal.m            # VisuShrink 小波去噪
├── wavelet_denoise_bayes.m                # BayesShrink 小波去噪
├── wavelet_denoise_wrapper.m              # 兼容封装
├── apply_threshold.m                      # 软/硬阈值函数
├── calculate_threshold.m                  # 阈值计算
├── calculate_metrics.m                    # 基础指标（PSNR/MSE）
├── evaluate_metrics.m                     # 统一评估（PSNR/MSE/SSIM/耗时）
├── compute_composite_score.m              # 综合评分
├── save_case_comparison_figure.m          # 对比图与标注单图导出
├── sanitize_filename.m                    # 文件名清理
└── README.md
```

## 环境要求

### 运行环境

- MATLAB R2022b 或以上（建议 R2024b）
- Windows / Linux / macOS

### 建议工具箱

- Wavelet Toolbox（小波分解与重构相关）
- Image Processing Toolbox（`wiener2`、`medfilt2`、`ssim`、`imbilatfilt` 等）

仓库中部分模块有回退逻辑，但完整功能建议安装上述工具箱。

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/bolt-phm/yanshihao.git
cd yanshihao
```

### 2. 在 MATLAB 中进入目录

```matlab
cd('仓库绝对路径')
```

### 3. 运行增强版主脚本

```matlab
main_advanced_denoising_simulation
```

脚本会自动尝试读取默认测试图像（如 `cameraman.tif`）。  
若未找到，请把测试图像放到仓库目录，或在主脚本中修改输入路径配置。

## 输出目录说明

每次运行会创建一个时间戳目录：

```text
results/
└── run_YYYYMMDD_HHMMSS/
    ├── run_log.txt
    ├── run_summary.txt
    ├── run_config.mat
    ├── all_workspace_data.mat
    ├── all_metrics_ranked.csv
    ├── best_method_by_noise.csv
    ├── global_method_summary.csv
    ├── summary_psnr.png
    ├── summary_ssim.png
    └── case_XX_<noise_case>/
        ├── 00_original.png
        ├── 01_noisy.png
        ├── metrics_ranked.csv
        ├── noisy_metrics.csv
        ├── comparison_top6.png
        └── annotated_tiles/
            ├── tile_01_original_labeled.png
            ├── tile_02_noisy_labeled.png
            └── tile_03...tile_08_method_..._labeled.png
```

### 输出文件用途建议

- `all_metrics_ranked.csv`：全场景全方法指标总表，可直接用于统计分析
- `best_method_by_noise.csv`：每个噪声场景最优方法汇总，可用于报告摘要
- `global_method_summary.csv`：按方法聚合后的均值表现
- `comparison_top6.png`：该场景下 Top 方法可视化大图
- `annotated_tiles/`：每个子图单独导出，适合做演示图排版

## 评分与排序机制

默认综合评分由 `compute_composite_score.m` 计算，使用以下因素：

- PSNR（越高越好）
- SSIM（越高越好）
- MSE（越低越好）
- TimeSec（越低越好）

默认权重：

- PSNR: `0.40`
- SSIM: `0.30`
- MSE: `0.20`（反向）
- TimeSec: `0.10`（反向）

你可以直接修改 `compute_composite_score.m` 中权重，按应用目标调整“质量优先”或“速度优先”的倾向。

## 配置说明

主要配置位于 `main_advanced_denoising_simulation.m`。

### 噪声场景配置

- `noise_cases`：定义噪声类型与参数（如 `sigma`、`density`、`variance`）

### 方法配置

- `method_configs`：定义参与对比的算法、阈值策略、小波基、分解层数等参数

### 运行配置

- 输出目录根路径
- 随机种子 `rng`
- 是否保存中间结果

## 作为框架进行扩展

### 新增去噪算法

1. 在 `denoise_with_method.m` 中添加新的 `case` 分支  
2. 保证输出图像与输入尺寸一致、数据范围正确  
3. 在 `method_configs` 中注册该方法名称与参数  
4. 运行主脚本并检查是否被纳入统一排序

### 新增评价指标

1. 在 `evaluate_metrics.m` 中加入指标计算  
2. 在结果汇总与 CSV 导出处增加对应字段  
3. 如需参与综合评分，更新 `compute_composite_score.m`

### 新增图表/报告输出

参考主脚本内 `summary_psnr.png`、`summary_ssim.png` 的生成流程，按相同数据结构快速扩展。

## 常见问题与排查

### 1. 找不到输入图像

检查主脚本中候选路径配置，或把测试图像放到仓库根目录。

### 2. `ssim`、`imbilatfilt` 等函数不可用

通常是工具箱未安装导致。可先用已实现的回退分支运行，但建议补齐工具箱以保证结果一致性。

### 3. 中文标注显示异常

在 MATLAB 图形设置中指定支持中文的字体，并确保系统字体可用。

### 4. 表格拼接报错（变量列不一致）

检查表格初始化列名与后续追加行的字段是否完全一致，避免动态扩列导致 `vertcat` 失败。

### 5. `groupsummary` 报错

确认传入列为数值列，并逐个指定需要聚合的变量，避免把字符串列误传入 `mean` 计算。

## 复现建议

- 固定 `rng` 随机种子
- 固定输入图像与噪声参数
- 保留每次运行的 `run_config.mat` 与 `run_log.txt`
- 在对比不同代码版本时保留 `results/run_*` 历史目录

## 路线图（Roadmap）

- 增加更多公开数据集的批量评测入口
- 增加更多去噪算法（如 BM3D、DnCNN、FFDNet）
- 增加多次重复实验统计（均值/方差/置信区间）
- 增加自动化报告导出（Markdown/PDF）

## 贡献指南

欢迎提交 Issue 与 Pull Request。

推荐流程：

1. Fork 仓库并创建分支
2. 提交修改与最小复现说明
3. 如涉及算法改动，请附运行结果或对比截图
4. 发起 PR 并说明变更范围与兼容性

## 许可证

当前仓库尚未附带 `LICENSE` 文件。  
如果计划公开分发或二次开发，建议补充标准开源许可证（如 MIT、Apache-2.0、GPL-3.0）。
