#!/usr/bin/env bash
# SCI Research Pack installer (macOS / Linux)
#
# Usage:
#   ./install.sh                                # full profile, OpenCode
#   ./install.sh --profile core                 # 精简版
#   ./install.sh --clients opencode,claude      # 多客户端
#   ./install.sh --clients codex                # 只装 Codex
#   ./install.sh --clients claude-desktop       # 只配 Claude Desktop 的 MCP
#   ./install.sh --with-fluent                  # 同时装 Fluent MCP
#   ./install.sh --dry-run                      # 只看会做什么
#
# Clients:
#   opencode        skills + commands + MCP
#   claude          Claude Code (CLI): skills + commands + MCP
#   codex           Codex CLI: skills + MCP
#   claude-desktop  Claude Desktop (GUI): MCP only, skills are uploaded as zip
#
set -euo pipefail

PROFILE="full"
CLIENTS="opencode"
WITH_FLUENT=0
DRY_RUN=0
FORCE=0
PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALL_CLIENTS="opencode claude codex claude-desktop"
MCP_NAME="ansys-fluent"

usage() {
  sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --clients) CLIENTS="$2"; shift 2 ;;
    --with-fluent) WITH_FLUENT=1; shift ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; echo "Try: ./install.sh --help"; exit 1 ;;
  esac
done

c_cyan='\033[36m'; c_green='\033[32m'; c_yellow='\033[33m'; c_gray='\033[90m'; c_red='\033[31m'; c_reset='\033[0m'
step() { printf "\n${c_cyan}[>] %s${c_reset}\n" "$1"; }
ok()   { printf "  ${c_green}[OK] %s${c_reset}\n" "$1"; }
skip() { printf "  ${c_gray}[--] %s${c_reset}\n" "$1"; }
warn() { printf "  ${c_yellow}[!!] %s${c_reset}\n" "$1"; }
err()  { printf "  ${c_red}[XX] %s${c_reset}\n" "$1"; }

# ---------------------------------------------------------------- profile

case "$PROFILE" in
  writing) IDS="paper-workflow scientific-writing write-scientific-manuscript scientific-prose-style anti-defensive-writing results-section-revision manuscript-optimizer claim-source-verification citation-verifier stats-reporting-audit figure-planner nature-figure nature-portfolio-playbook paper-reviewer rebuttal-response submission-audit sciwrite journal-adapt scipilot-figure scientific-paper-writer nature-writing nature-polishing nature-citation nature-ref-verifier nature-reviewer nature-response nature-paper2word nature-paper-xray nature-statistics nature-shared" ;;
  sim) IDS="fluent-cfd fluidsim openpiv cantera pybamm simpy uncertainty-and-units statistical-analysis scientific-visualization literature-review paper-lookup" ;;
  core) IDS="paper-workflow scientific-writing write-scientific-manuscript scientific-prose-style anti-defensive-writing results-section-revision manuscript-optimizer claim-source-verification citation-verifier stats-reporting-audit figure-planner nature-figure nature-portfolio-playbook paper-reviewer rebuttal-response submission-audit sciwrite journal-adapt scipilot-figure scientific-paper-writer fluent-cfd fluidsim uncertainty-and-units statistical-analysis scientific-visualization" ;;
  full) IDS="paper-workflow scientific-writing write-scientific-manuscript scientific-prose-style anti-defensive-writing results-section-revision manuscript-optimizer claim-source-verification citation-verifier stats-reporting-audit figure-planner nature-figure nature-portfolio-playbook paper-reviewer rebuttal-response submission-audit sciwrite journal-adapt scipilot-figure scientific-paper-writer nature-writing nature-polishing nature-citation nature-ref-verifier nature-reviewer nature-response nature-paper2word nature-paper-xray nature-statistics nature-shared fluent-cfd fluidsim openpiv cantera pybamm simpy uncertainty-and-units statistical-analysis scientific-visualization literature-review paper-lookup" ;;
  *) err "unknown profile: $PROFILE (expected full|core|writing|sim)"; exit 1 ;;
esac
LOCAL_IDS="journal-pipeline cfd-fluent-pipeline"

# ---------------------------------------------------------------- client paths

# Skills are read from different roots per client. These are the documented
# user-scope locations; project-scope variants exist but are not touched here.
skills_root() {
  case "$1" in
    opencode) echo "$HOME/.config/opencode/skills" ;;
    claude)   echo "$HOME/.claude/skills" ;;
    codex)    echo "$HOME/.agents/skills" ;;          # NOT ~/.codex/skills
    *)        echo "" ;;
  esac
}

