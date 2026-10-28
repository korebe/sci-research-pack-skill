#Requires -Version 5.1
<#
.SYNOPSIS
  Remove skills and commands installed by this pack.

.DESCRIPTION
  Removes only the skill folders and slash commands this pack installed. Other
  skills, your MCP entries, the Python venv and your manuscripts are left alone.
  MCP entries must be deleted by hand (see the closing hint or docs\08).

  Claude Desktop never receives a skills directory; pass -Clients claude-desktop
  to also delete the generated dist\claude-skills zips.
#>
param(
    # Comma separated or array; validated below so `powershell -File` works.
    [string[]]$Clients = @('opencode'),

    [switch]$Yes,
    [string]$PackRoot = $PSScriptRoot
)

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

function Get-SkillsRoot($c) {
    switch ($c) {
        'opencode'       { Join-Path $env:USERPROFILE '.config\opencode\skills' }
        'claude'         { Join-Path $env:USERPROFILE '.claude\skills' }
        # Codex user-scope skills live in ~/.agents/skills, not ~/.codex/skills.
        'codex'          { Join-Path $env:USERPROFILE '.agents\skills' }
        'claude-desktop' { $null }
    }
}

function Get-CommandsRoot($c) {
    switch ($c) {
        'opencode' { Join-Path $env:USERPROFILE '.config\opencode\commands' }
        'claude'   { Join-Path $env:USERPROFILE '.claude\commands' }
        default    { $null }
    }
}

$ids = @()
foreach ($d in @('skills\vendor', 'skills\local')) {
    $p = Join-Path $PackRoot $d
    if (Test-Path $p) { $ids += (Get-ChildItem $p -Directory).Name }
}

# command files shipped by this pack
$cmdFiles = @()
$cmdSrc = Join-Path $PackRoot 'commands'
if (Test-Path $cmdSrc) { $cmdFiles = (Get-ChildItem $cmdSrc -Filter '*.md').Name }

$targets = @()
foreach ($c in $Clients) {
    $root = Get-SkillsRoot $c
    if ($root) {
        foreach ($id in $ids) {
            $dst = Join-Path $root $id
            if (Test-Path $dst) { $targets += $dst }
        }
    }
    $cmdRoot = Get-CommandsRoot $c
    if ($cmdRoot) {
        foreach ($f in $cmdFiles) {
            $dst = Join-Path $cmdRoot $f
            if (Test-Path $dst) { $targets += $dst }
        }
    }
}

if ($Clients -contains 'claude-desktop') {
    $zipDir = Join-Path $PackRoot 'dist\claude-skills'
    if (Test-Path $zipDir) { $targets += $zipDir }
}

Write-Host ''
Write-Host '  The following will be removed:' -ForegroundColor Yellow
$targets | ForEach-Object { Write-Host "    $_" }
Write-Host "`n  Total: $($targets.Count) items" -ForegroundColor Yellow

if ($targets.Count -eq 0) { Write-Host '  Nothing to remove.'; exit 0 }
if (-not $Yes) {
    $ans = Read-Host '  Continue? [y/N]'
    if ($ans -notmatch '^[yY]') { Write-Host '  Aborted.'; exit 0 }
}

foreach ($t in $targets) {
    Remove-Item $t -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  removed $t" -ForegroundColor DarkGray
}

Write-Host "`n  Done. MCP entries and the .venv were not touched." -ForegroundColor Green
Write-Host ''
Write-Host '  To remove the MCP server as well:' -ForegroundColor Cyan
if ($Clients -contains 'opencode')       { Write-Host '    opencode mcp remove ansys-fluent   (or edit ~/.config/opencode/opencode.json)' }
if ($Clients -contains 'claude')         { Write-Host '    claude mcp remove ansys-fluent     (or edit ~/.claude.json)' }
if ($Clients -contains 'codex')          { Write-Host '    delete [mcp_servers.ansys-fluent] from ~/.codex/config.toml' }
if ($Clients -contains 'claude-desktop') { Write-Host '    delete mcpServers.ansys-fluent from %APPDATA%\Claude\claude_desktop_config.json' }
Write-Host '    Skills already uploaded to Claude Desktop must be removed in the app UI.' -ForegroundColor DarkGray
Write-Host ''
