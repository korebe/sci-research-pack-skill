#Requires -Version 5.1
<#
.SYNOPSIS
  SCI Research Pack installer (Windows PowerShell 5.1+).

.DESCRIPTION
  Installs a curated set of top-journal writing skills, CFD skills, slash
  commands and (optionally) the official Ansys Fluent MCP server.

.PARAMETER Profile
  full | core | writing | sim   (default: full)

.PARAMETER Clients
  Any of: opencode, claude, codex   (default: opencode)

.PARAMETER WithFluent
  Create .venv, pip install ansys-fluent-mcp, register the MCP server.

.PARAMETER WithARS
  Clone the optional OpenCode port of Academic Research Skills (CC BY-NC).

.PARAMETER DryRun
  Show what would happen without writing anything.

.EXAMPLE
  .\install.ps1
  .\install.ps1 -Profile core -Clients opencode,claude
  .\install.ps1 -WithFluent
#>
param(
    [ValidateSet('full', 'core', 'writing', 'sim')]
    [string]$Profile = 'full',

    [ValidateSet('opencode', 'claude', 'codex')]
    [string[]]$Clients = @('opencode'),

    [switch]$WithFluent,
    [switch]$WithARS,
    [switch]$SkipClone,
    [switch]$Force,
    [switch]$DryRun,

    [string]$PythonExe = '',
    [string]$PackRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# ---------------------------------------------------------------- helpers

function Write-Banner {
    Write-Host ''
    Write-Host '  SCI Research Pack  ·  top-journal writing + CFD' -ForegroundColor Cyan
    Write-Host '  -------------------------------------------------' -ForegroundColor DarkGray
}

function Write-Step($msg) { Write-Host "`n[>] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  [--] $msg" -ForegroundColor DarkGray }
function Write-Warn2($msg){ Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Err2($msg) { Write-Host "  [XX] $msg" -ForegroundColor Red }

function Get-SkillsRoot {
    param([string]$Client)
    switch ($Client) {
        'opencode' { return (Join-Path $env:USERPROFILE '.config\opencode\skills') }
        'claude'   { return (Join-Path $env:USERPROFILE '.claude\skills') }
        'codex'    { return (Join-Path $env:USERPROFILE '.codex\skills') }
        default    { throw "Unknown client: $Client" }
    }
}

function Get-CommandsRoot {
    param([string]$Client)
    switch ($Client) {
        'opencode' { return (Join-Path $env:USERPROFILE '.config\opencode\commands') }
        'claude'   { return (Join-Path $env:USERPROFILE '.claude\commands') }
        default    { return $null }
    }
}

function Install-OneSkill {
    param(
        [string]$Id,
        [string]$SourceRoot,
        [string[]]$TargetRoots
    )

    $src = Join-Path $SourceRoot $Id
    if (-not (Test-Path (Join-Path $src 'SKILL.md'))) {
        Write-Warn2 "missing SKILL.md: $src"
        return $false
    }

    $ok = $false
    foreach ($root in $TargetRoots) {
        $dst = Join-Path $root $Id
        if (Test-Path $dst) {
            if ($Force) {
                if (-not $DryRun) { Remove-Item $dst -Recurse -Force }
                Write-Skip "replaced $Id in $root"
            } else {
                Write-Skip "$Id already exists in $root (use -Force to replace)"
                $ok = $true
                continue
            }
        }
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            Copy-Item -Recurse -Force $src $dst
        }
        $ok = $true
    }
    return $ok
}

function Install-Commands {
    param([string[]]$TargetRoots)

    $srcDir = Join-Path $PackRoot 'commands'
    if (-not (Test-Path $srcDir)) { return }
    foreach ($root in $TargetRoots) {
        if (-not $root) { continue }
        if (-not $DryRun) { New-Item -ItemType Directory -Path $root -Force | Out-Null }
        Get-ChildItem $srcDir -Filter '*.md' | ForEach-Object {
            $dst = Join-Path $root $_.Name
            if ((Test-Path $dst) -and (-not $Force)) {
                Write-Skip "command $($_.Name) exists (use -Force)"
            } else {
                if (-not $DryRun) { Copy-Item $_.FullName $dst -Force }
                Write-Ok "command /$([IO.Path]::GetFileNameWithoutExtension($_.Name))"
            }
        }
    }
}

function ConvertTo-Hashtable {
    param($Object)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}
        foreach ($p in $Object.PSObject.Properties) {
            $h[$p.Name] = ConvertTo-Hashtable $p.Value
        }
        return $h
    }
    if ($Object -is [System.Collections.IEnumerable] -and -not ($Object -is [string])) {
        $arr = @()
        foreach ($item in $Object) { $arr += ,(ConvertTo-Hashtable $item) }
        return $arr
    }
    return $Object
}

