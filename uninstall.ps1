#Requires -Version 5.1
<#
.SYNOPSIS
  Remove skills and commands installed by this pack. Does not touch other
  skills, your MCP config, or your manuscripts.
#>
param(
    [string[]]$Clients = @('opencode'),
    [switch]$Yes,
    [string]$PackRoot = $PSScriptRoot
)

[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Get-SkillsRoot($c) {
    switch ($c) {
        'opencode' { Join-Path $env:USERPROFILE '.config\opencode\skills' }
        'claude'   { Join-Path $env:USERPROFILE '.claude\skills' }
        'codex'    { Join-Path $env:USERPROFILE '.codex\skills' }
    }
}

$ids = @()
foreach ($d in @('skills\vendor', 'skills\local')) {
    $p = Join-Path $PackRoot $d
    if (Test-Path $p) { $ids += (Get-ChildItem $p -Directory).Name }
}

$targets = @()
foreach ($c in $Clients) {
    $root = Get-SkillsRoot $c
    foreach ($id in $ids) {
        $dst = Join-Path $root $id
        if (Test-Path $dst) { $targets += $dst }
    }
}

Write-Host ''
Write-Host '  The following will be removed:' -ForegroundColor Yellow
$targets | ForEach-Object { Write-Host "    $_" }
Write-Host "`n  Total: $($targets.Count) directories" -ForegroundColor Yellow

if ($targets.Count -eq 0) { Write-Host '  Nothing to remove.'; exit 0 }
if (-not $Yes) {
    $ans = Read-Host '  Continue? [y/N]'
    if ($ans -notmatch '^[yY]') { Write-Host '  Aborted.'; exit 0 }
}

foreach ($t in $targets) {
    Remove-Item $t -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  removed $t" -ForegroundColor DarkGray
}

Write-Host "`n  Done. MCP entries and ~/.codex config were not modified." -ForegroundColor Green
Write-Host ''
