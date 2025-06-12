# Window Buffer 仿真問題解決檢查清單

## 問題描述

仿真結果與期望值不一致：

- 仿真第一個 window: data_out8 = -83
- 期望第一個 window: data_out8 = 127

## 解決步驟

### 1. 確認使用正確的 Verilog 文件

- 確認仿真使用的是 `window_buffer_3x3_2d_with_padding.v`
- 檢查文件是否包含最新的修正邏輯

### 2. 重新編譯仿真

```bash
# 在Quartus中重新編譯項目
# 或者使用命令行重新編譯
```

### 3. 檢查關鍵修正點

確認 window buffer 包含以下修正：

#### 時序邏輯修正

```verilog
// 在第二行開始時推進line buffer
if (row == 1 && col == 0)
begin
  // 推進 line buffer - 在第二行開始時推進
  for (i = 0; i < MAX_WIDTH; i = i + 1)
  begin
    line0[i] <= line1[i];
    line1[i] <= line2[i];
  end
end
```

#### 索引映射修正

```verilog
// 第二行：中間行 - 修正索引映射
data_out3 <= (row == 1 && col == 1) ? 0 : line1[col-2];  // 左中 - 修正索引
data_out4 <= line1[col-1];                               // 中心
data_out5 <= (col == img_width-1) ? 0 : line1[col];      // 右中

// 第三行：下方行 - 修正索引映射
data_out6 <= (row == 1 && col == 1) ? 0 : line2[col-2];  // 左下 - 修正索引
data_out7 <= line2[col-1];                               // 下中
data_out8 <= (col == img_width-1) ? 0 : line2[col];      // 右下
```

### 4. 仿真波形檢查

在仿真中檢查以下信號：

#### 在 row=1, col=0 時（第二行開始）

- `line0` 應該全為 0
- `line1` 應該包含第一行數據：[-5, -83, -61, -39, 82, -96, -29, 22]
- `line2` 應該包含第一行數據：[-5, -83, -61, -39, 82, -96, -29, 22]

#### 在 row=1, col=1 時（第一個 window）

- `line2[1]` 應該是 127
- `data_out8` 應該是 127

### 5. 預期結果

第一個 window 應該是：

```
     0    0    0
     0   -5  -83
     0  -94  127
```

卷積結果應該是：-44

### 6. 如果問題持續

1. 檢查 testbench 是否正確
2. 檢查時鐘和復位信號
3. 檢查輸入數據的時序
4. 提供仿真波形進行進一步分析

## 驗證腳本

運行以下 Python 腳本來驗證修正後的邏輯：

```bash
python test_final_index_fix.py
```

這應該顯示所有 window 都與期望值一致。
