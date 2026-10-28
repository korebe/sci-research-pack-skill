# SCI Research Pack

> 面向 **Nature / Cell / Science / SCI** 的论文写作 + CFD 仿真 Agent 整合包。
> 43 个技能，1 个官方 Fluent MCP，6 个 slash command，一套可直接执行的检查清单。

- **写作主线**：证据 → 结构 → 写作 → 润色 → 图表 → 统计 → 引用 → 模拟审稿 → 回复 → 投稿
- **仿真主线**：物理 → 网格 → 求解 → 收敛 → 验证 → 出图 → Methods
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

# 3) 自检
.\verify.ps1
```

装完打开 OpenCode，输入 `/paper` 或 `/cfd`。

### 只想要精简版

```powershell
.\install.ps1 -Profile core                 # 25 个上游 + 2 个调度器
.\install.ps1 -Profile writing              # 只装论文线
.\install.ps1 -Profile sim                  # 只装仿真线
.\install.ps1 -Clients opencode,claude      # 同时装到 Claude Code
```

### macOS / Linux

```bash
cd sci-research-pack
./install.sh
./install.sh --profile core --with-fluent
```

---

## 包含什么

### 论文线（30 个技能）

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
│  ├─ vendor/                   41 个上游技能（已内置，离线可用）
│  └─ local/                    2 个调度器
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
│  └─ 07-故障排查.md
├─ templates/
│  ├─ cover-letter.md
│  ├─ response-to-reviewers.md
│  └─ cfd-report.md
├─ licenses/                    上游许可证原文
└─ THIRD_PARTY_NOTICES.md
```

---

## 典型用法

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
.\install.ps1 -WithFluent
```

它会：

1. 在包目录创建 `.venv`
2. `pip install ansys-fluent-mcp`
3. 把 `ansys-fluent` 注册到 OpenCode（有 CLI 时用 `opencode mcp add`，否则合并 `opencode.json`）

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
2. **一个阶段只叫一个专家。** 调度器先分诊，避免 30 个技能互相打架。
3. **证据缺口显式化。** 没有数据就写 `[DATA NEEDED]`，不猜。
4. **期刊规则实时核对。** 包里的数字是参考值；投稿前必须看当期 Guide for Authors。
5. **不碰你的东西。** 安装只写技能/命令目录；卸载只删本包列出的 ID。

---

## 验证与卸载

```powershell
.\verify.ps1          # 技能数、命令、MCP、venv、Fluent 安装
.\uninstall.ps1       # 列出将删除的目录，确认后删除
```

MCP 配置和 `~/.codex/config.toml` 不会被自动删除。

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

Star 数为 2026-10-28 GitHub API 读数。完整许可见 `licenses/` 与
`THIRD_PARTY_NOTICES.md`。

---

## 一句话

**这套包不替你写论文，它逼你把论文写对。**
