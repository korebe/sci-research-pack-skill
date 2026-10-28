# Third-Party Notices

This pack redistributes skill files from the repositories below. Each remains
under its original license. The pack's own two orchestrator skills and docs are
MIT.

| Upstream | Stars* | License | Files copied | License file |
|---|---:|---|---|---|
| [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) | 54,965 | MIT | 10 skill dirs (`skills/vendor/*`) | `licenses/scientific-agent-skills-MIT.md` |
| [Boom5426/Nature-Paper-Skills](https://github.com/Boom5426/Nature-Paper-Skills) | 636 | MIT | 16 skill dirs | `licenses/Nature-Paper-Skills-MIT.txt` |
| [labarba/sciwrite](https://github.com/labarba/sciwrite) | 865 | CC-BY-4.0 | 1 skill dir | `licenses/sciwrite-CC-BY-4.0.txt` |
| [WantongC/journal-adapt-writing-skill](https://github.com/WantongC/journal-adapt-writing-skill) | 767 | MIT | 1 skill dir | `licenses/journal-adapt-MIT.txt` |
| [Haojae/scipilot-figure-skill](https://github.com/Haojae/scipilot-figure-skill) | 2,719 | MIT | 1 skill dir | `licenses/scipilot-figure-MIT.txt` |
| [eniktab/scientific-paper-writer](https://github.com/eniktab/scientific-paper-writer) | 31 | MIT | 1 skill dir | `licenses/scientific-paper-writer-MIT.txt` |
| [Yuan1z0825/nature-skills](https://github.com/Yuan1z0825/nature-skills) | 51,019 | Apache-2.0 | 10 skill dirs | `licenses/nature-skills-Apache-2.0.txt` |
| [cavoiie/fluent-cfd-skill](https://github.com/cavoiie/fluent-cfd-skill) | 86 | MIT | 1 skill dir | `licenses/fluent-cfd-MIT.txt` |
| [leima-max/origin-pro-mcp-skill](https://github.com/leima-max/origin-pro-mcp-skill) | 232 | MIT | 1 skill dir + `mcp/origin-pro/` source | `licenses/origin-pro-MIT.txt` |

\* Star counts read from the GitHub API on 2026-10-28; they change.

## Modifications

1. `skills/vendor/nature-shared/SKILL.md`: added
   `metadata: opencode/autoinvoke: false` so the shared reference package is
   not advertised as a standalone skill in OpenCode. Content is otherwise
   unchanged.
2. Directory names are preserved as upstream skill IDs. No skill body was
   edited.
3. `skills/local/journal-pipeline` and `skills/local/cfd-fluent-pipeline` are
   original to this pack (MIT).
4. `mcp/origin-pro/src/origin_pro_mcp/app.py`: upstream 0.2.0 imports
   `mcp.server.fastmcp.FastMCP`, which MCP Python SDK 2.x renamed to
   `mcp.server.mcpserver.MCPServer`. The file now tries the 1.x import and falls
   back to the 2.x one, so the server runs on both SDK lines. Tool code and
   behaviour are unchanged.
5. `skills/vendor/origin-pro/SKILL.md` was written for this pack from the
   upstream `SKILL.md` and `skills/publication-figure.md`; the upstream
   `publication-figure.md` is kept verbatim under `references/`.

## Attribution

- **sciwrite** is based on Dr. Kristin Sainani's *Writing in the Sciences*
  (Stanford, CC-BY lectures), authored by Lorena A. Barba. Retain the
  attribution if you redistribute.
- **Nature-Paper-Skills** and **nature-skills** implement Nature-style
  workflows; they are not affiliated with or endorsed by Nature Portfolio.
- **pyfluent-mcp** is an Ansys project, Apache-2.0. This pack only installs the
  PyPI package; it does not redistribute Ansys code.
- **origin-pro-mcp** is MIT, Copyright © 2026 youngminsw. The MCP source is
  vendored at commit `ff64b124` and the upstream license text is kept at
  `licenses/origin-pro-MIT.txt`.

## What is not included

- No Ansys binaries, license files, or case/data files.
- No Academic Research Skills (CC BY-NC) content; that module is cloned
  separately and remains non-commercial.
- No journal PDFs or paywalled papers.
