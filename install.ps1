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
  Any of: opencode, claude, codex, claude-desktop   (default: opencode)

  opencode        skills + commands + MCP
  claude          Claude Code (CLI): skills + commands + MCP
  codex           Codex CLI: skills + MCP
  claude-desktop  Claude Desktop (GUI): MCP only; skills are uploaded as a zip

.PARAMETER WithFluent
  Create .venv, pip install ansys-fluent-mcp, register the MCP server.

.PARAMETER WithOrigin
  Register the bundled origin-pro MCP server (Windows + OriginPro 2020+ only).

.PARAMETER WithARS
  Clone the optional OpenCode port of Academic Research Skills (CC BY-NC).

.PARAMETER DryRun
  Show what would happen without writing anything.

.EXAMPLE
  .\install.ps1
  .\install.ps1 -Profile core -Clients opencode,claude
  .\install.ps1 -WithFluent
  .\install.ps1 -WithOrigin -Clients opencode,claude-desktop
#>
param(
    [ValidateSet('full', 'core', 'writing', 'sim')]
    [string]$Profile = 'full',

    # No ValidateSet here: when the script is launched with `powershell -File`,
    # "-Clients opencode,claude" arrives as ONE string, and ValidateSet would
    # reject it. Normalised and validated below instead.
    [string[]]$Clients = @('opencode'),

    [switch]$WithFluent,
    [switch]$WithOrigin,
    [switch]$WithARS,
    [switch]$SkipClone,
    [switch]$Force,
    [switch]$DryRun,

    [string]$PythonExe = '',
    [string]$PackRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# ---------------------------------------------------------------- clients

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
        'opencode'       { return (Join-Path $env:USERPROFILE '.config\opencode\skills') }
        'claude'         { return (Join-Path $env:USERPROFILE '.claude\skills') }
        # Codex reads user skills from ~/.agents/skills, not ~/.codex/skills.
        'codex'          { return (Join-Path $env:USERPROFILE '.agents\skills') }
        # Claude Desktop has no skills directory; skills are uploaded as a zip.
        'claude-desktop' { return $null }
        default          { throw "Unknown client: $Client" }
    }
}

function Get-CommandsRoot {
    param([string]$Client)
    switch ($Client) {
        'opencode'       { return (Join-Path $env:USERPROFILE '.config\opencode\commands') }
        'claude'         { return (Join-Path $env:USERPROFILE '.claude\commands') }
        # Codex has no slash-command directory; claude-desktop has no commands.
        'codex'          { return $null }
        'claude-desktop' { return $null }
        default          { return $null }
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
        if (-not $root) { continue }          # claude-desktop: skills go via zip upload
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
    # No skills directory at all (claude-desktop): the skill is still "available"
    # because it is packaged into a zip further down.
    if (@($TargetRoots | Where-Object { $_ }).Count -eq 0) { return $true }
    return $ok
}

function New-ClaudeDesktopSkillZips {
    <#
      Claude Desktop cannot read a skills directory. Each skill must be uploaded
      by hand through Settings > Capabilities > Skills, so pre-build one zip per
      skill. Layout: <id>.zip -> <id>/SKILL.md
    #>
    param([string[]]$Ids, [string]$VendorRoot, [string]$LocalRoot)

    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $outDir = Join-Path $PackRoot 'dist\claude-skills'
    if (-not $DryRun) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $made = 0
    foreach ($id in $Ids) {
        $src = Join-Path $VendorRoot $id
        if (-not (Test-Path $src)) { $src = Join-Path $LocalRoot $id }
        if (-not (Test-Path (Join-Path $src 'SKILL.md'))) { continue }
        $zip = Join-Path $outDir "$id.zip"
        if ($DryRun) { Write-Ok "would build $zip"; $made++; continue }
        if (Test-Path $zip) { Remove-Item $zip -Force }
        try {
            [IO.Compression.ZipFile]::CreateFromDirectory(
                $src, $zip, [IO.Compression.CompressionLevel]::Optimal, $true)
            $made++
        } catch {
            Write-Warn2 "zip failed for $id : $($_.Exception.Message)"
        }
    }
    Write-Ok "$made skill zips in $outDir"
    Write-Skip 'upload only the skills you need; Claude Desktop has no folder-based skill loading'
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
        # PS 5.1 pretty-prints empty arrays as multi-line brackets; collapse them.
        $text = ($h | ConvertTo-Json -Depth 20) -replace '\[\s*\]', '[]'
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

function Register-ClaudeDesktopMcp {
    <#
      Claude Desktop is a GUI app: it has no skills directory and no slash
      commands. It only reads MCP servers from claude_desktop_config.json.
    #>
    param([string]$Name, [string]$Exe)

    $dir  = Join-Path $env:APPDATA 'Claude'
    $path = Join-Path $dir 'claude_desktop_config.json'

    if (Test-Path $path) {
        try {
            $cfg = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
            $backup = "$path.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            if (-not $DryRun) { Copy-Item $path $backup -Force }
            Write-Skip "backed up Claude Desktop config to $backup"
        } catch {
            Write-Warn2 "cannot parse $path; not auto-merging"
            Write-Host '  Merge config\claude_desktop_config.json by hand.'
            return $false
        }
    } else {
        $cfg = [pscustomobject]@{}
    }

    $h = ConvertTo-Hashtable $cfg
    if ($null -eq $h) { $h = @{} }
    if (-not $h.ContainsKey('mcpServers') -or -not ($h['mcpServers'] -is [hashtable])) { $h['mcpServers'] = @{} }
    $h['mcpServers'][$Name] = @{
        command = $Exe
        args    = @()
        env     = @{ FLUIDS_MCP_LOG_LEVEL = 'INFO'; FLUIDS_MCP_MAX_STEPS = '30' }
    }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        # PS 5.1 pretty-prints empty arrays as multi-line brackets; collapse them.
        $text = ($h | ConvertTo-Json -Depth 20) -replace '\[\s*\]', '[]'
        [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding($false)))
    }
    Write-Ok "wrote mcpServers.$Name to $path"
    Write-Skip 'quit Claude Desktop from the tray and reopen it; closing the window is not enough'
    return $true
}

