# SCI Research Pack

> 面向 **Nature / Cell / Science / SCI** 的论文写作 + CFD 仿真 Agent 整合包。
> 44 个技能，1 个官方 Fluent MCP，1 个可选 Origin MCP，6 个 slash command，支持 OpenCode / Claude Code / Codex / Claude Desktop。

- **写作主线**：证据 → 结构 → 写作 → 润色 → 图表 → 统计 → 引用 → 模拟审稿 → 回复 → 投稿
- **仿真主线**：物理 → 网格 → 求解 → 收敛 → 验证 → 出图 → Methods
- **出图**：matplotlib / R（默认）或 OriginPro（可选，Windows）
- **不造假**：不编引用、不编数据、不把"相关"写成"因果"

---

## 快速开始

### Windows

```powershell
cd path\to\sci-research-pack

# 1) 只装技能（默认 full，装到 OpenCode）
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

# 2) 同时装 Fluent MCP（需要本机有 Fluent + 许可证）
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -WithFluent

# 2b) 同时装 Origin MCP（Windows + OriginPro 2020 及以上）
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -WithOrigin

# 3) 装到多个客户端
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Clients opencode,claude,codex

# 4) 自检
.\verify.ps1 -Clients opencode,claude,codex
```

装完打开 OpenCode，输入 `/paper` 或 `/cfd`。

### 四个客户端装到哪

`-Clients`（bash 是 `--clients`）可取：`opencode`、`claude`、`codex`、`claude-desktop`，可任意组合。

| 客户端 | 技能目录 | 斜杠命令 | MCP 配置 |
|---|---|---|---|
| OpenCode | `~/.config/opencode/skills/` | `~/.config/opencode/commands/` | `opencode.json` → `mcp.servers` |
| Claude Code | `~/.claude/skills/` | `~/.claude/commands/` | `~/.claude.json` → `mcpServers` |
| Codex CLI | `~/.agents/skills/` | 无（用 `/skills` 或 `$技能名`） | `~/.codex/config.toml` → `[mcp_servers.<name>]` |
| Claude Desktop | 无目录，上传 zip | 无 | `%APPDATA%\Claude\claude_desktop_config.json` |

三个反直觉的地方：

- **Codex 的技能目录是 `~/.agents/skills`，不是 `~/.codex/skills`。** `~/.codex` 只放 `config.toml`。
- **Codex 没有自定义斜杠命令。** 本包的 `/paper`、`/cfd` 对 Codex 不生效，改用 `/skills` 选 `journal-pipeline`，或直接打 `$journal-pipeline`。
- **Claude Desktop 不读任何技能目录。** 加 `-Clients claude-desktop` 时脚本会把技能打包到 `dist/claude-skills/<id>.zip`，再到应用内 `Settings → Capabilities → Skills` 逐个上传；它的 MCP 配置改完必须从托盘退出重开才生效。

细节见 [`docs/08-客户端接入.md`](docs/08-客户端接入.md)。

### 只想要精简版

```powershell
.\install.ps1 -Profile core                 # 25 个上游 + 2 个调度器
.\install.ps1 -Profile writing              # 只装论文线（31 个上游）
.\install.ps1 -Profile sim                  # 只装仿真线（11 个上游）
.\install.ps1 -Clients opencode,claude      # 同时装到 Claude Code
```

`origin-pro` 属于论文线，`core` 和 `sim` 不含它。

### macOS / Linux

```bash
cd sci-research-pack
./install.sh
./install.sh --profile core --with-fluent
./install.sh --clients opencode,claude,codex
./install.sh --help                          # 全部参数
```

---

## 包含什么

### 论文线（31 个技能）

