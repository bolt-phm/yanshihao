# MATLAB 小波阈值图像去噪项目

## 项目说明
本仓库整理了毕业设计所需的核心 MATLAB 代码，包含：
- 基础版仿真脚本（`main_denoising_simulation.m`）
- 增强版仿真脚本（`main_advanced_denoising_simulation.m`）
- 小波去噪、阈值处理、指标评估、图像输出等功能函数

## 运行环境
- MATLAB R2022b 及以上（建议 R2024b）
- 需要图像处理/小波相关函数支持（`wavedec2`、`detcoef2`、`wiener2`、`medfilt2` 等）

## 快速运行
在 MATLAB 命令行进入仓库目录后执行：

```matlab
main_advanced_denoising_simulation
```

运行后将自动在 `results/run_时间戳/` 下生成：
- 各噪声场景排名结果（CSV）
- 总体汇总结果（CSV）
- 大图对比图（4x2）
- 单图带标注导出（`annotated_tiles/`）
- 运行日志与 MAT 数据

## 主要入口文件
- `main_advanced_denoising_simulation.m`：多噪声、多方法、自动优选、自动保存结果
- `save_case_comparison_figure.m`：输出中文标注大图与单图

## 备注
- 该仓库仅保留必要代码，不包含论文、任务书、开题等文档。
- 结果图可直接用于论文配图与答辩 PPT 二次制作。
