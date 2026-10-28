#Requires -Version 5.1
<#
.SYNOPSIS
  Verify the SCI Research Pack installation.
#>
param(
    [string[]]$Clients = @('opencode'),
    [string]$PackRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Line($label, $value, $status) {
    $color = switch ($status) {
        'ok'   { 'Green' }
        'warn' { 'Yellow' }
        'bad'  { 'Red' }
        default { 'Gray' }
    }
    Write-Host ("  {0,-22} {1}" -f $label, $value) -ForegroundColor $color
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
Write-Host "  pack: $PackRoot"

foreach ($c in $Clients) {
    $root = switch ($c) {
        'opencode' { Join-Path $env:USERPROFILE '.config\opencode\skills' }
        'claude'   { Join-Path $env:USERPROFILE '.claude\skills' }
        'codex'    { Join-Path $env:USERPROFILE '.codex\skills' }
    }
    Write-Host "`n[$c] $root" -ForegroundColor Cyan
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

# commands
$cmdRoot = Join-Path $env:USERPROFILE '.config\opencode\commands'
Write-Host "`n[commands] $cmdRoot" -ForegroundColor Cyan
if (Test-Path $cmdRoot) {
    $cmds = Get-ChildItem $cmdRoot -Filter '*.md'
    Line 'slash commands' "$($cmds.Count) ($(($cmds | ForEach-Object { '/' + $_.BaseName }) -join ' '))" 'ok'
} else {
    Line 'slash commands' 'missing' 'warn'
}

# mcp config
Write-Host "`n[MCP]" -ForegroundColor Cyan
$cfgPath = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
$cfgJsonc = Join-Path $env:USERPROFILE '.config\opencode\opencode.jsonc'
$cfg = $null
if (Test-Path $cfgPath) {
    try { $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
    if ($cfg -and $cfg.mcp -and $cfg.mcp.servers -and $cfg.mcp.servers.'ansys-fluent') {
        Line 'ansys-fluent' 'configured' 'ok'
    } else {
        Line 'ansys-fluent' 'not configured' 'warn'
    }
} elseif (Test-Path $cfgJsonc) {
    $hit = Select-String -Path $cfgJsonc -Pattern 'ansys-fluent' -Quiet
    if ($hit) { Line 'ansys-fluent' 'configured (jsonc)' 'ok' }
    else { Line 'ansys-fluent' 'not configured (jsonc)' 'warn' }
} else {
    Line 'opencode config' 'not found' 'warn'
}

# venv / package
Write-Host "`n[Python]" -ForegroundColor Cyan
$venvPy = Join-Path $PackRoot '.venv\Scripts\python.exe'
if (Test-Path $venvPy) {
    Line 'venv' $venvPy 'ok'
    $ver = & $venvPy -c "import importlib.metadata as m;print(m.version('ansys-fluent-mcp'))" 2>$null
    if ($LASTEXITCODE -eq 0) { Line 'ansys-fluent-mcp' $ver 'ok' }
    else { Line 'ansys-fluent-mcp' 'not installed' 'bad' }
    $fv = & $venvPy -c "import importlib.metadata as m;print(m.version('ansys-fluent-core'))" 2>$null
    if ($LASTEXITCODE -eq 0) { Line 'ansys-fluent-core' $fv 'ok' }
    else { Line 'ansys-fluent-core' 'not installed' 'warn' }
} else {
    Line 'venv' 'not created (use -WithFluent)' 'warn'
}

# Fluent install
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

Write-Host "`n  -------------------------------------------------" -ForegroundColor DarkGray
Write-Host '  If everything above is OK, open OpenCode and run /paper or /cfd.' -ForegroundColor Cyan
Write-Host ''