| 阶段 | 技能 | 来自 |
|---|---|---|
| 分诊 | `paper-workflow` | Nature-Paper-Skills |
| 文献 | `literature-review` `paper-lookup` | K-Dense |
| 拆解范文 | `nature-paper-xray` | nature-skills |
| 期刊适配 | `journal-adapt` | journal-adapt |
| 论证 | `claim-source-verification` `manuscript-optimizer` | Nature-Paper-Skills |
| 起草 | `scientific-writing` `write-scientific-manuscript` `results-section-revision` | Nature-Paper-Skills |
| 文风 | `scientific-prose-style` `anti-defensive-writing` | Nature-Paper-Skills |
| 润色 | `sciwrite` `nature-polishing` | sciwrite / nature-skills |
| 实时期刊规则 | `scientific-paper-writer` | scientific-paper-writer |
| 图表 | `figure-planner` `nature-figure` `scipilot-figure` `scientific-visualization` | 三个来源 |
| Origin 出图 | `origin-pro`（可选 MCP） | origin-pro-mcp-skill |
| 统计 | `stats-reporting-audit` `statistical-analysis` `nature-statistics` `uncertainty-and-units` | 三个来源 |
| 引用 | `citation-verifier` `nature-citation` `nature-ref-verifier` | 两个来源 |
| 审稿 | `paper-reviewer` `nature-reviewer` | 两个来源 |
| 回复 | `rebuttal-response` `nature-response` | 两个来源 |
| 投稿 | `submission-audit` `nature-portfolio-playbook` `nature-paper2word` | Nature-Paper / nature-skills |

### 仿真线（11 个技能）

| 技能 | 用途 |
|---|---|
| `fluent-cfd` | Fluent/PyFluent 工作流纪律、收敛诊断、验证清单 |
| `fluidsim` | Python 谱方法/LBM，无 Fluent 许可证时的替代 |
| `openpiv` | PIV 实验数据 |
| `cantera` | 燃烧/化学动力学 |
| `pybamm` | 电池电化学 |
| `simpy` | 离散事件仿真 |
| `uncertainty-and-units` | 不确定度传播、单位一致性 |
| `statistical-analysis` | 统计检验、效应量、CI |
| `scientific-visualization` | 科研可视化 |
| `literature-review` / `paper-lookup` | 仿真参数与文献依据 |

### 调度器（本包自带，MIT）

| 技能 | 作用 |
|---|---|
| `journal-pipeline` | 顶刊论文六道门：选刊 → 证据 → 结构 → 文风 → 诚信 → 审稿 |
| `cfd-fluent-pipeline` | CFD 七道门：物理 → 网格 → 求解 → 试跑 → 收敛 → 验证 → 报告 |

调度器不写正文，只决定"现在该用哪个专家技能"，并强制输出证据缺口。

---

## 目录结构

```
sci-research-pack/
├─ install.ps1 / install.sh     一键安装
├─ verify.ps1                   环境自检
├─ uninstall.ps1                只删本包安装的内容
├─ manifest.json                模块、来源、Star、许可证
├─ skills/
│  ├─ vendor/                   42 个上游技能（已内置，离线可用）
│  └─ local/                    2 个调度器
├─ mcp/
│  └─ origin-pro/               Origin MCP 源码（可选，Windows）
├─ commands/                    /paper /figure /review /revision /journal-fit /cfd
├─ config/
│  ├─ opencode.mcp.jsonc        OpenCode V2 MCP 片段
│  ├─ codex.config.toml         Codex 片段
│  ├─ claude_desktop_config.json
│  ├─ fluent.env.example
│  └─ mcp-optional.md           Zotero / paper-search / arXiv / OpenFOAM
├─ docs/
│  ├─ 01-技能路由表.md          ★ 先读这个
│  ├─ 02-Nature写作规范.md
│  ├─ 03-Cell写作规范.md
│  ├─ 04-Science写作规范.md
│  ├─ 05-投稿前检查清单.md
│  ├─ 06-CFD验证清单.md
│  ├─ 07-故障排查.md
│  └─ 08-客户端接入.md          OpenCode / Claude Code / Codex / Claude Desktop
├─ templates/
│  ├─ cover-letter.md
│  ├─ response-to-reviewers.md
│  └─ cfd-report.md
├─ dist/
│  └─ claude-skills/*.zip       装 Claude Desktop 时生成，供应用内上传
├─ licenses/                    上游许可证原文
└─ THIRD_PARTY_NOTICES.md
```

---

## 典型用法