function Register-OpenCodeMcp {
    param([string]$Name, [string]$Exe)

    $cli = Get-Command opencode -ErrorAction SilentlyContinue
    if ($cli) {
        if ($DryRun) { Write-Ok "would run: opencode mcp add $Name --global -- $Exe"; return $true }
        try {
            & $cli.Source mcp add $Name --global -- $Exe 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Ok "registered MCP '$Name' via opencode CLI"; return $true }
            Write-Warn2 "opencode mcp add failed (exit $LASTEXITCODE); falling back to config merge"
        } catch {
            Write-Warn2 "opencode CLI error: $($_.Exception.Message)"
        }
    }

    $dir = Join-Path $env:USERPROFILE '.config\opencode'
    $jsonPath = Join-Path $dir 'opencode.json'
    $jsoncPath = Join-Path $dir 'opencode.jsonc'

    if (Test-Path $jsoncPath) {
        Write-Warn2 "found opencode.jsonc; not auto-merging. Add this manually:"
        $escapedExe = $Exe -replace '\\', '\\'
        Write-Host ''
        Write-Host ('  "mcp": { "servers": { "' + $Name + '": { "type": "local", "command": ["' + $escapedExe + '"] } } }')
        Write-Host ''
        return $false
    }

    $cfg = $null
    if (Test-Path $jsonPath) {
        $raw = Get-Content $jsonPath -Raw -Encoding UTF8
        try {
            $cfg = $raw | ConvertFrom-Json
            $backup = "$jsonPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            if (-not $DryRun) { Copy-Item $jsonPath $backup -Force }
            Write-Skip "backed up config to $backup"
        } catch {
            Write-Warn2 "opencode.json is not strict JSON (comments?). Not auto-merging."
            Write-Host "  Add the mcp.servers entry manually (see config\opencode.mcp.jsonc)."
            return $false
        }
    } else {
        $cfg = [pscustomobject]@{ '$schema' = 'https://opencode.ai/config.json' }
    }

    $h = ConvertTo-Hashtable $cfg
    if (-not $h.ContainsKey('mcp') -or -not ($h['mcp'] -is [hashtable])) { $h['mcp'] = @{} }
    if (-not $h['mcp'].ContainsKey('servers') -or -not ($h['mcp']['servers'] -is [hashtable])) { $h['mcp']['servers'] = @{} }
    $h['mcp']['servers'][$Name] = @{ type = 'local'; command = @($Exe) }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $text = $h | ConvertTo-Json -Depth 20
        [IO.File]::WriteAllText($jsonPath, $text, (New-Object Text.UTF8Encoding($false)))
    }
    Write-Ok "wrote mcp.servers.$Name to $jsonPath"
    return $true
}

function Register-ClaudeMcp {
    param([string]$Name, [string]$Exe)
    $cli = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $cli) { Write-Skip 'claude CLI not found; skip Claude MCP registration'; return }
    if ($DryRun) { Write-Ok "would run: claude mcp add --scope user $Name -- $Exe"; return }
    try {
        & $cli.Source mcp add --scope user $Name -- $Exe 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok "registered Claude MCP '$Name'" }
        else { Write-Warn2 "claude mcp add failed (exit $LASTEXITCODE)" }
    } catch { Write-Warn2 $_.Exception.Message }
}

