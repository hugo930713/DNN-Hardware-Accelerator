# DNN-Hardware-Accelerator

本專案為一個基於 FPGA/RTL 的深度神經網路（DNN）硬體加速器設計，實作基本的卷積、ReLU 及 Pooling 運算單元，並提供完整的模擬與驗證流程。

## 目標

- 實現 3x3 卷積、ReLU、Pooling 等 DNN 基本運算之硬體模組。
- 提供可驗證的 RTL 設計，並與 Python 參考結果比對。
- 支援 ModelSim/Questa/Quartus 等主流程模擬與驗證。

## 主要檔案說明

- `conv_3x3.v`：3x3 卷積運算單元 RTL 實作
- `relu.v`：ReLU 運算單元 RTL 實作
- `pooling.v`：Pooling 運算單元 RTL 實作
- `window_buffer_3x3_2d_with_padding.v`：3x3 視窗緩衝區（含 padding）
- `top.v`：頂層整合模組
- `tb_top.v`：頂層測試平台（Testbench）
- `input_image.txt`：測試輸入影像資料

## 目錄結構簡介

- `output_files/`：Quartus 編譯產物（已加入 .gitignore）
- `db/`、`incremental_db/`、`work/`：EDA 工具暫存資料夾（已加入 .gitignore）
- `simulation/`：模擬相關資料夾，含 modelsim/、questa/ 子目錄
- `.qodo/`：自動化工具暫存

## 如何執行模擬/驗證

1. 使用 ModelSim/Questa 開啟 `simulation/modelsim/` 或 `simulation/questa/` 目錄下的 `.do` 腳本。
2. 執行 RTL 模擬，觀察波形與輸出結果。