> 下面的 `/paper`、`/cfd` 是 OpenCode 和 Claude Code 的命令。Codex 用户把 `/paper 需求` 换成 `/skills` 选 `journal-pipeline` 再描述需求（或 `$journal-pipeline`）；Claude Desktop 直接在对话里说需求即可。

### 1. 从零写一篇 Nature 子刊论文

```
/paper 我要写一篇关于 <主题> 的论文，目标 Nature Communications
```

Agent 会按 Gate 1→6 走：先确认期刊与文章类型，再逼你列出 claim→evidence 映射，然后才动笔。

### 2. 已有草稿，只差投稿

```
/paper 帮我审一遍这篇稿子，目标 Cell，重点看论证和统计
/review
/journal-fit
```

### 3. 审稿意见回复

```
/revision 把这三个审稿人的意见逐条回复，附 response letter
```

### 4. CFD 论文

```
/cfd 做一个 Re=50000 的弯管压降算例，网格无关性要做，最后按论文 Methods 写
```

Agent 会在 `connect` 前提醒 license 占用；收敛判断要求残差 + monitor + 守恒 + 物理合理性四项全过。

### 5. 画投稿级图

```
/figure 把这组数据做成 Nature 风格的多面板图，要色盲安全
```

---

## Fluent MCP

本包安装的是 **ANSYS 官方** [`ansys/pyfluent-mcp`](https://github.com/ansys/pyfluent-mcp)（Apache-2.0，64★，2026-07 发布，活跃维护）。

```powershell
.\install.ps1 -WithFluent -Clients opencode,claude,codex,claude-desktop
```

它会：

1. 在包目录创建 `.venv`
2. `pip install ansys-fluent-mcp`
3. 把 `ansys-fluent` 注册到每个 `-Clients` 指定的客户端：
   - OpenCode：有 CLI 时用 `opencode mcp add`，否则合并 `opencode.json`
   - Claude Code：`claude mcp add --scope user`
   - Codex：向 `~/.codex/config.toml` 追加 `[mcp_servers.ansys-fluent]`（含 `tool_timeout_sec = 600`，防止长求解被默认超时掐断）
   - Claude Desktop：合并 `claude_desktop_config.json` 的 `mcpServers`，改完需从托盘退出重开

四个客户端共用同一个 `.venv` 和同一个 `ansys-fluent-mcp.exe`，删掉 `.venv` 会一起失效。

**硬性前提**：本机安装并授权 Ansys Fluent。MCP 只负责执行，不负责判断物理是否正确。

20 个工具分五组：

- 会话：`connect` `disconnect` `session_status` `solver_status`
- Schema：`find_api` `get_help` `get_state` `get_targeted_context`
- 命名对象：`list_named_objects` `find_named_object` `select_named_objects`
- 执行：`run_code` `validate_code`
- 报告：`summarize_setup` `simulation_report` `screenshot` `mesh_quality` `list_fields` `compare_files`

> `run_code` 等于在 Fluent 会话里执行任意 Python。只跑你读过的代码。

没有 Fluent 许可证？用 `fluidsim` 技能，或见 `config/mcp-optional.md` 里的 OpenFOAM 方案。

---

## Origin MCP（可选，仅 Windows）

Origin 图的价值在于**可编辑**：审稿人要 `.opju`、要改字号、要换配色，Origin 都能给，matplotlib 导出的位图不能。本包内置 [`leima-max/origin-pro-mcp-skill`](https://github.com/leima-max/origin-pro-mcp-skill)（MIT，232★，v0.2.0）的 MCP 源码和配套技能 `origin-pro`。

```powershell
.\install.ps1 -WithOrigin -Clients opencode,claude,codex,claude-desktop
```

它会：

1. 复用包目录的 `.venv`（与 Fluent MCP 共用）
2. 从 `mcp/origin-pro/` 本地源码 `pip install`，不联网取包
3. 把 `origin-pro` 注册到每个 `-Clients` 指定的客户端

**硬性前提**：Windows + 已安装 OriginPro 2020 或更新版本。它走 COM，macOS/Linux 装不了；`install.sh` 在非 Windows 上会直接跳过。

**和 Fluent MCP 的关键区别：Origin 必须你自己先打开。** MCP 只连上正在运行的 Origin 实例，不会替你启动，也不会替你关掉未保存的工程。

23 个工具分六组：

- 项目：`new_project` `save_project` `load_project` `export_all_graphs`
- 数据：`create_worksheet` `set_worksheet_data` `get_worksheet_data` `import_csv_to_worksheet` `list_worksheets`
- 绘图：`create_graph` `add_plot_to_graph` `set_axis_labels` `set_axis_range` `export_graph`
- 样式：`apply_publication_style` `set_plot_style` `set_graph_font` `set_legend` `set_tick_style`
- 分析：`curve_fit` `list_fitting_functions`
- 高级：`run_labtalk` `get_labtalk_variable`

`origin-pro` 技能负责执行顺序（先定 claim，再定样式，最后导出并核对文件大小），`figure-planner` 和 `nature-figure` 仍负责决定图画什么、多大尺寸。三者顺序反了，得到的就是一张能看但投不出去的图。

> `run_labtalk` 等于在 Origin 里执行任意 LabTalk 脚本。只跑你读过的脚本。

**依赖平衡**：`ansys-common-mcp` 要求 `mcp<3` 且 `fastmcp>=3`，后者要求 `mcp>=2.3`；而 Origin 上游代码写的是 1.x 的 `mcp.server.fastmcp`。本包在 `app.py` 里做了双版本导入（1.x 用 `FastMCP`，2.x 用 `MCPServer`），所以两者共用一个 venv 不打架。不要手动把 `mcp` 钉到 1.x，会弄坏 Fluent MCP。

---

## 选装：Academic Research Skills

ARS 是完整的 "research → write → review → revise → finalize" 十阶段流水线，
但它有自己的 38-agent 编排和 CC BY-NC 许可（非商用）。

```powershell
.\install.ps1 -WithARS
```

它会被克隆到 `vendor/opencode-academic-research`，然后按该仓库自己的
`install.sh` 安装。**与 `journal-pipeline` 二选一作为主入口**，不要同时驱动。

---

## 设计原则

1. **技能是判断，MCP 是手。** 工具能跑通不等于物理正确、论证成立。
2. **一个阶段只叫一个专家。** 调度器先分诊，避免 44 个技能互相打架。
3. **证据缺口显式化。** 没有数据就写 `[DATA NEEDED]`，不猜。
4. **期刊规则实时核对。** 包里的数字是参考值；投稿前必须看当期 Guide for Authors。
5. **不碰你的东西。** 安装只写技能/命令目录；卸载只删本包列出的 ID。

---

## 验证与卸载

```powershell
.\verify.ps1 -Clients opencode,claude,codex,claude-desktop
.\uninstall.ps1 -Clients opencode,claude,codex
```

`verify` 按客户端分别核对技能目录、命令文件、MCP 条目、Claude Desktop 的 zip、venv、Fluent 安装和 Origin 的 COM 注册。`uninstall` 只删本包装进去的技能目录和命令文件，不动别的技能、不删 `.venv`、不删文稿；MCP 条目要按 `docs/08-客户端接入.md` 第 8 节手动清。

---

## 来源与许可

| 仓库 | Star | 许可 |
|---|---:|---|
| K-Dense-AI/scientific-agent-skills | 54,965 | MIT |
| Yuan1z0825/nature-skills | 51,019 | Apache-2.0 |
| Haojae/scipilot-figure-skill | 2,719 | MIT |
| labarba/sciwrite | 865 | CC-BY-4.0 |
| WantongC/journal-adapt-writing-skill | 767 | MIT |
| Boom5426/Nature-Paper-Skills | 636 | MIT |
| cavoiie/fluent-cfd-skill | 86 | MIT |
| ansys/pyfluent-mcp | 64 | Apache-2.0 |
| eniktab/scientific-paper-writer | 31 | MIT |
| leima-max/origin-pro-mcp-skill | 232 | MIT |

Star 数为 2026-10-28 GitHub API 读数。完整许可见 `licenses/` 与
`THIRD_PARTY_NOTICES.md`。

---

## 一句话

**这套包不替你写论文，它逼你把论文写对。**
