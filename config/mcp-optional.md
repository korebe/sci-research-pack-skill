# 可选 MCP 清单

主包只自动安装 **Fluent MCP**。下面这些按需自取，不装不影响写作技能。

> 原则：MCP 工具会占用模型上下文。一次只加你当前真正要用的。

---

## 1. Zotero（文献库）★ 推荐

- 仓库：<https://github.com/54yyyu/zotero-mcp>（5,608★，MIT）
- 作用：搜索你的 Zotero 库、读 PDF、取引用、按主题/作者/全文检索。
- 前提：本机装 Zotero，并在 Zotero 设置里开启本地 API。

```bash
uv tool install zotero-mcp-server
zotero-mcp setup          # 自动写入 Claude Desktop 配置
```

OpenCode：

```bash
opencode mcp add zotero --global -- zotero-mcp
```

---

## 2. paper-search（多源检索）★ 推荐

- 仓库：<https://github.com/openags/paper-search-mcp>（2,938★，MIT）
- 作用：arXiv、PubMed、bioRxiv、Semantic Scholar 等统一检索与下载。

```bash
uv tool install paper-search-mcp
opencode mcp add paper-search --global -- paper-search-mcp
```

---

## 3. arXiv（预印本 + LaTeX 源）★ 推荐

- 仓库：<https://github.com/blazickjp/arxiv-mcp-server>（3,237★，Apache-2.0）
- 作用：按章节读 LaTeX 源、从 arXiv 元数据生成 BibTeX、主题订阅。

```bash
opencode mcp add arxiv --global -- uvx arxiv-mcp-server
```

---

## 4. Fluent 的替代桥接：CAE-Agent-Hub

- 仓库：<https://github.com/Cai-aa/CAE-Agent-Hub>（1,187★，MIT）
- 子目录：`MCP/Ansys/Fluent MCP`
- 特点：批处理 journal 比 live session 稳；同时覆盖 Workbench、CFX、ICEM、
  System Coupling、Abaqus、COMSOL、CST。
- 适合：参数化批量算例、流固耦合、需要 Workbench 的场景。

```powershell
git clone https://github.com/Cai-aa/CAE-Agent-Hub
cd "CAE-Agent-Hub\MCP\Ansys\Fluent MCP"
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e .[pyfluent]
Copy-Item .env.example .env
# 填 ANSYS_ROOT / FLUENT_EXE，然后按 README 注册
```

与官方 `ansys-fluent-mcp` 二选一即可，不要同时挂两个 Fluent MCP。

---

## 5. OpenFOAM（无 Fluent 许可证）

- 仓库：<https://github.com/webworn/openfoam-mcp-server>（125★）
- 状态：作者自述 ~75% functional，OpenFOAM 12 求解器迁移未完成，
  许可证字段为 `NOASSERTION`（自行审查）。
- 定位：教学与快速原型，不是生产级 CFD 验证工具。

```bash
git clone https://github.com/webworn/openfoam-mcp-server
cd openfoam-mcp-server
# 按 README 安装依赖并注册 MCP
```

---

## 6. 注册后检查

```powershell
opencode mcp list
```

或在 OpenCode 里 `/mcps`。显示 `connected` 才算可用。

**不要**同时启用两个会启动 Fluent 的 MCP；license 会互相抢。