commands_root() {
  case "$1" in
    opencode) echo "$HOME/.config/opencode/commands" ;;
    claude)   echo "$HOME/.claude/commands" ;;
    *)        echo "" ;;                              # codex / claude-desktop: none
  esac
}

# Claude Desktop config file (MCP only)
desktop_config_path() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
    Linux)  echo "$HOME/.config/Claude/claude_desktop_config.json" ;;
    # Git Bash / MSYS / Cygwin on Windows: APPDATA is a Windows path.
    MINGW*|MSYS*|CYGWIN*) echo "${APPDATA:-$HOME/AppData/Roaming}/Claude/claude_desktop_config.json" ;;
    *)      echo "$HOME/.config/Claude/claude_desktop_config.json" ;;
  esac
}

has_client() {
  local needle="$1" c
  IFS=',' read -ra arr <<< "$CLIENTS"
  for c in "${arr[@]}"; do [[ "$c" == "$needle" ]] && return 0; done
  return 1
}

# Resolve a working Python 3. On Windows `python3` usually resolves to the
# Microsoft Store alias stub, which fails only when actually executed -- so
# probe by running it, not by `command -v`.
find_python() {
  local cand
  for cand in python3 python py; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys' >/dev/null 2>&1; then
      echo "$cand"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------- validation

for c in ${CLIENTS//,/ }; do
  case " $ALL_CLIENTS " in
    *" $c "*) ;;
    *) err "unknown client: $c (expected one of: $ALL_CLIENTS)"; exit 1 ;;
  esac
done

printf "\n  SCI Research Pack  ·  top-journal writing + CFD\n"
printf "  -------------------------------------------------\n"
printf "  pack    : %s\n" "$PACK_ROOT"
printf "  profile : %s\n" "$PROFILE"
printf "  clients : %s\n" "$CLIENTS"
[[ $DRY_RUN -eq 1 ]] && printf "  mode    : DRY RUN\n"

step "Checking prerequisites"
command -v git >/dev/null || { err "git not found"; exit 1; }
ok "$(git --version)"
[[ -d "$PACK_ROOT/skills/vendor" ]] || { err "missing skills/vendor"; exit 1; }

# ---------------------------------------------------------------- skills

install_skill() {
  local id="$1" srcroot="$2"
  local src="$srcroot/$id"
  [[ -f "$src/SKILL.md" ]] || { warn "missing SKILL.md: $src"; return 1; }
  local any=1 c root dst has_root=0
  IFS=',' read -ra arr <<< "$CLIENTS"
  for c in "${arr[@]}"; do
    root="$(skills_root "$c")"
    [[ -z "$root" ]] && continue          # claude-desktop: skills via zip upload
    has_root=1
    dst="$root/$id"
    if [[ -e "$dst" ]]; then
      if [[ $FORCE -eq 1 ]]; then
        [[ $DRY_RUN -eq 0 ]] && rm -rf "$dst"
        skip "replaced $id in $root"
      else
        skip "$id exists in $root"
        any=0
        continue
      fi
    fi
    if [[ $DRY_RUN -eq 0 ]]; then
      mkdir -p "$root"
      cp -R "$src" "$dst"
    fi
    any=0
  done
  # No skills directory at all (claude-desktop): counted as available because
  # the skill is packaged into a zip further down.
  [[ $has_root -eq 0 ]] && return 0
  return $any
}

step "Installing skills"
count=0; missing=0
for id in $IDS; do
  if install_skill "$id" "$PACK_ROOT/skills/vendor"; then count=$((count+1)); else missing=$((missing+1)); fi
done
for id in $LOCAL_IDS; do
  if install_skill "$id" "$PACK_ROOT/skills/local"; then count=$((count+1)); else missing=$((missing+1)); fi
done
ok "$count skills"
[[ $missing -gt 0 ]] && warn "$missing skills missing"

# ---------------------------------------------------------------- commands