function Register-CodexMcp {
    <#
      Codex reads MCP servers from ~/.codex/config.toml. There is no CLI
      subcommand that writes this, so append a block if it is not present.
    #>
    param([string]$Name, [string]$Exe)

    $dir  = Join-Path $env:USERPROFILE '.codex'
    $path = Join-Path $dir 'config.toml'

    if ((Test-Path $path) -and (Select-String -Path $path -Pattern "^\[mcp_servers\.$([regex]::Escape($Name))\]" -Quiet)) {
        Write-Skip "$Name already present in $path"
        return $true
    }
    if ($DryRun) { Write-Ok "would append [mcp_servers.$Name] to $path"; return $true }

    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    # TOML literal strings are single-quoted, so Windows backslashes need no escaping.
    $block = @(
        ''
        "[mcp_servers.$Name]"
        "command = '$Exe'"
        'args = []'
        'startup_timeout_sec = 45'
        'tool_timeout_sec = 600'
        ''
    )
    # Only the Fluent server reads these; keep the Origin block clean.
    if ($Name -eq 'ansys-fluent') {
        $block += @(
            "[mcp_servers.$Name.env]"
            'FLUIDS_MCP_LOG_LEVEL = "INFO"'
            'FLUIDS_MCP_MAX_STEPS = "30"'
            ''
        )
    }
    $block = $block -join "`r`n"

    [IO.File]::AppendAllText($path, $block, (New-Object Text.UTF8Encoding($false)))
    Write-Ok "appended [mcp_servers.$Name] to $path"
    return $true
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

function Register-Mcp {
    <#
      Register one MCP server with every selected client. Each client stores
      servers elsewhere, so the dispatch stays in one place.
    #>
    param([string]$Name, [string]$Exe)

    $ok = $true
    if ($Clients -contains 'opencode')       { $ok = [bool](Register-OpenCodeMcp -Name $Name -Exe $Exe) }
    if ($Clients -contains 'claude')         { Register-ClaudeMcp -Name $Name -Exe $Exe }
    if ($Clients -contains 'codex')          { [void](Register-CodexMcp -Name $Name -Exe $Exe) }
    if ($Clients -contains 'claude-desktop') { [void](Register-ClaudeDesktopMcp -Name $Name -Exe $Exe) }
    $script:mcpStatus[$Name] = $ok
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
    'nature-statistics', 'nature-shared', 'origin-pro'
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
# The MCP is useless without its skill, so -WithOrigin pulls origin-pro into
# core/sim profiles that do not include it by default.
if ($WithOrigin) { $selected = $selected + 'origin-pro' }
$selected = $selected | Select-Object -Unique

$localIds = @('journal-pipeline', 'cfd-fluent-pipeline')

# ---------------------------------------------------------------- run

Write-Banner
Write-Host "  Pack    : $PackRoot"
Write-Host "  Profile : $Profile ($($selected.Count) upstream + $($localIds.Count) local skills)"
Write-Host "  Clients : $($Clients -join ', ')"
if ($DryRun) { Write-Host '  Mode    : DRY RUN (nothing will be written)' -ForegroundColor Yellow }
if ($WithFluent) { Write-Host '  Fluent  : MCP will be installed' }
if ($WithOrigin) { Write-Host '  Origin  : MCP will be installed (Windows + OriginPro)' }
if ($WithARS) { Write-Host '  ARS     : optional module will be cloned' }

$mcpStatus = @{}
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
foreach ($c in $Clients) {
    $r = Get-SkillsRoot $c
    if ($r) { $targets += $r } else { Write-Skip "$c has no skills directory (skills are uploaded as a zip)" }
}
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

# 4b. Claude Desktop skill zips
if ($Clients -contains 'claude-desktop') {
    Write-Step 'Building Claude Desktop skill zips'
    New-ClaudeDesktopSkillZips -Ids ($selected + $localIds) -VendorRoot $vendorRoot -LocalRoot $localRoot
}

# 5. Fluent MCP
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
            if (-not $DryRun) { & $py -m venv $venv; Write-Ok "created venv: $venv" }
            else { Write-Skip "would create venv: $venv" }
        } else {
            Write-Skip "venv exists: $venv"
        }
        if (-not $DryRun) {
            # pip can fail on a broken venv or a network hiccup; that must not
            # abort the whole install, otherwise skills are half-written.
            $pipOk = $false
            try {
                & $venvPy -m pip install --upgrade pip --quiet 2>&1 | Out-Null
                & $venvPy -m pip install --upgrade ansys-fluent-mcp --quiet 2>&1 | Out-Null
                $pipOk = ($LASTEXITCODE -eq 0)
            } catch {
                $pipOk = $false
            }
            if ($pipOk) {
                Write-Ok 'installed ansys-fluent-mcp'
            } else {
                Write-Warn2 'pip install failed; run manually:'
                Write-Host "       `"$venvPy`" -m pip install ansys-fluent-mcp"
            }
        }
        $exe = Join-Path $venv 'Scripts\ansys-fluent-mcp.exe'
        if ((Test-Path $exe) -or $DryRun) {
            Register-Mcp -Name 'ansys-fluent' -Exe $exe
        } else {
            Write-Warn2 "MCP entry point not found: $exe"
        }
    }
}

# 5b. Origin MCP (bundled source, Windows only)
if ($WithOrigin) {
    Write-Step 'Setting up Origin Pro MCP'
    if ($env:OS -ne 'Windows_NT') {
        Write-Warn2 'origin-pro drives Origin through COM: Windows only. Skipped.'
    } elseif (-not (Test-Path (Join-Path $PackRoot 'mcp\origin-pro\pyproject.toml'))) {
        Write-Warn2 'bundled source missing: mcp\origin-pro'
    } else {
        $py = Get-Python $PythonExe
        if (-not $py) {
            Write-Err2 'Python not found. Install Python 3.10+ and re-run with -PythonExe.'
        } else {
            $originSrc = Join-Path $PackRoot 'mcp\origin-pro'
            $venv = Join-Path $PackRoot '.venv'
            $venvPy = Join-Path $venv 'Scripts\python.exe'
            if (-not (Test-Path $venvPy)) {
                if (-not $DryRun) { & $py -m venv $venv; Write-Ok "created venv: $venv" }
                else { Write-Skip "would create venv: $venv" }
            } else {
                Write-Skip "venv exists: $venv"
            }
            if (-not $DryRun) {
                $pipOk = $false
                try {
                    & $venvPy -m pip install --upgrade pip --quiet 2>&1 | Out-Null
                    & $venvPy -m pip install --upgrade $originSrc --quiet 2>&1 | Out-Null
                    $pipOk = ($LASTEXITCODE -eq 0)
                } catch {
                    $pipOk = $false
                }
                if ($pipOk) {
                    Write-Ok 'installed origin-pro-mcp'
                } else {
                    Write-Warn2 'pip install failed; run manually:'
                    Write-Host "       `"$venvPy`" -m pip install `"$originSrc`""
                }
            }
            $exe = Join-Path $venv 'Scripts\origin-pro-mcp.exe'
            if ((Test-Path $exe) -or $DryRun) {
                Register-Mcp -Name 'origin-pro' -Exe $exe
                Write-Skip 'start OriginPro yourself before using it; the MCP does not launch Origin'
            } else {
                Write-Warn2 "MCP entry point not found: $exe"
            }
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
    "mcp ansys-fluent: $([bool]$mcpStatus['ansys-fluent'])",
    "mcp origin-pro  : $([bool]$mcpStatus['origin-pro'])"
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
if ($Clients -contains 'opencode') {
    Write-Host '    OpenCode       : open OpenCode, then  /paper   or   /cfd'
}
if ($Clients -contains 'claude') {
    Write-Host '    Claude Code    : claude , then         /paper   or   /cfd'
}
if ($Clients -contains 'codex') {
    Write-Host '    Codex CLI      : codex , then          /skills  and pick journal-pipeline'
    Write-Host '                     (or type $journal-pipeline to invoke it directly)'
}
if ($Clients -contains 'claude-desktop') {
    Write-Host '    Claude Desktop : Settings > Capabilities > Skills > upload dist\claude-skills\*.zip'
    Write-Host '                     MCP only took effect after a full quit from the tray'
}
if ($WithOrigin -and $env:OS -eq 'Windows_NT') {
    Write-Host '    OriginPro      : start Origin first, then ask for a figure (origin-pro tools)'
}
Write-Host '    Verify         : .\verify.ps1'
Write-Host '    Docs           : docs\01-技能路由表.md   docs\08-客户端接入.md'
Write-Host ''
