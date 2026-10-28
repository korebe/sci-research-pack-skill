#Requires -Version 5.1
<#
.SYNOPSIS
  Verify the SCI Research Pack installation.

.DESCRIPTION
  Checks skills, slash commands and MCP registration per client. Each client
  stores these in a different place, so pass the same -Clients you installed
  with:

    .\verify.ps1                                   # OpenCode only
    .\verify.ps1 -Clients opencode,claude,codex    # several at once
    .\verify.ps1 -Clients claude-desktop           # MCP + skill zips
#>
param(
    # Comma separated or array; validated below so `powershell -File` works.
    [string[]]$Clients = @('opencode'),

    [string]$PackRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ValidClients = @('opencode', 'claude', 'codex', 'claude-desktop')
$Clients = @(
    $Clients |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        Select-Object -Unique
)
if ($Clients.Count -eq 0) { $Clients = @('opencode') }
$unknown = @($Clients | Where-Object { $ValidClients -notcontains $_ })
if ($unknown.Count -gt 0) {
    Write-Host "  [XX] unknown client: $($unknown -join ', ')" -ForegroundColor Red
    Write-Host "       expected: $($ValidClients -join ', ')"
    exit 1
}

function Line($label, $value, $status) {
    $color = switch ($status) {
        'ok'   { 'Green' }
        'warn' { 'Yellow' }
        'bad'  { 'Red' }
        default { 'Gray' }
    }
    Write-Host ("  {0,-22} {1}" -f $label, $value) -ForegroundColor $color
}

function Get-SkillsRoot([string]$Client) {
    switch ($Client) {
        'opencode'       { Join-Path $env:USERPROFILE '.config\opencode\skills' }
        'claude'         { Join-Path $env:USERPROFILE '.claude\skills' }
        # Codex user-scope skills live in ~/.agents/skills, not ~/.codex/skills.
        'codex'          { Join-Path $env:USERPROFILE '.agents\skills' }
        'claude-desktop' { $null }
    }
}

function Get-CommandsRoot([string]$Client) {
    switch ($Client) {
        'opencode' { Join-Path $env:USERPROFILE '.config\opencode\commands' }
        'claude'   { Join-Path $env:USERPROFILE '.claude\commands' }
        default    { $null }
    }
}

$expected = @(
    'journal-pipeline', 'cfd-fluent-pipeline',
    'paper-workflow', 'sciwrite', 'journal-adapt', 'scipilot-figure',
    'scientific-paper-writer', 'nature-figure', 'citation-verifier',
    'paper-reviewer', 'rebuttal-response', 'submission-audit',
    'fluent-cfd', 'fluidsim', 'uncertainty-and-units',
    'statistical-analysis', 'scientific-visualization'
)

Write-Host ''
Write-Host '  SCI Research Pack  ·  verification' -ForegroundColor Cyan
Write-Host '  -------------------------------------------------' -ForegroundColor DarkGray
Write-Host "  pack    : $PackRoot"
Write-Host "  clients : $($Clients -join ', ')"

# ------------------------------------------------------------------ skills

foreach ($c in $Clients) {
    $root = Get-SkillsRoot $c
    if (-not $root) {
        Write-Host "`n[$c] no skills directory by design" -ForegroundColor Cyan
        Line 'skills' 'uploaded as zip in the Claude app' 'warn'
        continue
    }

    Write-Host "`n[$c skills] $root" -ForegroundColor Cyan
    if (-not (Test-Path $root)) {
        Line 'skills dir' 'missing' 'bad'
        continue
    }
    $dirs = Get-ChildItem $root -Directory
    $withSkill = $dirs | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }
    Line 'skills found' "$($withSkill.Count)" 'ok'

    $miss = @()
    foreach ($id in $expected) {
        if (-not (Test-Path (Join-Path $root "$id\SKILL.md"))) { $miss += $id }
    }
    if ($miss.Count -eq 0) {
        Line 'core skills' 'all present' 'ok'
    } else {
        Line 'core skills missing' ($miss -join ', ') 'warn'
    }
}

# ---------------------------------------------------------------- commands

