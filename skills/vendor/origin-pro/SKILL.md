---
name: origin-pro
description: >-
  Drive OriginLab Origin / OriginPro through the `origin-pro` MCP server:
  build worksheets, plot, apply journal figure styles, run linear or nonlinear
  curve fits, and export PNG/TIFF/EPS/PDF or editable OPJU projects. Use when
  the user wants Origin rather than matplotlib — 用 Origin 画图、OriginPro
  作图、可编辑的 Origin 图、导出 OPJU、Origin 拟合、给 Origin 图排版。
  Not for Python/R plotting (use nature-figure or scipilot-figure).
license: MIT
---

# Origin Pro 执行器

本技能只干一件事：把「画什么」变成 Origin 里的真实对象。判断画什么、是否该画，不在这里。

## 0. 三个图技能的分工

| 技能 | 决定什么 |
|---|---|
| `figure-planner` | 这张图要证明哪个 claim，缺哪张图 |
| `nature-figure` / `scipilot-figure` | 尺寸、字体、配色、分辨率、多面板规范 |
| `origin-pro`（本技能） | 在 Origin 里把上述规范执行出来，并导出可验证的文件 |

顺序不能反。跳过前两步直接 `create_graph`，得到的是一张能看但投不出去的图。

## 1. 前置检查（每次会话开头做一遍）

1. **系统**：Windows。`origin-pro` 通过 COM 调 Origin，macOS/Linux 用不了。
2. **Origin 已启动**：先手动打开 Origin（2020 或更新）。MCP 不会替你启动它。
3. **MCP 已连接**：客户端里应能看到 `origin-pro` 的 23 个工具。看不到就先修 MCP，不要试着绕过。
4. **有没有未保存的工作**：`new_project` 会清空当前 Origin 会话。调用前必须问用户。

四项任一不满足，直接说明缺什么，不要用 `run_labtalk` 硬试。

## 2. 工具清单

**项目**：`new_project` `save_project(file_path="")` `load_project(file_path)`

**数据**：`create_worksheet(book_name, sheet_name="Sheet1")`、`set_worksheet_data(book_name, sheet_name, columns, column_names="")`、`get_worksheet_data`、`import_csv_to_worksheet(file_path, book_name="", delimiter=",")`、`list_worksheets`

**绘图**：`create_graph(graph_name, data_book, data_sheet, x_col, y_col, plot_type="scatter", y_error_col=0, title="")`、`add_plot_to_graph(...)`、`set_axis_labels(graph_name, x_label, y_label, title)`、`set_axis_range(graph_name, x_min, x_max, y_min, y_max)`、`export_graph(graph_name, file_path, format="png", width=600, height=400, dpi=300)`

`plot_type` 取值：`scatter` `line` `line+symbol` `column` `bar` `area` `histogram` `box` `contour` `3d_scatter` `3d_surface` `pie` `bubble`

**样式**：`apply_publication_style(graph_name, x_label, y_label, x_min, x_max, y_min, y_max, legend_entries, legend_position="top-right")`、`set_plot_style`、`set_graph_font`、`set_legend`、`set_tick_style`

**分析**：`curve_fit(data_book, data_sheet, x_col, y_col, function="line", y_error_col=0)`、`list_fitting_functions`

**高级**：`run_labtalk(script)`、`get_labtalk_variable(name)`

**批量导出**：`export_all_graphs(output_dir, format="png", dpi=300, width=800, height=600)`

列号从 1 开始，`0` 表示「没有这一列」（如 `y_error_col=0`）。

## 3. 标准流程

```text
create_worksheet("Fig1", "Sheet1")
  → set_worksheet_data("Fig1", "Sheet1", columns="[[0,1,2,3],[1.0,2.1,2.9,4.2]]", column_names="X,Y")
  → create_graph("Fig1A", "Fig1", "Sheet1", x_col=1, y_col=2, plot_type="scatter")
  → add_plot_to_graph("Fig1A", "Fig1", "Sheet1", x_col=1, y_col=3)     # 第二组数据
  → apply_publication_style("Fig1A", x_label="Time (h)", y_label="Concentration (mM)")
  → export_graph("Fig1A", "<项目>/figures/Fig1A.tif", format="tif", dpi=600)
```

