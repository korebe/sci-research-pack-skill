#!/usr/bin/env bash
# SCI Research Pack installer (macOS / Linux)
# Usage:
#   ./install.sh                     # full profile, opencode
#   ./install.sh --profile core
#   ./install.sh --clients opencode,claude --with-fluent
#   ./install.sh --dry-run
set -euo pipefail

PROFILE="full"
CLIENTS="opencode"
WITH_FLUENT=0
DRY_RUN=0
FORCE=0
PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --clients) CLIENTS="$2"; shift 2 ;;
    --with-fluent) WITH_FLUENT=1; shift ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

c_cyan='\033[36m'; c_green='\033[32m'; c_yellow='\033[33m'; c_gray='\033[90m'; c_reset='\033[0m'
step() { printf "\n${c_cyan}[>] %s${c_reset}\n" "$1"; }
ok()   { printf "  ${c_green}[OK] %s${c_reset}\n" "$1"; }
skip() { printf "  ${c_gray}[--] %s${c_reset}\n" "$1"; }
warn() { printf "  ${c_yellow}[!!] %s${c_reset}\n" "$1"; }

case "$PROFILE" in
  writing) IDS="paper-workflow scientific-writing write-scientific-manuscript scientific-prose-style anti-defensive-writing results-section-revision manuscript-optimizer claim-source-verification citation-verifier stats-reporting-audit figure-planner nature-figure nature-portfolio-playbook paper-reviewer rebuttal-response submission-audit sciwrite journal-adapt scipilot-figure scientific-paper-writer nature-writing nature-polishing nature-citation nature-ref-verifier nature-reviewer nature-response nature-paper2word nature-paper-xray nature-statistics nature-shared" ;;
  sim) IDS="fluent-cfd fluidsim openpiv cantera pybamm simpy uncertainty-and-units statistical-analysis scientific-visualization literature-review paper-lookup" ;;
  core) IDS="paper-workflow scientific-writing write-scientific-manuscript scientific-prose-style anti-defensive-writing results-section-revision manuscript-optimizer claim-source-verification citation-verifier stats-reporting-audit figure-planner nature-figure nature-portfolio-playbook paper-reviewer rebuttal-response submission-audit sciwrite journal-adapt scipilot-figure scientific-paper-writer fluent-cfd fluidsim uncertainty-and-units statistical-analysis scientific-visualization" ;;
  *) IDS="paper-workflow scientific-writing write-scientific-manuscript scientific-prose-style anti-defensive-writing results-section-revision manuscript-optimizer claim-source-verification citation-verifier stats-reporting-audit figure-planner nature-figure nature-portfolio-playbook paper-reviewer rebuttal-response submission-audit sciwrite journal-adapt scipilot-figure scientific-paper-writer nature-writing nature-polishing nature-citation nature-ref-verifier nature-reviewer nature-response nature-paper2word nature-paper-xray nature-statistics nature-shared fluent-cfd fluidsim openpiv cantera pybamm simpy uncertainty-and-units statistical-analysis scientific-visualization literature-review paper-lookup" ;;
esac
LOCAL_IDS="journal-pipeline cfd-fluent-pipeline"

skills_root() {
  case "$1" in
    opencode) echo "$HOME/.config/opencode/skills" ;;
    claude)   echo "$HOME/.claude/skills" ;;
    codex)    echo "$HOME/.codex/skills" ;;
  esac
}
commands_root() {
  case "$1" in
    opencode) echo "$HOME/.config/opencode/commands" ;;
    claude)   echo "$HOME/.claude/commands" ;;
    *)        echo "" ;;
  esac
}

printf "\n  SCI Research Pack  ·  top-journal writing + CFD\n"
printf "  -------------------------------------------------\n"
printf "  pack    : %s\n" "$PACK_ROOT"
printf "  profile : %s\n" "$PROFILE"
printf "  clients : %s\n" "$CLIENTS"
[[ $DRY_RUN -eq 1 ]] && printf "  mode    : DRY RUN\n"

step "Checking prerequisites"
command -v git >/dev/null || { warn "git not found"; exit 1; }
ok "$(git --version)"

[[ -d "$PACK_ROOT/skills/vendor" ]] || { warn "missing skills/vendor"; exit 1; }

install_skill() {
  local id="$1" srcroot="$2"
  local src="$srcroot/$id"
  [[ -f "$src/SKILL.md" ]] || { warn "missing SKILL.md: $src"; return 1; }
  local any=1
  IFS=',' read -ra arr <<< "$CLIENTS"
  for c in "${arr[@]}"; do
    local root; root="$(skills_root "$c")"
    local dst="$root/$id"
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

step "Installing commands"
IFS=',' read -ra arr <<< "$CLIENTS"
for c in "${arr[@]}"; do
  root="$(commands_root "$c")"
  [[ -z "$root" ]] && continue
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

if [[ $WITH_FLUENT -eq 1 ]]; then
  step "Setting up Ansys Fluent MCP"
  command -v python3 >/dev/null || { warn "python3 not found"; exit 1; }
  VENV="$PACK_ROOT/.venv"
  [[ -d "$VENV" ]] || python3 -m venv "$VENV"
  "$VENV/bin/python" -m pip install --upgrade pip --quiet
  "$VENV/bin/python" -m pip install --upgrade ansys-fluent-mcp --quiet
  ok "installed ansys-fluent-mcp"
  EXE="$VENV/bin/ansys-fluent-mcp"
  if command -v opencode >/dev/null; then
    [[ $DRY_RUN -eq 0 ]] && opencode mcp add ansys-fluent --global -- "$EXE" || true
    ok "registered MCP ansys-fluent"
  else
    warn "opencode CLI not found; add to ~/.config/opencode/opencode.json:"
    echo "  \"mcp\": { \"servers\": { \"ansys-fluent\": { \"type\": \"local\", \"command\": [\"$EXE\"] } } }"
  fi
fi

printf "\n  -------------------------------------------------\n"
ok "done"
printf "  next: open OpenCode and run /paper or /cfd\n"
printf "  read: docs/01-技能路由表.md\n\n"