step "Installing commands"
IFS=',' read -ra arr <<< "$CLIENTS"
for c in "${arr[@]}"; do
  root="$(commands_root "$c")"
  if [[ -z "$root" ]]; then
    [[ "$c" == "codex" ]] && skip "codex: no slash-command dir; call skills via /skills or \$name"
    [[ "$c" == "claude-desktop" ]] && skip "claude-desktop: no slash commands; use the chat UI"
    continue
  fi
  [[ $DRY_RUN -eq 0 ]] && mkdir -p "$root"
  for f in "$PACK_ROOT"/commands/*.md; do
    [[ -e "$f" ]] || continue
    if [[ -e "$root/$(basename "$f")" && $FORCE -eq 0 ]]; then
      skip "$(basename "$f") exists"
    else
      [[ $DRY_RUN -eq 0 ]] && cp "$f" "$root/"
      ok "/$(basename "$f" .md)"
    fi
  done
done

# Claude Desktop cannot read a skills directory; each skill must be uploaded as
# a zip through Settings > Capabilities > Skills. Pre-build one zip per skill.
build_desktop_zips() {
  local out="$PACK_ROOT/dist/claude-skills" made=0 failed=0 id src zip

  # `python3` on Windows often resolves to the Microsoft Store alias stub, which
  # fails at run time rather than at `command -v` time. Probe by executing.
  local py=""
  py="$(find_python)" || py=""

  local has_zip=0
  command -v zip >/dev/null 2>&1 && has_zip=1

  if [[ $has_zip -eq 0 && -z "$py" ]] && ! command -v powershell.exe >/dev/null 2>&1; then
    err "no zip, no working python, no powershell: cannot build Claude Desktop zips"
    return 1
  fi

  [[ $DRY_RUN -eq 0 ]] && mkdir -p "$out"
  for id in $IDS $LOCAL_IDS; do
    src="$PACK_ROOT/skills/vendor/$id"
    [[ -d "$src" ]] || src="$PACK_ROOT/skills/local/$id"
    [[ -f "$src/SKILL.md" ]] || continue
    zip="$out/$id.zip"
    if [[ $DRY_RUN -eq 1 ]]; then ok "would build $zip"; made=$((made+1)); continue; fi
    rm -f "$zip"

    if [[ $has_zip -eq 1 ]]; then
      ( cd "$(dirname "$src")" && zip -qr "$zip" "$id" ) || { warn "zip failed: $id"; failed=$((failed+1)); continue; }
    elif [[ -n "$py" ]]; then
      "$py" - "$src" "$zip" "$id" <<'PY' || { warn "zip failed: $id"; failed=$((failed+1)); continue; }
import os, sys, zipfile
src, out, name = sys.argv[1:4]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(src):
        for f in files:
            full = os.path.join(root, f)
            rel = os.path.join(name, os.path.relpath(full, src))
            z.write(full, rel)
PY
    else
      # Git Bash on Windows: Compress-Archive keeps <id>/SKILL.md as the root.
      powershell.exe -NoProfile -Command \
        "Compress-Archive -Path '$(cygpath -w "$src")' -DestinationPath '$(cygpath -w "$zip")' -Force" \
        >/dev/null || { warn "zip failed: $id"; failed=$((failed+1)); continue; }
    fi
    made=$((made+1))
  done
  ok "$made skill zips in $out"
  [[ $failed -gt 0 ]] && warn "$failed skills could not be zipped"
  skip "upload only the skills you need; Claude Desktop has no folder-based loading"
  return 0
}

if has_client claude-desktop; then
  step "Building Claude Desktop skill zips"
  build_desktop_zips
fi

# ---------------------------------------------------------------- MCP

# Merge an MCP server entry into a JSON config without clobbering other keys.
# mode=opencode -> {"mcp":{"servers":{...}}}
# mode=desktop  -> {"mcpServers":{...}}
# mode=claude   -> {"mcpServers":{...}}  (~/.claude.json)
merge_json_mcp() {
  local mode="$1" path="$2" exe="$3"
  if [[ $DRY_RUN -eq 1 ]]; then
    skip "would merge $MCP_NAME into $path"
    return 0
  fi
  local py
  py="$(find_python)" || { err "python not found; cannot merge $path"; return 1; }
  "$py" - "$mode" "$path" "$MCP_NAME" "$exe" <<'PY'
import json, os, sys
mode, path, name, exe = sys.argv[1:5]
data = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception as exc:
        print(f"  [!!] cannot parse {path}: {exc}")
        print("       fix or delete the file, then re-run")
        sys.exit(2)
entry = {"command": exe, "args": []}
if mode == "opencode":
    data.setdefault("mcp", {}).setdefault("servers", {})[name] = {
        "type": "local", "command": [exe],
    }
else:
    data.setdefault("mcpServers", {})[name] = entry
os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
print(f"  [OK] {name} -> {path}")
PY
}

# Append a [mcp_servers.<name>] block to Codex config.toml if absent.
register_codex_mcp() {
  local path="$1" exe="$2"
  if [[ -f "$path" ]] && grep -q "^\[mcp_servers\.$MCP_NAME\]" "$path"; then
    skip "$MCP_NAME already in $path"
    return 0
  fi
  [[ $DRY_RUN -eq 1 ]] && { ok "would append [mcp_servers.$MCP_NAME] to $path"; return 0; }
  mkdir -p "$(dirname "$path")"
  cat >> "$path" <<TOML

[mcp_servers.$MCP_NAME]
command = '$exe'
args = []
startup_timeout_sec = 45
tool_timeout_sec = 600

[mcp_servers.$MCP_NAME.env]
FLUIDS_MCP_LOG_LEVEL = "INFO"
FLUIDS_MCP_MAX_STEPS = "30"
TOML
  ok "appended [mcp_servers.$MCP_NAME] to $path"
}

if [[ $WITH_FLUENT -eq 1 ]]; then
  step "Setting up Ansys Fluent MCP"
  PY="$(find_python)" || { err "python 3 not found (needed for venv + JSON merge)"; exit 1; }
  VENV="$PACK_ROOT/.venv"
  # Windows venvs put entry points in Scripts\*.exe, POSIX ones in bin/.
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) VENV_BIN="$VENV/Scripts"; EXE="$VENV/Scripts/ansys-fluent-mcp.exe" ;;
    *)                    VENV_BIN="$VENV/bin";     EXE="$VENV/bin/ansys-fluent-mcp" ;;
  esac
  if [[ $DRY_RUN -eq 0 ]]; then
    [[ -d "$VENV" ]] || "$PY" -m venv "$VENV"
    "$VENV_BIN/python" -m pip install --upgrade pip --quiet
    "$VENV_BIN/python" -m pip install --upgrade ansys-fluent-mcp --quiet
    [[ -x "$EXE" ]] || { err "MCP entry point not found: $EXE"; exit 1; }
    ok "installed ansys-fluent-mcp"
  fi

  step "Registering MCP with each client"
  if has_client opencode; then
    if command -v opencode >/dev/null; then
      if [[ $DRY_RUN -eq 0 ]]; then
        opencode mcp add "$MCP_NAME" --global -- "$EXE" && ok "opencode: $MCP_NAME" \
          || warn "opencode mcp add failed; merge by hand (config/opencode.mcp.jsonc)"
      else
        skip "would run: opencode mcp add $MCP_NAME --global -- $EXE"
      fi
    else
      merge_json_mcp opencode "$HOME/.config/opencode/opencode.json" "$EXE"
    fi
  fi
  if has_client claude; then
    if command -v claude >/dev/null; then
      if [[ $DRY_RUN -eq 0 ]]; then
        claude mcp add --scope user "$MCP_NAME" -- "$EXE" && ok "claude code: $MCP_NAME" \
          || warn "claude mcp add failed; merge by hand into ~/.claude.json"
      else
        skip "would run: claude mcp add --scope user $MCP_NAME -- $EXE"
      fi
    else
      merge_json_mcp claude "$HOME/.claude.json" "$EXE"
    fi
  fi
  if has_client codex; then
    register_codex_mcp "$HOME/.codex/config.toml" "$EXE"
  fi
  if has_client claude-desktop; then
    merge_json_mcp desktop "$(desktop_config_path)" "$EXE"
    warn "restart Claude Desktop (quit from the tray, not just close the window)"
  fi
else
  step "Skipping MCP (use --with-fluent to install it)"
fi

# ---------------------------------------------------------------- summary

printf "\n  -------------------------------------------------\n"
if [[ $DRY_RUN -eq 1 ]]; then
  ok "$count skills would be installed"
else
  ok "$count skills installed"
fi
printf "  next:\n"
has_client opencode       && printf "    OpenCode       : /paper  or  /cfd\n"
has_client claude         && printf "    Claude Code    : /paper  or  /cfd\n"
has_client codex          && printf "    Codex          : /skills  then pick journal-pipeline\n"
has_client claude-desktop && printf "    Claude Desktop : Settings > Capabilities > Skills > upload a zip\n"
printf "  read: docs/08-客户端接入.md\n\n"