foreach ($c in $Clients) {
    $cmdRoot = Get-CommandsRoot $c
    if (-not $cmdRoot) { continue }
    Write-Host "`n[$c commands] $cmdRoot" -ForegroundColor Cyan
    if (Test-Path $cmdRoot) {
        $cmds = Get-ChildItem $cmdRoot -Filter '*.md'
        Line 'slash commands' "$($cmds.Count) ($(($cmds | ForEach-Object { '/' + $_.BaseName }) -join ' '))" 'ok'
    } else {
        Line 'slash commands' 'missing' 'warn'
    }
}

# ------------------------------------------------------------- desktop zips

if ($Clients -contains 'claude-desktop') {
    $zipDir = Join-Path $PackRoot 'dist\claude-skills'
    Write-Host "`n[claude-desktop skill zips] $zipDir" -ForegroundColor Cyan
    if (Test-Path $zipDir) {
        $zips = Get-ChildItem $zipDir -Filter '*.zip'
        Line 'skill zips' "$($zips.Count) ready to upload" 'ok'
    } else {
        Line 'skill zips' 'not built (re-run install with claude-desktop)' 'warn'
    }
}

# --------------------------------------------------------------------- MCP

function Test-McpJson([string]$Path, [string]$Property, [string]$Name) {
    if (-not (Test-Path $Path)) { return $false }
    try {
        $cfg = Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($Property -eq 'mcp.servers') {
            return [bool]($cfg.mcp -and $cfg.mcp.servers -and $cfg.mcp.servers.$Name)
        }
        return [bool]($cfg.mcpServers -and $cfg.mcpServers.$Name)
    } catch { return $false }
}

function Report-Mcp([string]$Name) {
    Write-Host "`n[MCP: $Name]" -ForegroundColor Cyan

    if ($Clients -contains 'opencode') {
        $p  = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
        $pj = Join-Path $env:USERPROFILE '.config\opencode\opencode.jsonc'
        if (Test-McpJson $p 'mcp.servers' $Name) { Line 'opencode' 'configured' 'ok' }
        elseif ((Test-Path $pj) -and (Select-String -Path $pj -Pattern $Name -Quiet)) {
            Line 'opencode' 'configured (jsonc)' 'ok'
        }
        else { Line 'opencode' 'not configured' 'warn' }
    }

    if ($Clients -contains 'claude') {
        $p = Join-Path $env:USERPROFILE '.claude.json'
        if (Test-McpJson $p 'mcpServers' $Name) { Line 'claude code' 'configured' 'ok' }
        else { Line 'claude code' 'not configured' 'warn' }
    }

    if ($Clients -contains 'codex') {
        $p = Join-Path $env:USERPROFILE '.codex\config.toml'
        if ((Test-Path $p) -and (Select-String -Path $p -Pattern "^\[mcp_servers\.$([regex]::Escape($Name))\]" -Quiet)) {
            Line 'codex' "configured in $p" 'ok'
        } else {
            Line 'codex' 'not configured' 'warn'
        }
    }

    if ($Clients -contains 'claude-desktop') {
        $p = Join-Path $env:APPDATA 'Claude\claude_desktop_config.json'
        if (Test-McpJson $p 'mcpServers' $Name) { Line 'claude desktop' "configured in $p" 'ok' }
        else { Line 'claude desktop' 'not configured' 'warn' }
    }
}

Report-Mcp 'ansys-fluent'
Report-Mcp 'origin-pro'

# ------------------------------------------------------------------ python

Write-Host "`n[Python]" -ForegroundColor Cyan
$venvPy = Join-Path $PackRoot '.venv\Scripts\python.exe'
if (Test-Path $venvPy) {
    Line 'venv' $venvPy 'ok'
    # A broken venv (interpreter moved or replaced) throws at launch; report it
    # instead of dumping a native-command stack trace.
    $ver = $null; $fv = $null
    try { $ver = & $venvPy -c "import importlib.metadata as m;print(m.version('ansys-fluent-mcp'))" 2>$null } catch { $ver = $null }
    if ($LASTEXITCODE -eq 0 -and $ver) { Line 'ansys-fluent-mcp' $ver 'ok' }
    elseif (-not $ver) { Line 'ansys-fluent-mcp' 'not installed or venv broken' 'bad' }
    else { Line 'ansys-fluent-mcp' 'not installed' 'bad' }
    try { $fv = & $venvPy -c "import importlib.metadata as m;print(m.version('ansys-fluent-core'))" 2>$null } catch { $fv = $null }
    if ($LASTEXITCODE -eq 0 -and $fv) { Line 'ansys-fluent-core' $fv 'ok' }
    elseif (-not $fv) { Line 'ansys-fluent-core' 'not installed or venv broken' 'warn' }
    else { Line 'ansys-fluent-core' 'not installed' 'warn' }

    $ov = $null
    try { $ov = & $venvPy -c "import importlib.metadata as m;print(m.version('origin-pro-mcp'))" 2>$null } catch { $ov = $null }
    if ($LASTEXITCODE -eq 0 -and $ov) { Line 'origin-pro-mcp' $ov 'ok' }
    elseif (-not $ov) { Line 'origin-pro-mcp' 'not installed (use -WithOrigin)' 'warn' }
    else { Line 'origin-pro-mcp' 'not installed (use -WithOrigin)' 'warn' }

    $oexe = Join-Path $PackRoot '.venv\Scripts\origin-pro-mcp.exe'
    if (Test-Path $oexe) { Line 'origin entry point' $oexe 'ok' }
    else { Line 'origin entry point' 'missing (use -WithOrigin)' 'warn' }
} else {
    Line 'venv' 'not created (use -WithFluent / -WithOrigin)' 'warn'
}