function Get-Python {
    param([string]$Preferred)
    if ($Preferred -and (Test-Path $Preferred)) { return $Preferred }
    $candidates = @('python', 'py')
    foreach ($c in $candidates) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

# ---------------------------------------------------------------- plan

$writingIds = @(
    'paper-workflow', 'scientific-writing', 'write-scientific-manuscript',
    'scientific-prose-style', 'anti-defensive-writing', 'results-section-revision',
    'manuscript-optimizer', 'claim-source-verification', 'citation-verifier',
    'stats-reporting-audit', 'figure-planner', 'nature-figure',
    'nature-portfolio-playbook', 'paper-reviewer', 'rebuttal-response',
    'submission-audit', 'sciwrite', 'journal-adapt', 'scipilot-figure',
    'scientific-paper-writer', 'nature-writing', 'nature-polishing',
    'nature-citation', 'nature-ref-verifier', 'nature-reviewer',
    'nature-response', 'nature-paper2word', 'nature-paper-xray',
    'nature-statistics', 'nature-shared'
)

$simIds = @(
    'fluent-cfd', 'fluidsim', 'openpiv', 'cantera', 'pybamm', 'simpy',
    'uncertainty-and-units', 'statistical-analysis', 'scientific-visualization',
    'literature-review', 'paper-lookup'
)

$coreWriting = @(
    'paper-workflow', 'scientific-writing', 'write-scientific-manuscript',
    'scientific-prose-style', 'anti-defensive-writing', 'results-section-revision',
    'manuscript-optimizer', 'claim-source-verification', 'citation-verifier',
    'stats-reporting-audit', 'figure-planner', 'nature-figure',
    'nature-portfolio-playbook', 'paper-reviewer', 'rebuttal-response',
    'submission-audit', 'sciwrite', 'journal-adapt', 'scipilot-figure',
    'scientific-paper-writer'
)
$coreSim = @('fluent-cfd', 'fluidsim', 'uncertainty-and-units', 'statistical-analysis', 'scientific-visualization')

switch ($Profile) {
    'writing' { $selected = $writingIds }
    'sim'     { $selected = $simIds }
    'core'    { $selected = $coreWriting + $coreSim }
    default   { $selected = $writingIds + $simIds }
}
$selected = $selected | Select-Object -Unique

$localIds = @('journal-pipeline', 'cfd-fluent-pipeline')

# ---------------------------------------------------------------- run

Write-Banner
Write-Host "  Pack    : $PackRoot"
Write-Host "  Profile : $Profile ($($selected.Count) upstream + $($localIds.Count) local skills)"
Write-Host "  Clients : $($Clients -join ', ')"
if ($DryRun) { Write-Host '  Mode    : DRY RUN (nothing will be written)' -ForegroundColor Yellow }
if ($WithFluent) { Write-Host '  Fluent  : MCP will be installed' }
if ($WithARS) { Write-Host '  ARS     : optional module will be cloned' }

# 1. sanity
Write-Step 'Checking prerequisites'
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { Write-Err2 'git not found. Install Git for Windows first.'; exit 1 }
Write-Ok "git $((& git --version) -replace 'git version ','')"

$vendorRoot = Join-Path $PackRoot 'skills\vendor'
$localRoot  = Join-Path $PackRoot 'skills\local'
if (-not (Test-Path $vendorRoot)) { Write-Err2 "missing $vendorRoot"; exit 1 }
if (-not (Test-Path $localRoot))  { Write-Err2 "missing $localRoot"; exit 1 }

# 2. optional clone ARS
if ($WithARS) {
    Write-Step 'Cloning optional Academic Research Skills (OpenCode port)'
    $arsDir = Join-Path $PackRoot 'vendor\opencode-academic-research'
    if (Test-Path $arsDir) {
        Write-Skip 'already cloned'
    } elseif (-not $DryRun) {
        New-Item -ItemType Directory -Path (Split-Path $arsDir) -Force | Out-Null
        & git clone --depth 1 --quiet https://github.com/timpara/opencode-academic-research.git $arsDir
        if ($LASTEXITCODE -ne 0) { Write-Warn2 'clone failed; see docs/07-故障排查.md' }
        else { Write-Ok 'cloned to vendor\opencode-academic-research' }
    }
    Write-Warn2 'ARS is CC BY-NC 4.0 (non-commercial). Run its own installer inside the repo.'
}

# 3. install skills
$targets = @()
foreach ($c in $Clients) { $targets += (Get-SkillsRoot $c) }
Write-Step "Installing skills to:"
$targets | ForEach-Object { Write-Host "  - $_" }

$installed = @()
$missing = @()
foreach ($id in $selected) {
    $ok = Install-OneSkill -Id $id -SourceRoot $vendorRoot -TargetRoots $targets
    if ($ok) { $installed += $id } else { $missing += $id }
}
foreach ($id in $localIds) {
    $ok = Install-OneSkill -Id $id -SourceRoot $localRoot -TargetRoots $targets
    if ($ok) { $installed += $id } else { $missing += $id }
}

# 4. commands
$cmdRoots = @()
foreach ($c in $Clients) { $cmdRoots += (Get-CommandsRoot $c) }
Write-Step 'Installing slash commands'
Install-Commands -TargetRoots $cmdRoots

# 5. Fluent MCP
$mcpOk = $false
if ($WithFluent) {
    Write-Step 'Setting up Ansys Fluent MCP'
    $py = Get-Python $PythonExe
    if (-not $py) {
        Write-Err2 'Python not found. Install Python 3.12+ and re-run with -PythonExe.'
    } else {
        $ver = & $py -c "import sys;print('.'.join(map(str,sys.version_info[:2])))" 2>$null
        Write-Ok "python $ver ($py)"
        $venv = Join-Path $PackRoot '.venv'
        $venvPy = Join-Path $venv 'Scripts\python.exe'
        if (-not (Test-Path $venvPy)) {
            if (-not $DryRun) { & $py -m venv $venv }
            Write-Ok "created venv: $venv"
        } else {
            Write-Skip "venv exists: $venv"
        }
        if (-not $DryRun) {
            & $venvPy -m pip install --upgrade pip --quiet
            & $venvPy -m pip install --upgrade ansys-fluent-mcp --quiet
            if ($LASTEXITCODE -eq 0) { Write-Ok 'installed ansys-fluent-mcp' }
            else { Write-Warn2 'pip install failed; run manually: pip install ansys-fluent-mcp' }
        }
        $exe = Join-Path $venv 'Scripts\ansys-fluent-mcp.exe'
        if ((Test-Path $exe) -or $DryRun) {
            if ($Clients -contains 'opencode') { $mcpOk = Register-OpenCodeMcp -Name 'ansys-fluent' -Exe $exe }
            if ($Clients -contains 'claude')   { Register-ClaudeMcp -Name 'ansys-fluent' -Exe $exe }
            if ($Clients -contains 'codex')    { Write-Skip 'Codex: copy config\codex.config.toml into ~/.codex/config.toml' }
        } else {
            Write-Warn2 "MCP entry point not found: $exe"
        }
    }
}

# 6. report
$report = Join-Path $PackRoot 'install-report.txt'
$lines = @(
    "SCI Research Pack install report",
    "date    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "profile : $Profile",
    "clients : $($Clients -join ', ')",
    "skills  : $($installed.Count) installed, $($missing.Count) missing",
    "",
    "installed:",
    ($installed | Sort-Object | ForEach-Object { "  - $_" }),
    "",
    "missing:",
    ($missing  | Sort-Object | ForEach-Object { "  - $_" }),
    "",
    "mcp ansys-fluent: $mcpOk"
)
if (-not $DryRun) { $lines | Set-Content $report -Encoding UTF8 }

Write-Host ''
Write-Host '  -------------------------------------------------' -ForegroundColor DarkGray
if ($DryRun) {
    Write-Ok "$($installed.Count) skills would be installed"
} else {
    Write-Ok "$($installed.Count) skills installed"
}
if ($missing.Count -gt 0) { Write-Warn2 "$($missing.Count) skills missing (see install-report.txt)" }
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor Cyan
Write-Host '    1. Open OpenCode and run:  /paper   or   /cfd'
Write-Host '    2. Check:                  .\verify.ps1'
Write-Host '    3. Read:                   docs\01-技能路由表.md'
Write-Host ''