要点：

- **一次建一个图页，命名跟正文一致**（`Fig1A` 而不是 `Graph1`）。导出文件名必须能对上正文引用。
- `columns` 是 JSON 数组的数组：外层每个元素是一列，内层是这一列的值。列长度必须一致。
- 已有数据优先 `import_csv_to_worksheet`，不要手工拼 JSON。
- 多面板图在 Origin 里就分成 `Fig1A` / `Fig1B` 单独导出，拼版交给排版环节；不要在 Origin 里硬拼。

## 4. 期刊默认样式

用户没指定时，`apply_publication_style` 之后再确认这几项：

| 项 | 值 |
|---|---|
| 字体 | Arial（中文图用 Arial + 宋体，数字与拉丁字母仍走 Arial） |
| 轴标题 | 加粗，含单位，格式 `Quantity (unit)` |
| 刻度 | 朝内 |
| 边框 | 四边闭合 |
| 网格线 | 无 |
| 背景 | 白 |
| 配色 | 色盲安全（蓝/红/绿/橙/紫/青），不用彩虹色 |

多面板图的字号、线宽、标记大小必须全图统一；改一个图就要同步改其余图。

## 5. 拟合

`curve_fit` 返回的是 Origin 的拟合结果。写进论文前必须报告：

- 函数形式（`list_fitting_functions` 里的哪个，或自定义表达式）
- 参数值与标准误
- R² 或调整后 R²
- 数据点数 n 与拟合参数个数
- 是否加权（用了 `y_error_col` 就是加权）

只给 R² 不给参数误差的拟合，不能进正文。

## 6. 失败模式

| 现象 | 原因 | 处理 |
|---|---|---|
| 工具调用卡住不返回 | Origin 弹了模态对话框（保存提示、许可证、更新提醒） | 去 Origin 窗口点掉，再重试 |
| `Dispatch` 失败 / COM 报错 | Origin 没启动，或位数不匹配（32/64 位） | 手动启动 Origin；确认装的是 64 位版本 |
| 导出的文件 0 字节 | 图页不存在或名字写错 | 先用 `list_worksheets` / `run_labtalk` 确认对象名 |
| 中文变方框 | 字体没设 | `set_graph_font` 指定中文字体后再导出 |
| 样式改了一个图，别的没变 | Origin 样式是逐图页的 | 对每个图页分别调用 `apply_publication_style` |
| MCP 启动即报 `No module named 'mcp.server.fastmcp'` | 装的是 PyPI 上的旧包，或 `mcp` SDK 版本与代码不匹配 | 用包内源码重装：`.\.venv\Scripts\python.exe -m pip install --upgrade .\mcp\origin-pro` |

## 7. 交付前检查

- [ ] 导出的文件存在且大小正常（`export_graph` 返回值里有路径，自己核一遍）
- [ ] 分辨率 ≥ 300 dpi；线条图优先矢量（EPS/PDF/SVG），照片类用 TIFF
- [ ] 轴标题带单位，量符号斜体
- [ ] 图例文字与正文、图注完全一致
- [ ] 配色在灰度下仍可区分
- [ ] 原始 `.opju` 已保存（审稿人要可编辑源文件时能拿出来）
- [ ] 图注里的 n、误差棒定义、统计检验与图内实际一致

## 8. 与 CFD 流程的衔接

`cfd-fluent-pipeline` 走到「出图」时，如果用户要 Origin 图：

- 残差、monitor、网格无关性曲线 → `line` 或 `line+symbol`，x 轴用对数时先确认 `set_axis_range` 与刻度类型
- 实验 vs 仿真的对比 → `scatter` + 误差棒（`y_error_col`）
- 云图、矢量图是 Fluent 导出的位图，不要塞进 Origin 当数据图；只在 Origin 里做拼版说明

---

内容改编自 [leima-max/origin-pro-mcp-skill](https://github.com/leima-max/origin-pro-mcp-skill)（MIT，Copyright © 2026 youngminsw）。原始 `publication-figure.md` 见 `references/`。