# ------------------------------------------------------------------- fluent

Write-Host "`n[Ansys Fluent]" -ForegroundColor Cyan
$roots = @()
if ($env:AWP_ROOT261) { $roots += $env:AWP_ROOT261 }
if ($env:AWP_ROOT251) { $roots += $env:AWP_ROOT251 }
$base = 'C:\Program Files\ANSYS Inc'
if (Test-Path $base) {
    Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object { $roots += $_.FullName }
}
if ($roots.Count -gt 0) {
    Line 'install root' ($roots -join '; ') 'ok'
    $fluent = Get-ChildItem -Path $roots -Filter 'fluent.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($fluent) { Line 'fluent.exe' $fluent.FullName 'ok' }
    else { Line 'fluent.exe' 'not found under install root' 'warn' }
} else {
    Line 'install root' 'not detected' 'warn'
}
$lic = $env:ANSYSLMD_LICENSE_FILE
if ($lic) { Line 'license server' $lic 'ok' } else { Line 'license server' 'env not set (may still work)' 'warn' }

# ------------------------------------------------------------------- origin

Write-Host "`n[Origin Pro]" -ForegroundColor Cyan
$originRoots = @()
foreach ($base in @("$env:ProgramFiles\OriginLab", "${env:ProgramFiles(x86)}\OriginLab")) {
    if ($base -and (Test-Path $base)) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object { $originRoots += $_.FullName }
    }
}
if ($originRoots.Count -gt 0) {
    Line 'install root' ($originRoots -join '; ') 'ok'
} else {
    Line 'install root' 'not detected' 'warn'
}
# COM registration is what the MCP actually needs, so check that too.
$com = $null
try { $com = Get-Item 'Registry::HKEY_CLASSES_ROOT\Origin.ApplicationSI' -ErrorAction Stop } catch { $com = $null }
if ($com) { Line 'COM (Origin.ApplicationSI)' 'registered' 'ok' }
else { Line 'COM (Origin.ApplicationSI)' 'not registered' 'bad' }
$proc = Get-Process -Name 'Origin64', 'Origin' -ErrorAction SilentlyContinue
if ($proc) { Line 'running' (($proc | Select-Object -First 1).ProcessName) 'ok' }
else { Line 'running' 'not running (start it before using origin-pro)' 'warn' }

# ---------------------------------------------------------------- next step

Write-Host "`n  -------------------------------------------------" -ForegroundColor DarkGray
Write-Host '  What to run next:' -ForegroundColor Cyan
if ($Clients -contains 'opencode')       { Write-Host '    OpenCode       : /paper   or   /cfd' }
if ($Clients -contains 'claude')         { Write-Host '    Claude Code    : /paper   or   /cfd' }
if ($Clients -contains 'codex')          { Write-Host '    Codex          : /skills  then pick journal-pipeline' }
if ($Clients -contains 'claude-desktop') { Write-Host '    Claude Desktop : Settings > Capabilities > Skills > upload a zip' }
if (Test-Path (Join-Path $PackRoot 'skills\vendor\origin-pro')) {
    Write-Host '    OriginPro      : start Origin first, then ask for a figure'
}
Write-Host '    Details        : docs\08-客户端接入.md' -ForegroundColor DarkGray
Write-Host ''
