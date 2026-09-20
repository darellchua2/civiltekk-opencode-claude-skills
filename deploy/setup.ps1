<#
.SYNOPSIS
    OpenCode Configuration Setup Script for Windows (PowerShell)

.DESCRIPTION
    Automated setup for OpenCode configuration on Windows with proper error
    handling, logging, and user experience enhancements.

.EXAMPLE
    .\setup.ps1                      # Interactive menu (recommended)
    .\setup.ps1 -Quick               # Quick setup (config + skills only)
    .\setup.ps1 -SkillsOnly          # Skills deployment only
    .\setup.ps1 -Update              # Update OpenCode CLI to latest
    .\setup.ps1 -DryRun              # Preview all actions without changes
    .\setup.ps1 -Yes                 # Auto-accept all prompts
    .\setup.ps1 -Rollback -RollbackTarget list   # List available backups
    .\setup.ps1 -Rollback -RollbackTarget latest # Restore most recent backup
    .\setup.ps1 -Rollback -RollbackArg 20260719_070926  # Restore by TIMESTAMP
    .\setup.ps1 -NoZipBackup         # Deploy without creating zip archive
    .\setup.ps1 -Yes -Quick -Provider zai                  # Headless quick deploy
    .\setup.ps1 -Yes -EnablePack markitdown,nextjs         # CI: defaults + packs
    .\setup.ps1 -Yes -Provider openai -EnablePack markitdown -SkillProfile lean
    .\setup.ps1 -DryRun -Yes -EnablePack autodesk          # Preview a combo
    .\setup.ps1 -Help                # Show detailed help

.NOTES
    Requires PowerShell 5.1+ (ships with Windows 10/11)
#>

[CmdletBinding()]
param(
    [switch]$Quick,
    [switch]$SkillsOnly,
    [switch]$Update,
    [switch]$DryRun,
    [switch]$Yes,
    [switch]$Help,

    [ValidateSet("daily", "weekly", "monthly", "manual")]
    [string]$ScheduleUpdate = "manual",

    [switch]$EnableAutoUpdate,
    [switch]$DisableAutoUpdate,
    [switch]$CheckUpdate,

    [int]$KeepBackups = 5,

    # v2.0.0: Rollback mode (mirrors --rollback in setup.sh)
    [switch]$Rollback,
    [ValidateSet("list", "latest", "")]
    [string]$RollbackTarget = "",
    # RollbackTarget only accepts 'list' or 'latest' via parameter validation.
    # For TIMESTAMP or VERSION targets, pass -RollbackArg "<value>" instead.
    [string]$RollbackArg = "",

    # v2.0.0: Skip zip archive creation (zip is on by default)
    [switch]$NoZipBackup,

    # v2.0 model resolution
    [string]$Provider = "",
    [switch]$ModelsOnly,
    [switch]$Force,
    [switch]$Migrate,
    [switch]$Mix,
    # Provider packs (#268): deploy-time MCP toggle. CSV of pack names
    # (autodesk,markitdown,nextjs,docling,chrome-devtools). Empty = no-op.
    [string]$EnablePack = "",
    # Skill profile (GIT-333): deploy-time primary visibility. lean (default)
    # rewrites the DEPLOYED config's skill permissions (permissions array) to
    # 46 visible skills;
    # full deploys the shipped 107-allow allowlist verbatim.
    [ValidateSet("lean", "full")]
    [string]$SkillProfile = "lean"
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Version Latest

################################################################################
# GLOBAL VARIABLES
################################################################################

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Get-Location }

# Resolve repo root (setup.ps1 lives in deploy/, repo root is one level up)
$RepoDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$VersionFile = Join-Path $RepoDir "VERSION"
if (Test-Path $VersionFile) {
    $ScriptVersion = (Get-Content $VersionFile -Raw).Trim()
} else {
    $ScriptVersion = "2.0.0"
}

$ConfigDir = Join-Path $HOME ".config\opencode"
# OpenCode v2 only discovers opencode.json / opencode.jsonc — never config.json.
$ConfigFile = Join-Path $ConfigDir "opencode.json"
$LegacyConfigFile = Join-Path $ConfigDir "config.json"
$JsoncConfigFile = Join-Path $ConfigDir "opencode.jsonc"
$SkillsDir = Join-Path $ConfigDir "skills"
$AgentsSrcDir = Join-Path $RepoDir "agents"
$AgentsDestDir = Join-Path $ConfigDir "agents"
# Repo-owned plugins (auto-loaded by opencode from this dir). Mirrors the
# agents/skills deploy pattern. Currently: opencode-skill-counter-sync.
$PluginsSrcDir = Join-Path $RepoDir "plugins"
$PluginsDestDir = Join-Path $ConfigDir "plugins"
$BackupDir = Join-Path $HOME ".opencode-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$LogFile = Join-Path $HOME ".opencode-setup.log"
$LastUpdateCheck = Join-Path $ConfigDir ".last-update-check"
$UpdateLog = Join-Path $ConfigDir "update.log"

# v2.0 model resolution (tier-based, provider-agnostic)
$DeployDir = Join-Path $RepoDir "deploy"
$InstallDir = Join-Path $RepoDir "installer"
$ResolverScript = Join-Path $InstallDir "resolve-models.mjs"
$MergePacksScript = Join-Path $DeployDir "merge-packs.mjs"
$PacksDir = Join-Path $DeployDir "packs"
$ApplySkillProfileScript = Join-Path $DeployDir "apply-skill-profile.mjs"
$SkillProfilesFile = Join-Path $DeployDir "skill-profiles.json"
$TuiScript = Join-Path $DeployDir "tui.mjs"
$AgentTiers = Join-Path $InstallDir "agent-tiers.json"
$ModelsDefaultMap = Join-Path $InstallDir "models.default.json"
$ProviderPresets = Join-Path $InstallDir "provider-presets.json"
# Global user overrides (~/.config/opencode/)
$UserModelsMap = Join-Path $ConfigDir "models.json"
$UserOverrides = Join-Path $ConfigDir "agent-overrides.json"
# Project-local overrides (repo root .opencode/)
$ProjectModelsMap = Join-Path $RepoDir ".opencode\models.json"
$ProjectOverrides = Join-Path $RepoDir ".opencode\agent-overrides.json"
# Resolver state + migration marker
$ResolvedSidecar = Join-Path $ConfigDir ".resolved-models.json"
$ConfigVersionFile = Join-Path $ConfigDir ".config-version"
$SchemaVersion = "2.0"
$SourceConfig = Join-Path $RepoDir "opencode_app\opencode.json"

$ZaiApiKey = $env:ZAI_API_KEY

$SkipConfigCopy = $false

################################################################################
# LOGGING FUNCTIONS
################################################################################

function Initialize-Logging {
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    if (-not (Test-Path $LogFile)) {
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
    }
    Write-Log "INFO" "=== OpenCode Setup Started at $(Get-Date) ==="
    Write-Log "INFO" "Script version: $ScriptVersion"
    Write-Log "INFO" "User: $env:USERNAME"
    Write-Log "INFO" "PowerShell version: $($PSVersionTable.PSVersion)"
    Write-Log "INFO" "Working directory: $(Get-Location)"
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -Path $LogFile -Value $logLine -ErrorAction SilentlyContinue
    } catch {}

    switch ($Level) {
        "ERROR"   { Write-Host "[$Level] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[$Level] $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "[$Level] $Message" -ForegroundColor Green }
        "DEBUG"   { if ($VerbosePreference -eq "Continue") { Write-Host "[$Level] $Message" -ForegroundColor Gray } }
        default   { Write-Host "[$Level] $Message" }
    }
}

function Write-LogInfo    { param([string]$Msg) Write-Log "INFO"    $Msg }
function Write-LogWarn    { param([string]$Msg) Write-Log "WARNING" $Msg }
function Write-LogError   { param([string]$Msg) Write-Log "ERROR"   $Msg }
function Write-LogSuccess { param([string]$Msg) Write-Log "SUCCESS" $Msg }
function Write-LogDebug   { param([string]$Msg) Write-Log "DEBUG"   $Msg }

# Count active SKILL.md files in a directory, excluding _archived (matches the
# deploy's _archived skip). Drift-proof skill count for banners/status. BT-157.
function Get-SkillCount {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    return @(Get-ChildItem -Path $Path -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -notmatch "[\\/]_archived[\\/]" }).Count
}

function Get-AgentCount {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    return @(Get-ChildItem -Path $Path -Filter "*.md" -File -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -notmatch "[\\/]_archived[\\/]" }).Count
}

# Auto-derive per-category counts from skill frontmatter (category: field),
# excluding _archived. Prints "Category (N)" lines sorted by count desc. BT-157.
function Get-SkillCategories {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    Get-ChildItem -Path $Path -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "[\\/]_archived[\\/]" } |
        ForEach-Object {
            $cat = (Get-Content $_.FullName -ErrorAction SilentlyContinue |
                    Where-Object { $_ -match '^\s*category:\s*(.+)$' } |
                    Select-Object -First 1) -replace '^\s*category:\s*',''
            [pscustomobject]@{ Category = $cat.Trim() }
        } |
        Where-Object { $_.Category } |
        Group-Object Category |
        Sort-Object Count -Descending |
        ForEach-Object { "    - {0} ({1})" -f $_.Name, $_.Count }
}

################################################################################
# UTILITY FUNCTIONS
################################################################################

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-WithDryRun {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string]$Description = $Command
    )

    Write-LogDebug "Executing: $Command"

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would execute: $Command" -ForegroundColor Cyan
        return $true
    }

    # Execute via ScriptBlock so stdout flows through and $LASTEXITCODE is
    # honoured for native executables (npm, winget, choco, etc.). The previous
    # implementation only caught parsing exceptions and ALWAYS returned $true,
    # which masked real failures like `npm install -g opencode-ai` errors.
    try {
        $scriptBlock = [ScriptBlock]::Create($Command)
        & $scriptBlock | Out-Host
        # $LASTEXITCODE is set by native executables. PowerShell cmdlets that
        # fail throw instead, so we're covered both ways.
        if (Test-Path Variable:\LASTEXITCODE) {
            return $LASTEXITCODE -eq 0
        }
        return $true
    } catch {
        Write-LogError "Command failed: $Description"
        Write-LogError $_.Exception.Message
        return $false
    }
}

function Read-Prompt {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Default = ""
    )

    if ($Yes -and $Default) {
        Write-LogDebug "Auto-accepting with default: $Default"
        return $Default
    }

    $promptText = if ($Default) { "${Message} [${Default}]: " } else { "${Message}: " }
    $result = Read-Host $promptText
    if ([string]::IsNullOrWhiteSpace($result) -and $Default) {
        return $Default
    }
    return $result
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Message,
        [bool]$DefaultYes = $false
    )

    if ($Yes) {
        return $DefaultYes
    }

    $defaultDisplay = if ($DefaultYes) { "Y/n" } else { "y/N" }

    while ($true) {
        $response = Read-Host "$Message [$defaultDisplay]"
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $DefaultYes
        }
        if ($response -match "^[YyNn]$") {
            return $response -match "^[Yy]"
        }
        Write-Host "Invalid input. Please enter y or n." -ForegroundColor Yellow
    }
}

function New-FileBackup {
    param([Parameter(Mandatory)][string]$FilePath)

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        Write-LogInfo "Created backup directory: $BackupDir"
    }

    if (Test-Path $FilePath) {
        $fileName = Split-Path $FilePath -Leaf
        $backupPath = Join-Path $BackupDir $fileName
        Copy-Item $FilePath $backupPath -Force
        Write-LogInfo "Backed up: $FilePath -> $backupPath"
    }
}

function Remove-OldBackups {
    if ($KeepBackups -lt 0) {
        Write-LogDebug "Backup cleanup disabled (KeepBackups=$KeepBackups)"
        return
    }

    $allBackups = @(Get-ChildItem $HOME -Directory -Filter ".opencode-backup-*" -ErrorAction SilentlyContinue)
    $allBackups += @(Get-ChildItem $HOME -Directory -Filter ".opencode-update-backup-*" -ErrorAction SilentlyContinue)

    if ($allBackups.Count -eq 0) {
        Write-LogDebug "No old backups found"
        return
    }

    $allBackups = $allBackups | Sort-Object LastWriteTime -Descending

    if ($allBackups.Count -le $KeepBackups) {
        Write-LogDebug "Found $($allBackups.Count) backup(s) (within retention limit of $KeepBackups)"
        return
    }

    $toDelete = $allBackups | Select-Object -Skip $KeepBackups
    Write-LogInfo "Cleaning up old backups (keeping $KeepBackups of $($allBackups.Count))..."

    foreach ($dir in $toDelete) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would remove old backup: $($dir.FullName)" -ForegroundColor Cyan
            $siblingZip = "$($dir.FullName).zip"
            if (Test-Path $siblingZip) {
                Write-Host "[DRY-RUN] Would remove old backup zip: $siblingZip" -ForegroundColor Cyan
            }
        } else {
            Remove-Item $dir.FullName -Recurse -Force
            Write-LogInfo "Removed old backup: $($dir.FullName)"
            # Also remove sibling .zip archive if it exists
            $siblingZip = "$($dir.FullName).zip"
            if (Test-Path $siblingZip) {
                Remove-Item $siblingZip -Force
                Write-LogInfo "Removed old backup zip: $siblingZip"
            }
        }
    }

    Write-LogSuccess "Cleaned up $($toDelete.Count) old backup(s)"
}

################################################################################
# ZIP BACKUP AND ROLLBACK FUNCTIONS (v2.0.0)
################################################################################

function New-ZipBackup {
    # Respects $NoZipBackup toggle and $DryRun
    if ($NoZipBackup) {
        Write-LogDebug "Zip backup disabled (-NoZipBackup)"
        return $true
    }

    if (-not (Test-Path $BackupDir)) {
        Write-LogDebug "Skipping zip: BackupDir does not exist ($BackupDir)"
        return $true
    }

    $items = @(Get-ChildItem $BackupDir -ErrorAction SilentlyContinue)
    if ($items.Count -eq 0) {
        Write-LogDebug "Skipping zip: BackupDir is empty ($BackupDir)"
        return $true
    }

    $zipPath = "$BackupDir.zip"

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would execute: Compress-Archive -Path $BackupDir\* -DestinationPath $zipPath -Force" -ForegroundColor Cyan
        return $true
    }

    Write-LogInfo "Creating zip archive: $zipPath"
    try {
        Compress-Archive -Path "$BackupDir\*" -DestinationPath $zipPath -Force -ErrorAction Stop
        Write-LogSuccess "Zip archive created: $zipPath"
        return $true
    } catch {
        Write-LogWarn "Compress-Archive failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-Backups {
    # Returns an array of backup directory objects (newest first), any prefix.
    $result = @()
    $result += @(Get-ChildItem $HOME -Directory -Filter ".opencode-backup-*" -ErrorAction SilentlyContinue)
    $result += @(Get-ChildItem $HOME -Directory -Filter ".opencode-update-backup-*" -ErrorAction SilentlyContinue)
    $result += @(Get-ChildItem $HOME -Directory -Filter ".opencode-pre-rollback-backup-*" -ErrorAction SilentlyContinue)
    return ($result | Sort-Object Name -Descending)
}

function Show-Backups {
    $all = Get-Backups
    if ($all.Count -eq 0) {
        Write-Host "No backups found in $HOME"
        Write-Host ""
        Write-Host "Backups are created automatically by:"
        Write-Host "  - .\setup.ps1 (full deploy)"
        Write-Host "  - .\setup.ps1 -Rollback (pre-rollback safety)"
        return
    }

    $fmt = "{0,-17} {1,-22} {2,-10} {3,-5} {4}"
    Write-Host ($fmt -f "TIMESTAMP", "TYPE", "SIZE", "ZIP", "PATH")
    Write-Host ("-" * 100)

    foreach ($dir in $all) {
        $name = $dir.Name
        $ts = ""
        $btype = "backup"

        if ($name -like ".opencode-backup-*") {
            $ts = $name -replace "^\.opencode-backup-", ""
            $btype = "backup"
        } elseif ($name -like ".opencode-update-backup-*") {
            $ts = $name -replace "^\.opencode-update-backup-", ""
            $btype = "update"
        } elseif ($name -like ".opencode-pre-rollback-backup-*") {
            $ts = $name -replace "^\.opencode-pre-rollback-backup-", ""
            $btype = "pre-rollback"
        }

        $size = "?"
        try {
            $sizeBytes = (Get-ChildItem $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if ($sizeBytes -ge 1MB) { $size = "{0:N0}M" -f ($sizeBytes / 1MB) }
            elseif ($sizeBytes -ge 1KB) { $size = "{0:N0}K" -f ($sizeBytes / 1KB) }
            else { $size = "$sizeBytes" }
        } catch {}

        $zipMarker = "-"
        if (Test-Path "$($dir.FullName).zip") { $zipMarker = "zip" }

        Write-Host ($fmt -f $ts, $btype, $size, $zipMarker, $dir.FullName)
    }

    # List orphan zips (no matching flat dir)
    $orphanZips = @()
    $orphanZips += @(Get-ChildItem $HOME -File -Filter ".opencode-backup-*.zip" -ErrorAction SilentlyContinue)
    $orphanZips += @(Get-ChildItem $HOME -File -Filter ".opencode-update-backup-*.zip" -ErrorAction SilentlyContinue)
    $orphanZips += @(Get-ChildItem $HOME -File -Filter ".opencode-pre-rollback-backup-*.zip" -ErrorAction SilentlyContinue)
    $orphanZips = $orphanZips | Sort-Object Name -Descending
    if ($orphanZips.Count -gt 0) {
        Write-Host ""
        Write-Host "Orphan archives (no matching flat dir):"
        foreach ($z in $orphanZips) {
            $zsize = "?"
            try { $zsize = "{0:N0}K" -f ($z.Length / 1KB) } catch {}
            Write-Host ("  {0,-40} {1,-10} {2}" -f $z.Name, $zsize, $z.FullName)
        }
    }
}

function Get-LatestBackup {
    $all = Get-Backups
    if ($all.Count -eq 0) { return $null }
    return $all[0]
}

function Resolve-BackupTarget {
    param([Parameter(Mandatory)][string]$Target)

    # TIMESTAMP pattern: YYYYMMDD_HHMMSS
    if ($Target -match "^\d{8}_\d{6}$") {
        foreach ($prefix in @(".opencode-backup-", ".opencode-update-backup-", ".opencode-pre-rollback-backup-")) {
            $candidate = Join-Path $HOME "${prefix}${Target}"
            if (Test-Path $candidate) { return $candidate }
        }
        # Fall back to zip-only
        foreach ($prefix in @(".opencode-backup-", ".opencode-update-backup-", ".opencode-pre-rollback-backup-")) {
            $candidate = Join-Path $HOME "${prefix}${Target}.zip"
            if (Test-Path $candidate) { return $candidate }
        }
        return $null
    }

    # VERSION pattern: vX.Y.Z or X.Y.Z
    if ($Target -match "^v?\d+\.\d+\.\d+$") {
        $cleanVer = $Target -replace "^v", ""
        Write-LogInfo "Resolving version $cleanVer via VERSION file git history..."

        $versionCommitDate = $null
        if ((Test-CommandExists "git") -and (Test-Path (Join-Path $RepoDir ".git"))) {
            try {
                Push-Location $RepoDir
                $versionCommitDate = git log -1 --format=%ci -- VERSION 2>$null | Select-Object -First 1
                if (-not $versionCommitDate) {
                    $versionCommitDate = git log -1 --format=%ai "v$cleanVer" 2>$null | Select-Object -First 1
                }
                # Try by VERSION file content at each commit
                if (-not $versionCommitDate) {
                    $commits = git log --format=%H -- VERSION 2>$null
                    foreach ($commit in $commits) {
                        $content = (git show "${commit}:VERSION" 2>$null) -replace "\s", ""
                        if ($content -eq $cleanVer) {
                            $versionCommitDate = git log -1 --format=%ci $commit 2>$null | Select-Object -First 1
                            break
                        }
                    }
                }
                Pop-Location
            } catch {
                try { Pop-Location } catch {}
            }
        }

        if (-not $versionCommitDate) {
            Write-LogWarn "Could not resolve version $cleanVer to a git commit date"
            return $null
        }

        # Convert git date string to comparable YYYYMMDDHHMMSS
        $gitDate = [datetime]$versionCommitDate
        $gitTsNumeric = $gitDate.ToString("yyyyMMddHHmmss")
        Write-LogInfo "Version $cleanVer corresponds to commit timestamp $gitTsNumeric"

        $bestDir = $null
        $bestTs = ""
        foreach ($dir in (Get-Backups)) {
            $name = $dir.Name
            $ts = ""
            foreach ($prefix in @(".opencode-backup-", ".opencode-update-backup-", ".opencode-pre-rollback-backup-")) {
                if ($name -like "${prefix}*") {
                    $ts = $name -replace "^$([regex]::Escape($prefix))", ""
                    break
                }
            }
            if ($ts -notmatch "^\d{8}_\d{6}$") { continue }
            $tsNumeric = ($ts -replace "_", "")
            if ([int64]$tsNumeric -le [int64]$gitTsNumeric) {
                if (-not $bestTs -or ([int64]$tsNumeric -gt [int64]$bestTs)) {
                    $bestTs = $tsNumeric
                    $bestDir = $dir.FullName
                }
            }
        }

        return $bestDir
    }

    return $null
}

function Restore-FromDir {
    param([Parameter(Mandatory)][string]$SrcDir)

    if (-not (Test-Path $SrcDir)) {
        Write-LogError "Source dir does not exist: $SrcDir"
        return $false
    }

    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }

    # opencode.json (pre-v2.1 backups stored it as config.json)
    if (Test-Path (Join-Path $SrcDir "opencode.json")) {
        Copy-Item (Join-Path $SrcDir "opencode.json") $ConfigFile -Force
        Write-LogInfo "Restored: opencode.json"
    } elseif (Test-Path (Join-Path $SrcDir "config.json")) {
        Copy-Item (Join-Path $SrcDir "config.json") $ConfigFile -Force
        Write-LogInfo "Restored: opencode.json (from legacy config.json backup)"
    }

    # AGENTS.md
    $agentsDest = Join-Path $ConfigDir "AGENTS.md"
    if (Test-Path (Join-Path $SrcDir "AGENTS.md")) {
        Copy-Item (Join-Path $SrcDir "AGENTS.md") $agentsDest -Force
        Write-LogInfo "Restored: AGENTS.md"
    }

    # skills/ (prefer "skills" over "skills-backup")
    if (Test-Path (Join-Path $SrcDir "skills")) {
        if (Test-Path $SkillsDir) { Remove-Item $SkillsDir -Recurse -Force }
        Copy-Item (Join-Path $SrcDir "skills") $SkillsDir -Recurse -Force
        Write-LogInfo "Restored: skills/"
    } elseif (Test-Path (Join-Path $SrcDir "skills-backup")) {
        if (Test-Path $SkillsDir) { Remove-Item $SkillsDir -Recurse -Force }
        Copy-Item (Join-Path $SrcDir "skills-backup") $SkillsDir -Recurse -Force
        Write-LogInfo "Restored: skills/ (from skills-backup/)"
    }

    # agents/
    if (Test-Path (Join-Path $SrcDir "agents")) {
        if (Test-Path $AgentsDestDir) { Remove-Item $AgentsDestDir -Recurse -Force }
        Copy-Item (Join-Path $SrcDir "agents") $AgentsDestDir -Recurse -Force
        Write-LogInfo "Restored: agents/"
    } elseif (Test-Path (Join-Path $SrcDir "agents-backup")) {
        if (Test-Path $AgentsDestDir) { Remove-Item $AgentsDestDir -Recurse -Force }
        Copy-Item (Join-Path $SrcDir "agents-backup") $AgentsDestDir -Recurse -Force
        Write-LogInfo "Restored: agents/ (from agents-backup/)"
    }

    # Other top-level *.json / *.md files
    Get-ChildItem $SrcDir -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notin @("config.json", "opencode.json", "AGENTS.md") -and ($_.Extension -in ".json", ".md")
    } | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $ConfigDir $_.Name) -Force
        Write-LogInfo "Restored: $($_.Name)"
    }

    return $true
}

function New-PreRollbackBackup {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $preDir = Join-Path $HOME ".opencode-pre-rollback-backup-$ts"

    Write-LogInfo "Creating pre-rollback safety backup..."

    if (-not (Test-Path $preDir)) {
        New-Item -ItemType Directory -Path $preDir -Force | Out-Null
    }

    if (Test-Path $ConfigFile) {
        Copy-Item $ConfigFile (Join-Path $preDir "opencode.json") -Force
    }
    $agentsMd = Join-Path $ConfigDir "AGENTS.md"
    if (Test-Path $agentsMd) {
        Copy-Item $agentsMd (Join-Path $preDir "AGENTS.md") -Force
    }
    if (Test-Path $SkillsDir) {
        Copy-Item $SkillsDir (Join-Path $preDir "skills") -Recurse -Force
    }
    if (Test-Path $AgentsDestDir) {
        Copy-Item $AgentsDestDir (Join-Path $preDir "agents") -Recurse -Force
    }
    $vgCfgPre = Join-Path $ConfigDir "vibeguard.config.json"
    if (Test-Path $vgCfgPre) {
        Copy-Item $vgCfgPre (Join-Path $preDir "vibeguard.config.json") -Force
    }

    Write-LogSuccess "Pre-rollback backup created: $preDir"
    return $preDir
}

function Invoke-Rollback {
    # Determine the effective target string
    $target = $RollbackTarget
    if ([string]::IsNullOrWhiteSpace($target) -and -not [string]::IsNullOrWhiteSpace($RollbackArg)) {
        $target = $RollbackArg
    }

    # Sub-mode: list
    if ($target -eq "list") {
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host "                Available Backups" -ForegroundColor White
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host ""
        Show-Backups
        return
    }

    # Resolve target → backup path (dir or zip)
    $backupPath = $null

    if ([string]::IsNullOrWhiteSpace($target)) {
        # Interactive picker
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host "                Select Backup to Restore" -ForegroundColor White
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host ""
        Show-Backups
        Write-Host ""

        if (-not $Yes) {
            $pick = Read-Host "Enter TIMESTAMP to restore (or 'q' to cancel)"
            if ([string]::IsNullOrWhiteSpace($pick) -or $pick -eq "q") {
                Write-LogInfo "Rollback cancelled"
                return
            }
            $target = $pick
        } else {
            Write-LogError "Interactive rollback requires a TARGET (cannot prompt with -Yes)"
            Write-LogInfo "Use: .\setup.ps1 -RollbackArg <TIMESTAMP>"
            Write-LogInfo "Or:  .\setup.ps1 -RollbackTarget latest"
            throw "Interactive rollback cannot proceed with -Yes and no target"
        }
    }

    if ($target -eq "latest") {
        $latest = Get-LatestBackup
        if (-not $latest) {
            Write-LogError "No backups available to restore from"
            throw "No backups available"
        }
        $backupPath = $latest.FullName
    } else {
        $backupPath = Resolve-BackupTarget -Target $target
        if (-not $backupPath) {
            Write-LogError "No backup found for target: '$target'"
            Write-LogInfo "Available backups:"
            Show-Backups
            throw "No backup found for target: '$target'"
        }
    }

    Write-LogInfo "Resolved backup: $backupPath"

    # DRY-RUN: print plan, change nothing
    if ($DryRun) {
        Write-Host ""
        Write-Host "[DRY-RUN] Rollback plan:" -ForegroundColor Cyan
        Write-Host "  Source: $backupPath"
        Write-Host "  Target: $ConfigDir\"
        Write-Host "  Steps:"
        Write-Host "    1. Create pre-rollback backup of current state"
        Write-Host "    2. Confirm (or skip with -Yes)"
        if ($backupPath -like "*.zip") {
            Write-Host "    3. Extract archive to temp location"
            Write-Host "    4. Copy files to $ConfigDir\"
        } else {
            Write-Host "    3. Copy files to $ConfigDir\"
        }
        Write-Host ""
        return
    }

    # Confirmation prompt (unless -Yes)
    if (-not $Yes) {
        Write-Host ""
        Write-Host "WARNING: This will replace files in $ConfigDir\ with content from:" -ForegroundColor Yellow
        Write-Host "    $backupPath"
        Write-Host ""
        if (-not (Read-YesNo "Continue with rollback?" $false)) {
            Write-LogInfo "Rollback cancelled by user"
            return
        }
    }

    # STEP 1: Pre-rollback safety backup (ALWAYS — even with -Yes)
    $preDir = New-PreRollbackBackup

    # STEP 2: Resolve src dir (extract zip if needed)
    $srcDir = $backupPath
    $extractedTmp = $null
    if ($backupPath -like "*.zip") {
        Write-LogInfo "Extracting zip archive..."
        $extractedTmp = Join-Path $env:TEMP "opencode-rollback-$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -ItemType Directory -Path $extractedTmp -Force | Out-Null
        try {
            Expand-Archive -Path $backupPath -DestinationPath $extractedTmp -Force -ErrorAction Stop
            $srcDir = $extractedTmp
        } catch {
            Write-LogError "Failed to extract backup archive: $($_.Exception.Message)"
            Write-LogInfo "Your current state is unchanged"
            Remove-Item $extractedTmp -Recurse -Force -ErrorAction SilentlyContinue
            throw "Archive extraction failed"
        }
    } elseif (-not (Test-Path $backupPath)) {
        Write-LogError "Backup path is neither a directory nor a zip: $backupPath"
        throw "Invalid backup path"
    }

    # STEP 3: Restore
    Write-LogInfo "Restoring files to $ConfigDir\..."
    [void](Restore-FromDir -SrcDir $srcDir)

    # Cleanup temp dir
    if ($extractedTmp -and (Test-Path $extractedTmp)) {
        Remove-Item $extractedTmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-LogSuccess "Rollback complete!"
    Write-LogInfo "Restored from: $backupPath"
    Write-LogInfo "Pre-rollback backup saved to: $preDir"
    $preTs = (Split-Path $preDir -Leaf) -replace "^\.opencode-pre-rollback-backup-", ""
    Write-LogInfo "If rollback was wrong, run: .\setup.ps1 -Rollback -RollbackArg `"$preTs`""
}

function Test-ApiKey {
    param(
        [string]$Key,
        [string]$KeyName = "API Key"
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        Write-LogWarn "No $KeyName provided"
        return $false
    }
    if ($Key.Length -lt 10) {
        Write-LogWarn "$KeyName seems too short (minimum 10 characters)"
        return $false
    }
    return $true
}

function Get-MaskedValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -lt 12) { return "<hidden>" }
    return "$($Value.Substring(0,8))...$($Value.Substring($Value.Length - 4))"
}

################################################################################
# SHOW HELP
################################################################################

function Show-Help {
    @"

=======================================================================
                    OpenCode Configuration Setup v$ScriptVersion
                    (Windows PowerShell Edition)
=======================================================================

USAGE:
    .\setup.ps1 [OPTIONS]

=======================================================================
                            SETUP MODES
=======================================================================

  MODE                    WHAT IT DOES                          WHEN TO USE
  ----------------------------------------------------------------------
  Interactive (default)   Full setup with guided prompts       First-time setup
                           1. GitHub PAT setup (optional)
                           2. Z.AI API key setup
                           3. Node.js check/install
                           4. opencode-ai installation
                           5. opencode.json deployment
                           6. skills/ deployment
                           7. Environment variable persistence

  -Quick                  Copy config files only                Already have
                           1. opencode.json -> ~/.config/opencode/  dependencies
                           2. AGENTS.md -> ~/.config/opencode/
                           3. skills/* -> ~/.config/opencode/skills/

  -SkillsOnly             Deploy skills only                    opencode-ai already
                           1. Validates opencode-ai installed    installed
                           2. Copies skills/* to config dir

  -Update                 Update opencode-ai CLI only           Keep CLI current

  -Rollback [-RollbackTarget|-RollbackArg <T>]
                                                Restore from a previous backup
                          TARGET:
                            (omitted)             Interactive picker
                            -RollbackTarget latest     Most recent backup
                            -RollbackTarget list       List backups and exit
                            -RollbackArg <TIMESTAMP>   e.g. 20260719_070926
                            -RollbackArg <VERSION>     e.g. 1.76.0 (closest <= tag)
                          Safety: creates a pre-rollback backup first
                          Combine with -Yes to skip confirmation prompt

======================================================================
                            OPTIONS
======================================================================

  SETUP OPTIONS:
    -Quick                Quick setup mode (config + skills only)
    -SkillsOnly           Skills-only deployment mode
    -Update               Update OpenCode CLI to latest version
    -Rollback             Restore from previous backup (see above)

  UPDATE MANAGEMENT:
    -EnableAutoUpdate         Enable automatic opencode-ai updates
    -DisableAutoUpdate        Disable automatic updates
    -ScheduleUpdate <sched>   Set update frequency: daily, weekly, monthly, manual
    -CheckUpdate              Check for updates without installing

  UTILITY OPTIONS:
    -Help                Show this help message
    -DryRun              Preview all actions without making changes
    -Yes                 Auto-accept all prompts (non-interactive)
    -KeepBackups <N>     Keep only N most recent backups (default: 5)
                           0 = delete all old backups, negative = keep all
    -NoZipBackup         Skip zip archive creation (zip is created by default
                           alongside the flat-file backup for portability)

======================================================================
                          BACKUP AND ROLLBACK EXAMPLES
======================================================================

    .\setup.ps1 -Rollback -RollbackTarget list            # List backups
    .\setup.ps1 -Rollback -RollbackTarget latest          # Restore latest
    .\setup.ps1 -Rollback -RollbackArg 20260719_070926    # Restore by TIMESTAMP
    .\setup.ps1 -Rollback -RollbackArg 1.76.0             # Restore by VERSION
    .\setup.ps1 -Rollback -RollbackTarget latest -Yes     # No confirmation
    .\setup.ps1 -Rollback -RollbackTarget latest -DryRun  # Dry-run preview
    .\setup.ps1 -NoZipBackup                              # Deploy without zip

    Note: Every deploy creates BOTH a flat-file backup
          (~/.opencode-backup-TIMESTAMP/) AND a zip archive
          (~/.opencode-backup-TIMESTAMP.zip) for portability.

  MODEL RESOLUTION (v2.0):
    -Provider <name>     Non-interactive provider preset: zai|anthropic|openai|
                         openrouter|local-llm|vllm|ollama (writes ~/.config/opencode/models.json)
    -ModelsOnly          Provider selection + model resolution only (no other setup)
    -Migrate             Run v1.x -> v2.0 migration + model resolution only
    -Force               Re-resolve all agents (ignore preserved hand-edits)
    -Mix                 Per-category provider/model editor (mix providers across
                         primary/reasoning/fast/docs/vision, e.g. vision on OpenAI)

  PROVIDER PACKS (deploy-time MCP toggle):
    -EnablePack <csv>    Enable provider pack(s) — flips mcp.<server>.enabled
                         and sets permission "<ns>*": "allow". Available packs:
                         autodesk, markitdown, nextjs, docling, chrome-devtools
                         (comma-separated). No-op if omitted; default OFF.
                         Example: -EnablePack autodesk,markitdown

   SKILL PROFILE (deploy-time primary visibility):
     -SkillProfile <p>    lean (default) | full. lean rewrites the DEPLOYED
                          config's skill permissions (permissions array) to 46
                          primary-visible skills
                          + "*": "deny" (subagents unaffected — they self-scope
                          via frontmatter allows); full deploys the shipped
                          107-allow allowlist verbatim.

 ======================================================================
                     COMMON COMBINATION EXAMPLES
 ======================================================================

   Model resolution + profile:
     .\setup.ps1 -Provider anthropic -Yes      # Deploy with Anthropic models
     .\setup.ps1 -Mix                          # Mix providers per tier
     .\setup.ps1 -ModelsOnly -Force            # Re-resolve models only
     .\setup.ps1 -SkillProfile full            # Primary sees all shipped skills

   Headless / CI combos:
     .\setup.ps1 -Yes -Quick -Provider zai                  # Quick deploy, no prompts
     .\setup.ps1 -Yes -EnablePack markitdown,nextjs         # Defaults + packs
     .\setup.ps1 -Yes -Provider openai -EnablePack markitdown -SkillProfile lean
     .\setup.ps1 -DryRun -Yes -EnablePack autodesk          # Preview a combo


=======================================================================
                         CONFIGURED FEATURES
=======================================================================

    AGENTS ($(Get-AgentCount (Join-Path $RepoDir 'agents'))):
    build (default)      Full-featured coding agent with all tools
    plan                 Planning agent (read-only, edits need approval)
    explore              Fast codebase exploration and analysis
    general              General-purpose multi-step research
    scout                External docs and dependency research
    explorer             Codebase exploration and analysis (subagent)
    code-review          Code review with SOLID/clean-code analysis
    language-reviewer    Multi-language code review (Python, TS/JS, Go, Rust, Java)
    testing              Test generation with framework detection
    pr-workflow          PR creation with quality gates and JIRA integration
    linting              Code linting with auto-fix for Python/JS/TS
    repo-ops-specialist  Git repository operations (release, branch protection, labels)
    architecture-review  Architecture review with clean architecture principles
    tdd                  Test Driven Development workflow guidance
    coverage             Test coverage reporting and badges
    documentation        Docstring generation (PEP 257, JSDoc, Javadoc)
    loop-operator        Autonomous loop execution with self-correction
    pptx-specialist      PowerPoint orchestration (routes to generate-slide/template-modifier)
    docx-creation        Word document creation and manipulation
    xlsx-specialist      Spreadsheet creation and analysis
    image-analyzer       Images/screenshots to code, OCR, error diagnosis
    error-resolver       Error diagnosis with stack trace analysis
    opencode-tooling     OpenCode config creation and maintenance
    startup-founder      Startup founder business operations agent
    startup-ceo          Investor-ready pitch decks and board updates
    office-document      Office document specialist: Word, PowerPoint, Excel
     nextjs-specialist  Next.js scaffolding + runtime MCP diagnosis
    opentofu-explorer    OpenTofu/Terraform infrastructure management
    cad-specialist       CAD, robotics, hardware design orchestration
    discovery-specialist Customer-facing discovery: Vision docs + wireframes
    requirements-specialist  BRD + SRS drafting (BABOK/IIBA + IEEE 830)
    technical-design-specialist  Technical design + ADRs (engineering 'how' stage)

    Usage: opencode --agent build 'implement auth feature'
            opencode --agent explore 'find all API routes'
 
            SKILLS ($(Get-SkillCount (Join-Path $RepoDir 'skills'))):

$(Get-SkillCategories (Join-Path $RepoDir 'skills'))

    Run 'opencode --list-skills' for detailed descriptions
    Run 'opencode --skill <name> \"prompt\"' to invoke a skill

=======================================================================
                            REQUIREMENTS
=======================================================================

  Required:
    PowerShell 5.1+       Ships with Windows 10/11
    Node.js v20+          For opencode-ai and MCP servers

  Recommended:
    nvm-windows            Node version manager (https://github.com/coreybutler/nvm-windows/releases)
    git                   For version control

  API Keys (prompted during setup):
    ZAI_API_KEY           Required for web-reader, web-search
                          Get from: https://z.ai

  GitHub Auth:
    GitHub CLI (gh)      Recommended for GitHub MCP features
                         Install: https://cli.github.com/
                         Or use OAuth: opencode mcp auth github

=======================================================================

For more information: https://opencode.ai
Report issues: https://github.com/anomalyco/opencode/issues

"@
}

################################################################################
# DEPENDENCY CHECKS
################################################################################

function Test-Dependencies {
    Write-LogInfo "Checking basic dependencies..."

    $missing = @()

    if (-not (Test-CommandExists "curl.exe")) {
        if (-not (Test-CommandExists "curl")) {
            $missing += "curl"
        }
    }

    if (-not (Test-CommandExists "git")) {
        Write-LogWarn "git is not installed (recommended but not required)"
    }

    if (-not (Test-CommandExists "rg")) {
        Write-LogWarn "rg (ripgrep) is not installed (recommended but not required)"
        Write-LogWarn "  Install with: winget install BurntSushi.ripgrep.MSVC | scoop install ripgrep | choco install ripgrep"
    }

    if ($missing.Count -gt 0) {
        Write-LogError "Missing required dependencies: $($missing -join ', ')"
        Write-LogInfo "Please install missing dependencies and try again"
        return $false
    }

    Write-LogSuccess "All required dependencies are installed"
    return $true
}

function Test-Network {
    Write-LogInfo "Checking network connectivity..."

    $urls = @("https://api.github.com", "https://registry.npmjs.org")
    $ok = $true

    foreach ($url in $urls) {
        try {
            $null = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing
            Write-LogDebug "Connected to: $url"
        } catch {
            Write-LogWarn "Cannot reach: $url"
            $ok = $false
        }
    }

    if (-not $ok) {
        Write-LogError "Network connectivity issues detected"
        return $false
    }

    Write-LogSuccess "Network connectivity OK"
    return $true
}

################################################################################
# SETUP: GitHub CLI
################################################################################

function Set-GitHubCLI {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              GitHub CLI Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    if (Test-CommandExists "gh") {
        $ghAuthResult = $null
        try {
            $ghAuthResult = & gh auth status 2>&1
            if ($LASTEXITCODE -eq 0) {
                $ghUser = (& gh api user --jq '.login' 2>$null)
                if ([string]::IsNullOrWhiteSpace($ghUser)) { $ghUser = "unknown" }
                Write-LogSuccess "GitHub CLI is installed and authenticated as: $ghUser"
                Write-LogInfo "Run 'opencode mcp auth github' to configure GitHub MCP authentication"
                return
            }
        } catch {}

        Write-LogWarn "GitHub CLI is installed but not authenticated."
        Write-Host ""
        Write-Host "  To authenticate, run:" -ForegroundColor Yellow
        Write-Host "    gh auth login" -ForegroundColor White
        Write-Host ""
        Write-Host "  Then re-run this setup or run: opencode mcp auth github"
    } else {
        Write-LogWarn "GitHub CLI (gh) is not installed."
        Write-Host ""
        Write-Host "  Install GitHub CLI:" -ForegroundColor Yellow
        Write-Host "    winget install GitHub.cli"
        Write-Host "    -- or --"
        Write-Host "    choco install gh"
        Write-Host ""
        Write-Host "  After installing, run: gh auth login"
        Write-Host "  Then re-run this setup or run: opencode mcp auth github"
    }
}

################################################################################
# SETUP: Z.AI API Key
################################################################################

function Set-ZaiApiKey {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "                  Z.AI API Key Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "This setup requires a Z.AI API Key for MCP services."
    Write-Host ""

    $keyFromRegistry = $null
    try {
        $keyFromRegistry = (Get-ItemPropertyValue -Path "HKCU:\Environment" -Name "ZAI_API_KEY" -ErrorAction SilentlyContinue)
    } catch {}

    if ($keyFromRegistry -and [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        $ZaiApiKey = $keyFromRegistry
    }

    if (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        Write-Host "ZAI_API_KEY is already set in your environment."
        Write-Host "Current key (masked): $(Get-MaskedValue $ZaiApiKey)"
        Write-Host ""

        if (Read-YesNo "Use existing key?" $true) {
            Write-LogInfo "Using existing ZAI_API_KEY"
            return
        }
    }

    Write-Host "Please enter your Z.AI API Key:"
    $secureInput = Read-Host -AsSecureString
    $ZaiApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
    )
    Write-Host ""

    if (-not (Test-ApiKey -Key $ZaiApiKey -KeyName "ZAI_API_KEY")) {
        Write-LogError "No valid ZAI_API_KEY provided"

        if (-not (Read-YesNo "Continue without API key? Some MCP services will not work." $false)) {
            Write-LogError "Setup cancelled. Please run this script again with your API key."
            exit 1
        }
    } else {
        Write-LogSuccess "API Key accepted: $(Get-MaskedValue $ZaiApiKey)"
    }
}

################################################################################
# SETUP: PeonPing
################################################################################

function Set-PeonPing {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              PeonPing Sound Notifications Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "PeonPing plays game character voice lines when your AI agent"
    Write-Host "finishes work or needs permission. Works with Claude Code and OpenCode!"
    Write-Host ""
    Write-Host "Features:"
    Write-Host "  - Voice notifications from Warcraft, StarCraft, Portal, and more"
    Write-Host "  - Desktop notifications when agent needs attention"
    Write-Host "  - 160+ sound packs available"
    Write-Host "  - OpenCode TypeScript plugin for native integration"
    Write-Host ""

    if (-not (Read-YesNo "Install PeonPing?" $true)) {
        Write-LogInfo "Skipping PeonPing installation"
        return
    }

    $peonInstallDir = Join-Path $env:USERPROFILE ".claude\hooks\peon-ping"
    if ((Test-Path (Join-Path $peonInstallDir "peon.ps1")) -or (Test-CommandExists "peon")) {
        Write-LogInfo "PeonPing is already installed"
        if (-not (Read-YesNo "Reinstall/update PeonPing?" $false)) {
            Write-LogInfo "Keeping existing PeonPing installation"
            Write-Host ""
            if (Read-YesNo "Install/update PeonPing OpenCode plugin?" $true) {
                Set-PeonPingPlugin
            }
            return
        }
    }

    Write-LogInfo "Installing PeonPing via native Windows installer..."
    Write-Host ""

    try {
        $installerUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.ps1"

        if (-not $DryRun) {
            Write-Host "  Downloading and running Windows installer..." -ForegroundColor Cyan
            Write-Host "  Source: $installerUrl"
            Write-Host ""

            $installerTemp = Join-Path $env:TEMP "peon-ping-install.ps1"
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerTemp -UseBasicParsing
            Unblock-File -Path $installerTemp -ErrorAction SilentlyContinue

            $peonArgs = @("-NoProfile", "-File", $installerTemp)

            $policy = Get-ExecutionPolicy -Scope CurrentUser
            if ($policy -eq "Restricted") {
                Write-Host "  Note: Execution policy is Restricted, using Bypass for installer" -ForegroundColor Yellow
                $peonArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $installerTemp)
            }

            & powershell.exe @peonArgs
            $installExitCode = $LASTEXITCODE

            Remove-Item $installerTemp -Force -ErrorAction SilentlyContinue

            # Treat 0 and 3010 (ERROR_SUCCESS_REBOOT_REQUIRED) as success.
            # Everything else is a real failure worth warning about.
            if ($installExitCode -ne 0 -and $installExitCode -ne 3010) {
                Write-LogWarn "PeonPing installer exited with code: $installExitCode"
            }
        } else {
            Write-Host "[DRY-RUN] Would download and run: $installerUrl" -ForegroundColor Cyan
            Write-Host "[DRY-RUN] Would then install OpenCode TypeScript plugin" -ForegroundColor Cyan
        }

        if ((Test-Path (Join-Path $peonInstallDir "peon.ps1")) -or (Test-CommandExists "peon")) {
            Write-LogSuccess "PeonPing installed successfully"

            Write-Host ""
            Write-Host "Quick commands:"
            Write-Host "  peon status          - Check if active"
            Write-Host "  peon preview         - Play test sounds"
            Write-Host "  peon packs list      - List installed packs"
            Write-Host "  peon packs install <name>   - Install a pack"
            Write-Host "  peon volume 0.5      - Set volume (0.0-1.0)"
            Write-Host "  peon toggle          - Mute/unmute sounds"
            Write-Host ""

            if (Read-YesNo "Install PeonPing OpenCode plugin?" $true) {
                Set-PeonPingPlugin
            }
        } else {
            Write-LogWarn "PeonPing installation may not have completed correctly"
            Write-Host ""
            Write-Host "Try installing manually:" -ForegroundColor Yellow
            Write-Host "  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.ps1' -UseBasicParsing | Invoke-Expression" -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        Write-LogError "PeonPing installation failed: $($_.Exception.Message)"
        Write-LogInfo "Install manually: https://github.com/PeonPing/peon-ping"
    }
}

function Set-PeonPingPlugin {
    Write-Host ""
    Write-LogInfo "Configuring PeonPing for OpenCode..."

    $pluginsDir = Join-Path $ConfigDir "plugins"
    $peonPlugin = Join-Path $pluginsDir "peon-ping.ts"
    $peonConfigDir = Join-Path $ConfigDir "peon-ping"
    $peonConfigFile = Join-Path $peonConfigDir "config.json"

    # Check if plugin already installed
    if ((Test-Path $peonPlugin) -and (Test-Path $peonConfigFile)) {
        Write-LogInfo "PeonPing plugin already installed at $peonPlugin"
        if (-not (Read-YesNo "Reinstall PeonPing plugin?" $false)) {
            Write-LogInfo "Keeping existing PeonPing plugin"
            return
        }
    }

    $peonAdapter = $null

    # Find the PeonPing adapter script (installer)
    $possiblePaths = @(
        (Join-Path $env:USERPROFILE ".claude\hooks\peon-ping\adapters\opencode.sh"),
        "C:\Program Files\peon-ping\libexec\adapters\opencode.sh",
        (Join-Path ${env:ProgramFiles} "peon-ping\libexec\adapters\opencode.sh"),
        (Join-Path ${env:LOCALAPPDATA} "Programs\peon-ping\libexec\adapters\opencode.sh")
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $peonAdapter = $path
            break
        }
    }

    if ($peonAdapter) {
        Write-LogInfo "Found adapter: $peonAdapter"
        Write-LogInfo "Running PeonPing OpenCode adapter installer..."
        
        if (-not $DryRun) {
            # Run bash adapter in Git Bash if available, otherwise download TS directly
            if (Test-CommandExists "bash") {
                & bash $peonAdapter
            } else {
                Write-LogInfo "Git Bash not found, downloading TypeScript plugin directly..."
                $downloadSuccess = $false
                
                # Try primary URL
                $pluginUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode/peon-ping.ts"
                try {
                    if (-not (Test-Path $pluginsDir)) {
                        New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
                    }
                    Invoke-WebRequest -Uri $pluginUrl -OutFile $peonPlugin -UseBasicParsing
                    Unblock-File -Path $peonPlugin -ErrorAction SilentlyContinue
                    Write-LogSuccess "Plugin downloaded to: $peonPlugin"
                    $downloadSuccess = $true
                } catch {
                    Write-LogWarn "Primary download failed: $($_.Exception.Message)"
                }
                
                # Fallback URL
                if (-not $downloadSuccess) {
                    $fallbackUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/plugins/opencode/peon-ping.ts"
                    try {
                        Invoke-WebRequest -Uri $fallbackUrl -OutFile $peonPlugin -UseBasicParsing
                        Unblock-File -Path $peonPlugin -ErrorAction SilentlyContinue
                        Write-LogSuccess "Plugin downloaded from fallback URL"
                        $downloadSuccess = $true
                    } catch {
                        Write-LogError "Fallback download also failed"
                    }
                }
                
                if (-not $downloadSuccess) {
                    Write-LogError "Failed to download PeonPing plugin"
                    return
                }
            }
        } else {
            Write-Host "[DRY-RUN] Would run adapter or download plugin" -ForegroundColor Cyan
        }
    } else {
        Write-LogWarn "PeonPing adapter script not found"
        Write-LogInfo "Downloading TypeScript plugin directly..."

        $pluginUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode/peon-ping.ts"

        if ($DryRun) {
            Write-Host "[DRY-RUN] Would download peon-ping.ts to: $peonPlugin" -ForegroundColor Cyan
            Write-Host "[DRY-RUN] Would create config at: $peonConfigFile" -ForegroundColor Cyan
            return
        }

        try {
            if (-not (Test-Path $pluginsDir)) {
                New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
            }

            Write-LogInfo "Downloading peon-ping.ts OpenCode plugin..."
            Invoke-WebRequest -Uri $pluginUrl -OutFile $peonPlugin -UseBasicParsing
            Unblock-File -Path $peonPlugin -ErrorAction SilentlyContinue
            Write-LogSuccess "Plugin downloaded to: $peonPlugin"
        } catch {
            Write-LogError "PeonPing plugin download failed: $($_.Exception.Message)"
            Write-Host ""
            Write-Host "Try installing manually:" -ForegroundColor Yellow
            Write-Host "  1. Download: https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode/peon-ping.ts" -ForegroundColor Yellow
            Write-Host "  2. Save to: $peonPlugin" -ForegroundColor Yellow
            Write-Host ""
            return
        }
    }

    # Create config if it doesn't exist
    if (-not (Test-Path $peonConfigDir)) {
        New-Item -ItemType Directory -Path $peonConfigDir -Force | Out-Null
    }

    if (-not (Test-Path $peonConfigFile)) {
        $peonConfig = @{
            default_pack = "peon"
            volume = 0.5
            enabled = $true
            categories = @{
                "session.start" = $true
                "session.end" = $true
                "task.acknowledge" = $true
                "task.complete" = $true
                "task.error" = $true
                "task.progress" = $true
                "input.required" = $true
                "resource.limit" = $true
                "user.spam" = $true
            }
            spam_threshold = 3
            spam_window_seconds = 10
            pack_rotation = @()
            debounce_ms = 500
        }
        $prevCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
            $peonConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $peonConfigFile -Encoding UTF8
        } finally {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $prevCulture
        }
        Write-LogSuccess "Config created at: $peonConfigFile"
    } else {
        Write-LogInfo "Config already exists, preserved."
    }

    Write-LogSuccess "PeonPing OpenCode plugin installed successfully"
    Write-Host ""
    Write-Host "Plugin installed to:"
    Write-Host "  - Plugin: $peonPlugin"
    Write-Host "  - Config: $peonConfigFile"
    Write-Host "  - Packs:  $env:USERPROFILE\.openpeon\packs\"
    Write-Host ""
    Write-Host "Restart OpenCode to activate the plugin."
    Write-Host ""
}

################################################################################
# SETUP: Node.js
################################################################################

function Set-NodeJS {
    Write-Host ""
    Write-Host "=== Installing/Updating Node.js ===" -ForegroundColor White

    if (Test-CommandExists "node") {
        $nodeVersion = & node --version 2>$null
        Write-LogInfo "Node.js is already installed ($nodeVersion)"

        if (Read-YesNo "Install a newer version of Node.js?" $false) {
            Install-NodeJS
        }
    } else {
        Write-LogInfo "Node.js is not installed"
        Install-NodeJS
    }
}

function Install-NodeJS {
    Write-Host ""
    Write-Host "Node.js installation options:" -ForegroundColor Yellow
    Write-Host ""

    if (Test-CommandExists "nvm") {
        Write-LogInfo "nvm-windows is installed"
        Write-LogInfo "Installing Node.js v24 via nvm..."
        Invoke-WithDryRun "nvm install 24"
        Invoke-WithDryRun "nvm use 24"

        if (Test-CommandExists "node") {
            $nv = & node --version 2>$null
            Write-LogSuccess "Node.js $nv is now active"
        }
        return
    }

    Write-LogWarn "nvm-windows is not installed"
    Write-Host ""

    if (Test-CommandExists "winget") {
        Write-Host "  1. winget install OpenJS.NodeJS.LTS (recommended)"
    }
    if (Test-CommandExists "choco") {
        Write-Host "  2. choco install nodejs"
    }
    Write-Host "  3. Download from: https://nodejs.org/"
    Write-Host "  4. Install nvm-windows: https://github.com/coreybutler/nvm-windows/releases"
    Write-Host ""

    if (Test-CommandExists "winget") {
        if (Read-YesNo "Install Node.js via winget?" $true) {
            Write-LogInfo "Installing Node.js via winget..."
            Invoke-WithDryRun "winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements"
            Write-LogSuccess "Node.js installed via winget. Open a new terminal to use it."
            return
        }
    }

    if (Test-CommandExists "choco") {
        if (Read-YesNo "Install Node.js via chocolatey?" $true) {
            Write-LogInfo "Installing Node.js via chocolatey..."
            Invoke-WithDryRun "choco install nodejs -y"
            Write-LogSuccess "Node.js installed via chocolatey. Open a new terminal to use it."
            return
        }
    }

    Write-LogInfo "Please install Node.js manually from https://nodejs.org/"
    Write-LogInfo "Or install nvm-windows from https://github.com/coreybutler/nvm-windows/releases"
    Write-LogInfo "After installing, open a new terminal and run this script again"
}

################################################################################
# SETUP: OpenCode CLI
################################################################################

function Set-OpenCode {
    Write-Host ""
    Write-Host "=== Installing/Updating OpenCode ===" -ForegroundColor White

    if (-not (Test-CommandExists "npm")) {
        Write-LogError "npm is not available. Cannot install opencode-ai."
        Write-LogInfo "Please install Node.js first via nvm-windows: https://github.com/coreybutler/nvm-windows/releases"
        return
    }

    if (Test-CommandExists "opencode") {
        $currentVersion = & opencode --version 2>$null
        if ([string]::IsNullOrWhiteSpace($currentVersion)) { $currentVersion = "unknown" }

        Write-LogInfo "opencode-ai is already installed (v$currentVersion)"

        $latestVersion = Get-OpenCodeVersion -Latest

        Write-LogInfo "Latest version: v$latestVersion"

        if ($currentVersion -ne $latestVersion -and $latestVersion -ne "unknown") {
            Write-Host ""
            Write-LogWarn "An update is available for opencode-ai!"

            if (Read-YesNo "Would you like to update to the latest version?" $true) {
                Write-LogInfo "Updating opencode-ai..."
                if (Invoke-WithDryRun "npm install -g opencode-ai@latest") {
                    $newVersion = & opencode --version 2>$null
                    Write-LogSuccess "opencode-ai updated successfully to $newVersion"
                } else {
                    Write-LogError "opencode-ai update failed"
                }
            }
        } else {
            Write-LogSuccess "opencode-ai is already up to date"

            if (Read-YesNo "Reinstall opencode-ai anyway?" $false) {
                Write-LogInfo "Reinstalling opencode-ai..."
                Invoke-WithDryRun "npm install -g opencode-ai"
                Write-LogSuccess "opencode-ai reinstalled successfully"
            }
        }
    } else {
        Write-LogInfo "opencode-ai is not installed"

        if (Read-YesNo "Install opencode-ai now?" $true) {
            Write-LogInfo "Installing opencode-ai..."
            if (Invoke-WithDryRun "npm install -g opencode-ai") {
                Write-LogSuccess "opencode-ai installed successfully"
            } else {
                Write-LogError "opencode-ai installation failed"
            }
        } else {
            Write-LogWarn "Skipping opencode-ai installation"
        }
    }
}

################################################################################
# UPDATE: OpenCode CLI only
################################################################################

function Update-OpenCodeCLI {
    Write-Host ""
    Write-Host "=== Updating OpenCode CLI ===" -ForegroundColor White
    Write-Host ""

    if (-not (Test-CommandExists "npm")) {
        Write-LogError "npm is not available. Cannot update opencode-ai."
        return
    }

    if (-not (Test-CommandExists "opencode")) {
        Write-LogWarn "opencode-ai is not installed."

        if (Read-YesNo "Would you like to install opencode-ai now?" $true) {
            Write-LogInfo "Installing opencode-ai..."
            if (Invoke-WithDryRun "npm install -g opencode-ai") {
                Write-LogSuccess "opencode-ai installed successfully"
            }
        }
        return
    }

    $currentVersion = & opencode --version 2>$null
    if ([string]::IsNullOrWhiteSpace($currentVersion)) { $currentVersion = "unknown" }
    Write-LogInfo "Current version: v$currentVersion"

    Write-LogInfo "Checking for updates..."
    $latestVersion = Get-OpenCodeVersion -Latest

    if ($latestVersion -eq "unknown") {
        Write-LogError "Could not fetch latest version from npm registry"
        return
    }

    Write-LogInfo "Latest version: v$latestVersion"

    if ($currentVersion -eq $latestVersion) {
        Write-LogSuccess "opencode-ai is already up to date!"

        if (Read-YesNo "Force reinstall anyway?" $false) {
            Write-LogInfo "Reinstalling opencode-ai..."
            Invoke-WithDryRun "npm install -g opencode-ai@$latestVersion"
            Write-LogSuccess "opencode-ai reinstalled successfully"
        }
        return
    }

    Write-Host ""
    Write-LogInfo "Update available: v$currentVersion -> v$latestVersion"

    if (Read-YesNo "Update opencode-ai to v$latestVersion?" $true) {
        Write-LogInfo "Updating opencode-ai..."
        if (Invoke-WithDryRun "npm install -g opencode-ai@latest") {
            $newVersion = & opencode --version 2>$null
            Write-LogSuccess "opencode-ai updated successfully to v$newVersion"
        } else {
            Write-LogError "Update failed"
        }
    }
}

################################################################################
# SETUP: Configuration Deployment
################################################################################

function Park-JsoncSibling {
    # Park a coexisting opencode.jsonc (#432): no documented .json/.jsonc
    # tie-break within one directory. Guard on BOTH files so a jsonc-only
    # machine keeps its sole live config; DryRun stays preview-only. Called
    # from the config phase and after an apply-mode resolver run so every run
    # that writes opencode.json ends with exactly one live config.
    if ((Test-Path $ConfigFile) -and (Test-Path $JsoncConfigFile)) {
        if (-not $DryRun) { Move-Item $JsoncConfigFile "$JsoncConfigFile.legacy-ignored" -Force }
        Write-LogWarn "Stale opencode.jsonc found (undefined precedence vs opencode.json); renamed to opencode.jsonc.legacy-ignored"
    }
}

function Set-Configuration {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "                  Configuration Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    if (-not $DryRun) {
        if (-not (Test-Path $ConfigDir)) {
            New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        }
    }
    Write-LogInfo "Config directory: $ConfigDir"

    $agentsSrc = Join-Path $ScriptDir ".AGENTS.md"
    $agentsDest = Join-Path $ConfigDir "AGENTS.md"

    if (Test-Path $agentsSrc) {
        if (Test-Path $agentsDest) {
            $stale = $true
            if (-not $DryRun) {
                $stale = ((Get-FileHash $agentsSrc).Hash -ne (Get-FileHash $agentsDest).Hash)
            }
            if ($stale) {
                Write-LogWarn "AGENTS.md at $agentsDest is STALE - it differs from the source $agentsSrc"
                Write-LogWarn "Stale shipped instructions can cause incorrect agent behavior. Recommend overwriting."
                if (Read-YesNo "Overwrite with the current source version?" $true) {
                    New-FileBackup $agentsDest
                    if (-not $DryRun) { Copy-Item $agentsSrc $agentsDest -Force }
                    Write-LogSuccess "AGENTS.md updated successfully (renamed from .AGENTS.md)"
                } else {
                    Write-LogWarn "Kept stale AGENTS.md - shipped agent instructions may be out of date."
                }
            } else {
                Write-LogInfo "AGENTS.md already up to date at $agentsDest"
            }
        } else {
            if (-not $DryRun) { Copy-Item $agentsSrc $agentsDest -Force }
            Write-LogSuccess "AGENTS.md copied successfully (renamed from .AGENTS.md)"
        }
    } else {
        Write-LogWarn ".AGENTS.md not found in $ScriptDir"
    }

    # Migrate legacy deploy: setup.ps1 used to deploy the config as config.json,
    # which OpenCode v2 never reads (it only discovers opencode.json(c)). Adopt
    # the legacy file as the live config; if both exist, park the stale copy.
    if ((-not (Test-Path $ConfigFile)) -and (Test-Path $LegacyConfigFile)) {
        Move-Item $LegacyConfigFile $ConfigFile -Force
        Write-LogInfo "Migrated legacy config.json -> opencode.json (OpenCode v2 only reads opencode.json|opencode.jsonc)"
    } elseif ((Test-Path $ConfigFile) -and (Test-Path $LegacyConfigFile)) {
        Move-Item $LegacyConfigFile "$LegacyConfigFile.legacy-ignored" -Force
        Write-LogWarn "Stale legacy config.json renamed to config.json.legacy-ignored (ignored by OpenCode v2)"
    }

    # Park a coexisting opencode.jsonc (#432) — both-exist + DryRun-safe helper.
    Park-JsoncSibling

    if (Test-Path $ConfigFile) {
        Write-Host ""
        Write-LogWarn "opencode.json already exists at $ConfigFile"

        if (-not (Read-YesNo "Do you want to overwrite it?" $false)) {
            Write-LogInfo "Skipping config copy. Existing configuration preserved."
            $script:SkipConfigCopy = $true
            Deploy-Skills
            return
        }

        New-FileBackup $ConfigFile
    } else {
        $msg = "Copy opencode.json to $($ConfigDir)?"
        if (-not (Read-YesNo $msg $true)) {
            Write-LogInfo "Skipping config copy"
            $script:SkipConfigCopy = $true
            Deploy-Skills
            return
        }
    }

    if (-not $script:SkipConfigCopy) {
        # Copy the config from the single source of truth (opencode_app/opencode.json).
        # Historically this copied deploy/config.json, but maintaining a duplicate
        # caused drift (see PLAN-BT-74 Phase 12.2). The resolver (run later in
        # Deploy-Agents) patches this file in-place for explore/general models (and
        # primary only if a provider/mix was chosen — local deploys ship no
        # baked-in primary; the end user picks at runtime).
        $configSrc = $SourceConfig
        if (Test-Path $configSrc) {
            if (-not $DryRun) { Copy-Item $configSrc $ConfigFile -Force }
            Write-LogSuccess "opencode.json copied successfully (from $SourceConfig)"

            # Copied config may now coexist with a jsonc (accepted copy on a
            # jsonc-only machine): restore the one-live-config end state.
            Park-JsoncSibling

            # Deploy vibeguard secret-masking config (PLAN-GIT-315).
            $vgSrc = Join-Path $RepoDir "plugins/vibeguard.config.json"
            if (Test-Path $vgSrc) {
                $vgDest = Join-Path $ConfigDir "vibeguard.config.json"
                if (-not $DryRun) { Copy-Item $vgSrc $vgDest -Force }
                Write-LogSuccess "vibeguard.config.json deployed (secret masking active)"
                $script:vgDeployed = $true
            }
            # Install local Python MCP launchers (PLAN-GIT-262: markitdown-local-mcp).
            # Best-effort — non-fatal on offline/pip-missing.
            Install-LocalMcpLaunchers

            # Install docling-mcp if --enable-pack docling was requested (PLAN-GIT-308).
            # Heavy (~3-4 GB) — only runs when explicitly opted in.
            Install-Docling

            Write-Host ""
             Write-Host "Configured $(Get-AgentCount (Join-Path $RepoDir 'agents')) agents:" -ForegroundColor Green
            Write-Host "    - build (default) - Full-featured coding agent"
            Write-Host "    - plan - Planning agent (read-only)"
            Write-Host "    - explore - Codebase exploration and analysis"
            Write-Host "    - image-analyzer-subagent - Image/screenshot analysis"
            Write-Host "    - discovery-specialist-subagent - Customer-facing discovery: Vision docs + wireframes"
            Write-Host ""
            Write-Host "Configured MCP servers:" -ForegroundColor Green
            Write-Host "    - Auto-start: codegraph, web-reader, web-search"
            Write-Host "    - Opt-in per-project (.opencode/opencode.json): atlassian"
            Write-Host "    - Available but disabled (opt-in): next-devtools, markitdown, docling, chrome-devtools"
            if ($script:vgDeployed) {
                Write-Host "Secret masking: active (vibeguard)" -ForegroundColor Green
            }
            Write-Host ""
        } else {
            Write-LogError "opencode.json source not found: $SourceConfig"
        }
    }

    Deploy-Skills
}

function Deploy-Skills {
    Write-Host ""
    Write-LogInfo "Setting up skills directory..."

    # Skills deploy moved to the single install path (#379): Deploy-Content
    # (invoked from Deploy-Agents, after migration) installs skills + agents
    # via the installer CLI — manifest-tracked. Only the directory is ensured.
    if (-not $DryRun) {
        if (-not (Test-Path $SkillsDir)) {
            New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
        }
    }
    Write-LogInfo "Skills directory: $SkillsDir"

    Deploy-Agents
    Deploy-Plugins
    Setup-OpencodeInitShim
}

# ─────────────────────────────────────────────────────────────────────────────
# v2.0 MODEL RESOLUTION HELPERS
# ─────────────────────────────────────────────────────────────────────────────

# Run the model resolver: injects concrete models into deployed agent .md files
# and patches opencode.json (explore + general always; primary only if a
# provider/mix chosen — local deploys omit a baked-in primary). Sets $LASTEXITCODE.
function Invoke-Resolver {
    param([switch]$ConfigOnly)
    if (-not (Test-Path $ResolverScript)) {
        Write-LogError "Resolver not found: $ResolverScript"
        return
    }
    # #379 single install path: -ConfigOnly omits the agents args — the
    # installer CLI (Deploy-Content) owns agent-file writing.
    $resolverArgs = @(
        "--tiers", $AgentTiers,
        "--default-map", $ModelsDefaultMap,
        "--user-map", $UserModelsMap,
        "--overrides", $UserOverrides,
        "--config-src", $SourceConfig,
        "--config-dest", $ConfigFile,
        "--state", $ResolvedSidecar
    )
    if (-not $ConfigOnly) {
        $resolverArgs = @("--agents-src", $AgentsSrcDir, "--agents-dest", $AgentsDestDir) + $resolverArgs
    }
    if (Test-Path $ProjectModelsMap) { $resolverArgs += @("--project-map", $ProjectModelsMap) }
    if (Test-Path $ProjectOverrides) { $resolverArgs += @("--project-overrides", $ProjectOverrides) }
    if ($Force) { $resolverArgs += "--force" }
    if ($Provider) { $resolverArgs += @("--provider", $Provider, "--presets", $ProviderPresets) }
    # Deploy-time exposed-model guard (#281): fail-fast if a tier/source pin
    # references a model its provider doesn't serve. Guarded by file presence.
    $ProviderModelsFile = Join-Path $InstallDir "provider-models.json"
    if (Test-Path $ProviderModelsFile) { $resolverArgs += @("--provider-models", $ProviderModelsFile) }
    if ($DryRun) { $resolverArgs += "--dry-run" }
    & node $ResolverScript @resolverArgs
    # An apply-mode resolver write can create opencode.json beside a live
    # jsonc (decline-copy path, -ModelsOnly/-Migrate): park it here so every
    # run that writes the config ends with exactly one live config (#432).
    if (-not $DryRun -and $LASTEXITCODE -eq 0) {
        Park-JsoncSibling
    }
}

# Provider-pack merger (#268): deep-merges selected pack partials into the
# resolved config. Mirrors Invoke-Resolver's dry-run path handling (B1): in
# DryRun mode the resolver stages to $DryRunPreviewDir/opencode.json, so the
# merger must target that; otherwise $ConfigFile. No-op if $EnablePack is empty.
function Invoke-PackMerger {
    if (-not $EnablePack) { return }
    if (-not (Test-Path $MergePacksScript)) {
        Write-LogError "Pack merger not found: $MergePacksScript"
        return
    }
    if (-not (Test-Path $PacksDir)) {
        Write-LogError "Packs directory not found: $PacksDir"
        return
    }

    $targetConfig = $ConfigFile
    if ($DryRun) {
        $targetConfig = Join-Path $DryRunPreviewDir "opencode.json"
        if (-not (Test-Path $targetConfig)) {
            Write-LogError "Dry-run preview config not found: $targetConfig"
            Write-LogError "The resolver must run first to stage the preview. Aborting pack merge."
            return
        }
    }

    Write-LogInfo "Applying provider packs: $EnablePack"
    & node $MergePacksScript --config $targetConfig --packs-dir $PacksDir --packs $EnablePack
    $mergeRc = $LASTEXITCODE
    if ($mergeRc -ne 0) {
        Write-LogError "Provider-pack merge failed (exit $mergeRc)"
        return
    }

    # Install-on-enable: markitdown's Python launcher is pip-installed, not
    # baked into the target config — without this the enabled server fails to
    # spawn. Mirrors the sh hook in Invoke-PackMerger (setup.sh). Skipped in
    # dry-run (nothing real is deployed) and when the pack wasn't requested.
    if ((-not $DryRun) -and ($EnablePack -match '(^|,)markitdown(,|$)')) {
        Install-LocalMcpLaunchers
    }

    # Best-effort hook: must not leak pip's exit code into the caller's
    # $LASTEXITCODE -ne 0 check (mirrors setup.sh's explicit 'return 0').
    $global:LASTEXITCODE = 0
}

# Apply the skill profile (GIT-333): rewrites ONLY the skill rules
# (action:"skill") inside the permissions array of the DEPLOYED config
# (never the source opencode_app/opencode.json).
# lean (default) -> 44 primary-visible skills + "*": "deny"; full -> verified
# no-op. Mirrors Invoke-PackMerger's dry-run contract (B1).
function Invoke-SkillProfile {
    if (-not (Test-Path $ApplySkillProfileScript)) {
        Write-LogError "Skill-profile applier not found: $ApplySkillProfileScript"
        return
    }
    if (-not (Test-Path $SkillProfilesFile)) {
        Write-LogError "Skill profiles file not found: $SkillProfilesFile"
        return
    }

    $targetConfig = $ConfigFile
    if ($DryRun) {
        $targetConfig = Join-Path $DryRunPreviewDir "opencode.json"
        if (-not (Test-Path $targetConfig)) {
            Write-LogError "Dry-run preview config not found: $targetConfig"
            Write-LogError "The resolver must run first to stage the preview. Aborting skill-profile apply."
            return
        }
    }

    Write-LogInfo "Applying skill profile: $SkillProfile"
    & node $ApplySkillProfileScript --config $targetConfig --profiles $SkillProfilesFile --profile $SkillProfile
}

# Validate -EnablePack names early (fail fast). Mirrors setup.sh's
# validate_enable_pack so a bogus pack aborts before any config work.
function Test-EnablePack {
    if (-not $EnablePack) { return }
    if (-not (Test-Path $PacksDir)) {
        Write-LogError "-EnablePack: packs directory not found: $PacksDir"
        exit 1
    }
    $requested = $EnablePack.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if (-not $requested) { return }
    $unknown = @()
    foreach ($name in $requested) {
        if (-not (Test-Path (Join-Path $PacksDir "pack-$name.json"))) {
            $unknown += $name
        }
    }
    if ($unknown.Count -gt 0) {
        $available = (Get-ChildItem $PacksDir -Filter "pack-*.json" | ForEach-Object { $_.Name -replace '^pack-','' -replace '\.json$','' }) -join ', '
        Write-LogError "-EnablePack: unknown pack(s): $($unknown -join ', ')"
        Write-Host "  Available packs: $available" -ForegroundColor Yellow
        exit 1
    }
    Write-LogInfo "Provider packs requested: $($requested -join ',')"
}

# Choose a model provider (interactive TUI or -Provider flag) and write the
# global ~/.config/opencode/models.json tier map.
function Set-ModelProvider {
    Write-Host ""
    Write-Host "====================================================================="
    Write-Host "                      Model Provider (v2.0)"
    Write-Host "====================================================================="
    Write-Host ""

    if ($Provider -and -not $Mix) {
        Write-LogInfo "Provider preset: $Provider (writing $UserModelsMap)"
        & node $TuiScript provider-picker --presets $ProviderPresets --provider $Provider --out $UserModelsMap
        return
    }

    # -Mix: per-category provider/model editor (interactive). Base = $Provider or zai.
    if ($Mix) {
        $base = if ($Provider) { $Provider } else { "zai" }
        Write-LogInfo "Mix mode: choose a provider/model per category (base: $base)"
        & node $TuiScript tier-editor --presets $ProviderPresets --provider $base --out $UserModelsMap
        if ($LASTEXITCODE -ne 0) { Write-LogWarn "Mix editor cancelled (using default models)" }
        return
    }

    if (-not $Yes) {
        Write-Host "  1) Single provider (recommended)"
        Write-Host "  2) Mix providers per category (e.g. vision on OpenAI, rest on Z.AI)"
        $providerChoice = Read-Prompt "Select option" "1"
        switch ($providerChoice) {
            "2" {
                $base = if ($Provider) { $Provider } else { "zai" }
                & node $TuiScript tier-editor --presets $ProviderPresets --provider $base --out $UserModelsMap
                if ($LASTEXITCODE -ne 0) { Write-LogWarn "Mix editor cancelled (using default models)" }
            }
            default {
                if (Read-YesNo "Choose a model provider? (default: Z.AI)" $false) {
                    & node $TuiScript provider-picker --presets $ProviderPresets --out $UserModelsMap
                    if ($LASTEXITCODE -ne 0) { Write-LogWarn "Provider selection skipped (using default models)" }
                } else {
                    Write-LogInfo "Using default Z.AI models"
                }
            }
        }
    } else {
        Write-LogInfo "Non-interactive: using default models (use -Provider <name> or -Mix to choose)"
    }
}

# Detect a pre-v2 install and run the one-time migration: backup, lift
# customizations, mark the config version. Idempotent.
function Invoke-Migration {
    $currentVersion = "0"
    if (Test-Path $ConfigVersionFile) { $currentVersion = (Get-Content $ConfigVersionFile -Raw).Trim() }

    $skip = $false
    try {
        $cv = [version]$currentVersion
        $sv = [version]$SchemaVersion
        if ($cv -ge $sv) { $skip = $true }
    } catch {
        # unparseable current version -> migrate
    }
    if ($skip) {
        Write-LogDebug "Config already at v$SchemaVersion, no migration needed"
        return
    }

    Write-Host ""
    Write-LogWarn "v2.0 major upgrade detected (current config: v$currentVersion)"
    Write-LogWarn "Agent models are now resolved from tiers (see MIGRATION.md). Existing"
    Write-LogWarn "agents will be backed up and re-resolved. Custom models are preserved."

    if (-not $Yes) {
        if (-not (Read-YesNo "Run migration now?" $true)) {
            Write-LogWarn "Migration skipped. Agents re-resolved from tiers (custom models NOT lifted)."
            return
        }
    }

    # Backup existing agents + config (skip actual copy in dry-run)
    if ($DryRun) {
        if ((Test-Path $AgentsDestDir) -and @(Get-ChildItem $AgentsDestDir -Filter "*.md" -ErrorAction SilentlyContinue).Count -gt 0) {
            Write-LogInfo "[DRY-RUN] Would back up agents -> $BackupDir/agents-backup"
        }
        if (Test-Path $ConfigFile) { Write-LogInfo "[DRY-RUN] Would back up opencode.json" }
    } else {
        if ((Test-Path $AgentsDestDir) -and @(Get-ChildItem $AgentsDestDir -Filter "*.md" -ErrorAction SilentlyContinue).Count -gt 0) {
            if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
            $agentsBackup = Join-Path $BackupDir "agents-backup"
            if (-not (Test-Path $agentsBackup)) {
                Copy-Item $AgentsDestDir $agentsBackup -Recurse -Force
                Write-LogInfo "Backed up agents to $agentsBackup"
            }
        }
        if (Test-Path $ConfigFile) { New-FileBackup $ConfigFile }
    }

    # Lift customizations into agent-overrides.json BEFORE re-resolve
    if (-not $DryRun) {
        & node $ResolverScript --lift-only --agents-dest $AgentsDestDir --default-map $ModelsDefaultMap --overrides $UserOverrides
    }

    if ($DryRun) {
        Write-LogSuccess "[DRY-RUN] Would mark config as v$SchemaVersion"
    } else {
        Set-Content -Path $ConfigVersionFile -Value $SchemaVersion -NoNewline
        Write-LogSuccess "Migration to v$SchemaVersion complete"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# LOCAL MCP LAUNCHER INSTALL (PLAN-GIT-262)
# ─────────────────────────────────────────────────────────────────────────────

# Install in-repo Python-based MCP launchers (currently: markitdown-local-mcp)
# onto the user's PATH so OpenCode can spawn them via the `command` field in
# opencode.json. Uses pip (already a soft dep). Mirrors install_local_mcp_launchers()
# in setup.sh.
function Install-LocalMcpLaunchers {
    $launcherDir = Join-Path $AppDir "mcp-servers\markitdown-local-mcp"

    # Idempotency: skip the network round-trip when already installed AND
    # importable — `pip show` alone hides broken installs (missing mcp SDK
    # dep), which surfaces later as "MCP error -32000: Connection closed".
    # (Mirrors setup.sh install_local_mcp_launchers.) Single python probe —
    # reused for the install below.
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) { $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue }
    if ($pythonCmd) {
        & $pythonCmd.Name -m pip show markitdown-local-mcp *> $null
        $pipOk = $LASTEXITCODE -eq 0
        & $pythonCmd.Name -c "from markitdown_local_mcp.__main__ import main" *> $null
        $importOk = $LASTEXITCODE -eq 0
        if ($pipOk -and $importOk) {
            Write-LogSuccess "markitdown-local-mcp already installed - skipping pip install"
            $global:LASTEXITCODE = 0
            return
        }
    }

    if (-not (Test-Path $launcherDir)) {
        Write-LogWarn "markitdown-local-mcp launcher source not found at $launcherDir - skipping"
        $global:LASTEXITCODE = 0
        return
    }

    # Prerequisite: python + pip (probed above)
    if (-not $pythonCmd) {
        Write-LogWarn "python not found - cannot install markitdown-local-mcp. Install Python 3.10+ and re-run."
        $global:LASTEXITCODE = 0
        return
    }
    $python = if ($pythonCmd.Name -eq 'python') { 'python' } else { 'python3' }

    # Install (network required; non-fatal if offline). PEP 668
    # (externally-managed-environment, Debian 12+/Ubuntu 23.04+) blocks plain
    # `pip install --user` - retry once with --break-system-packages (--user
    # keeps the install isolated to ~/.local, which is the risk PEP 668 guards).
    Write-LogInfo "$python -m pip install --user --force-reinstall $launcherDir"
    $pipOut = & $python -m pip install --user --force-reinstall --no-warn-script-location $launcherDir 2>&1
    $pipRetry = $null
    if ($LASTEXITCODE -ne 0 -and (($pipOut | Out-String) -match 'externally-managed-environment')) {
        Write-LogInfo "PEP 668 externally-managed environment detected - retrying with --break-system-packages"
        $pipRetry = & $python -m pip install --user --break-system-packages --force-reinstall --no-warn-script-location $launcherDir 2>&1
    }
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "markitdown-local-mcp installed"
        # Windows console-script lands in %APPDATA%\Python\Scripts - warn if not on PATH
        $userScripts = Join-Path $env:APPDATA "Python\Scripts"
        if (-not ($env:PATH -like "*$userScripts*")) {
            Write-LogWarn "$userScripts is not on your PATH. Add it to use markitdown-local-mcp:"
            Write-Host "    setx PATH `"$userScripts;%PATH%`"" -ForegroundColor Yellow
        }
    } else {
        Write-LogWarn "pip install failed for markitdown-local-mcp (offline?). The launcher is opt-in (enabled: false) - OpenCode will work without it. Re-run setup when online to enable."
        if ($null -eq $pipRetry) { $pipRetry = $pipOut }
        Write-LogWarn "pip output (last 3 lines):"
        ($pipRetry | Out-String).Trim() -split "`r?`n" | Select-Object -Last 3 | ForEach-Object { Write-LogWarn "  pip: $_" }
    }

    # Best-effort installer: never leak a pip exit code to callers.
    $global:LASTEXITCODE = 0
}

# Install docling-mcp (heavy ~3-4 GB) — only when --enable-pack docling is
# requested. Unlike markitdown (local-dir pip install), docling-mcp comes from
# PyPI. First convert downloads ~hundreds of MB of models from huggingface.co.
# Mirrors install_docling() in setup.sh.
function Install-Docling {
    if (-not ($EnablePack -match '(^|,)docling(,|$)')) {
        return
    }

    Write-Host ""
    Write-LogInfo "Installing docling-mcp[local] (~3-4 GB with models)..."

    # Prerequisite: python + pip
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) { $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue }
    if (-not $pythonCmd) {
        Write-LogWarn "python not found - cannot install docling-mcp. Install Python 3.10+ and re-run."
        return
    }
    $python = if ($pythonCmd.Name -eq 'python') { 'python' } else { 'python3' }

    # PEP 668 (externally-managed-environment, Debian 12+/Ubuntu 23.04+) blocks
    # plain `pip install --user` - retry once with --break-system-packages
    # (--user keeps the install isolated to ~/.local).
    Write-LogInfo "$python -m pip install --user docling-mcp[local]"
    $pipOut = & $python -m pip install --user --no-warn-script-location "docling-mcp[local]" 2>&1
    if ($LASTEXITCODE -ne 0 -and (($pipOut | Out-String) -match 'externally-managed-environment')) {
        Write-LogInfo "PEP 668 externally-managed environment detected - retrying with --break-system-packages"
        & $python -m pip install --user --break-system-packages --no-warn-script-location "docling-mcp[local]" 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "docling-mcp installed"
        Write-LogInfo "NOTE: first 'docling convert' will download ~hundreds of MB of models from huggingface.co (cached thereafter)."
    } else {
        Write-LogWarn "pip install failed for docling-mcp (offline, OOM, or PEP 668?). The pack is opt-in - OpenCode will work without it. Re-run setup when online to enable."
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PLUGIN DEPLOYMENT
# ─────────────────────────────────────────────────────────────────────────────

# Copy repo-owned plugins (plugins/*) into the global
# plugins dir so opencode auto-loads them. Mirrors the skills deploy pattern.
# These are NOT npm packages (those live in opencode.json plugins[]); they are
# local TS plugins auto-discovered from ~/.config/opencode/plugins/.

# Install the opencode-init wrapper shim (project-scoped selective installer CLI).
# Writes a opencode-init.cmd wrapper into the user bin dir that invokes node on
# <repo>\installer\init.mjs. Avoids mklink (needs Developer Mode/admin). Idempotent.
# Additive — does not change any other setup.ps1 behavior.
function Setup-OpencodeInitShim {
    $initSrc = Join-Path $RepoDir "installer\init.mjs"
    if (-not (Test-Path $initSrc)) {
        Write-LogWarn "opencode-init source not found at $initSrc; skipping shim"
        return
    }
    $userBin = Join-Path $env:APPDATA "Python\Scripts"
    if (-not (Test-Path $userBin)) { New-Item -ItemType Directory -Force -Path $userBin | Out-Null }
    $shim = Join-Path $userBin "opencode-init.cmd"
    $nodeExe = (Get-Command node -ErrorAction SilentlyContinue).Source
    if (-not $nodeExe) { $nodeExe = "node" }
    $body = "@echo off`r`n`"$nodeExe`" `"$initSrc`" %*`r`n"
    if ((Test-Path $shim) -and ((Get-Content $shim -Raw) -eq $body)) {
        Write-LogInfo "opencode-init shim already correct at $shim"
    } else {
        Set-Content -Path $shim -Value $body -Encoding ASCII
        Write-Host "[SUCCESS] opencode-init installed to $shim" -ForegroundColor Green
    }
    # PATH check
    $pathDirs = $env:PATH -split ';'
    if ($pathDirs -notcontains $userBin) {
        Write-LogWarn "$userBin is not on your PATH. Add it to use opencode-init."
    }
    Write-LogInfo "Tip: individual skills/agents can also be installed via: npx github:darellchua2/opencode-config-template add <name>"
}

function Deploy-Plugins {
    Write-Host ""
    Write-LogInfo "Setting up plugins..."

    if (-not (Test-Path $PluginsSrcDir)) {
        Write-LogInfo "No repo plugins to deploy ($PluginsSrcDir not found). Skipping."
        return
    }

    if (-not (Test-Path $PluginsDestDir)) {
        New-Item -ItemType Directory -Path $PluginsDestDir -Force | Out-Null
    }

    # #456 migration: plugins renamed with the opencode- prefix - drop stale
    # pre-rename copies so the same plugin never loads twice.
    foreach ($legacyName in @("vibeguard.ts", "ponytail-scoped.ts", "question-repair.ts", "learnings-autoinject.ts", "learnings-autoinject.README.md")) {
        $legacyPath = Join-Path $PluginsDestDir "$legacyName"
        if (Test-Path $legacyPath) {
            if ($DryRun) {
                Write-LogInfo "[DRY-RUN] Would remove $legacyPath"
            } else {
                Remove-Item $legacyPath -Force
            }
        }
    }

    # Copy each plugin file/subdirectory (skip dotfiles, _archived, node_modules).
    # Mirrors setup.sh which copies BOTH top-level .ts plugin files (e.g.
    # opencode-ponytail-scoped.ts, opencode-learnings-autoinject.ts) AND plugin subdirectories.
    $count = 0
    Get-ChildItem -Path $PluginsSrcDir -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match '^\.|_archived|^node_modules$') { return }
        Copy-Item $_.FullName $PluginsDestDir -Recurse -Force
        $count++
    }

    if ($count -gt 0) {
        $plural = if ($count -ne 1) { "s" } else { "" }
        Write-LogSuccess "Plugins copied successfully to $PluginsDestDir ($count plugin$plural)"
    } else {
        Write-LogInfo "No repo plugins found to deploy."
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# AGENT DEPLOYMENT (v2.0 — resolver-driven)
# ─────────────────────────────────────────────────────────────────────────────
# Single install path (#379): all content installs flow through the installer
# CLI so every deploy is manifest-tracked. Snapshots existing content first.
function Deploy-Content {
    Write-Host ""
    Write-LogInfo "Deploying content via installer CLI (manifest-tracked)..."

    if (-not (Test-CommandExists "node")) {
        Write-LogError "Node.js is required by the installer CLI."
        $global:LASTEXITCODE = 1
        return
    }

    # Pre-overwrite snapshot (ARCH-4): preserve user edits before force-copy.
    # Unconditional — $BackupDir may not exist yet on -Yes redeploy.
    $contentBackup = Join-Path $BackupDir "content-backup"
    if (@(Get-ChildItem $SkillsDir -ErrorAction SilentlyContinue).Count -gt 0) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $contentBackup -Force | Out-Null; Copy-Item $SkillsDir (Join-Path $contentBackup "skills") -Recurse -Force }
        Write-LogInfo "Snapshotted existing skills to content-backup/skills"
    }
    if (@(Get-ChildItem $AgentsDestDir -ErrorAction SilentlyContinue).Count -gt 0) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $contentBackup -Force | Out-Null; Copy-Item $AgentsDestDir (Join-Path $contentBackup "agents") -Recurse -Force }
        Write-LogInfo "Snapshotted existing agents to content-backup/agents"
    }

    $cliArgs = @("add", "--all", "--yes")
    if ($Provider) { $cliArgs += @("--provider", $Provider) }
    if ($DryRun) { $cliArgs += "--dry-run" }
    & node (Join-Path $InstallDir "init.mjs") @cliArgs
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "installer CLI failed (exit $LASTEXITCODE)"
        return
    }
    Write-LogSuccess "Content deployed (manifest-tracked)"
}

function Deploy-Agents {
    Write-Host ""
    Write-LogInfo "Setting up agents (v2.0 model resolution)..."

    if (-not (Test-CommandExists "node")) {
        Write-LogError "Node.js is required to resolve agent models."
        Write-LogError "Install Node.js first, then re-run this setup."
        Write-LogWarn "Skipping agent deployment."
        return
    }

    if (-not (Test-Path $AgentsSrcDir)) {
        Write-LogWarn "agents/ source folder not found: $AgentsSrcDir"
        return
    }

    if (-not $DryRun) {
        if (-not (Test-Path $AgentsDestDir)) {
            New-Item -ItemType Directory -Path $AgentsDestDir -Force | Out-Null
        }
    }

    # Migration (detect pre-v2, backup, lift customizations) before resolve
    Invoke-Migration

    # Single install path (#379): content installs via the CLI after migration
    # (lift must see pre-overwrite agents), before the config-only resolve.
    Deploy-Content
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Content deployment failed"
        return
    }

    # Resolve + inject concrete models into the CONFIG (agent files: Deploy-Content)
    Write-LogInfo "Resolving agent models..."
    Invoke-Resolver -ConfigOnly
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Model resolution failed"
        return
    }

    # Apply provider packs (-EnablePack) if requested. Runs AFTER the resolver
    # so it merges into the resolved config. Mirrors Invoke-Resolver's dry-run
    # path (B1). No-op if $EnablePack is empty.
    if ($EnablePack) {
        Invoke-PackMerger
        if ($LASTEXITCODE -ne 0) {
            Write-LogError "Provider-pack application failed"
            return
        }
    }

    # Apply skill profile (-SkillProfile lean|full, default lean). Runs LAST so
    # the rewrite lands on the final resolved+packed config. Subagents are
    # unaffected (frontmatter allows, GIT-333 Phase 1).
    Invoke-SkillProfile
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Skill-profile application failed"
        return
    }

    # Count deployed agents by mode
    $agentCount = 0; $primaryCount = 0; $subagentCount = 0
    foreach ($file in @(Get-ChildItem $AgentsDestDir -Filter "*.md" -ErrorAction SilentlyContinue)) {
        $agentCount++
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "^mode:\s*primary") { $primaryCount++ }
        elseif ($content -match "^mode:\s*subagent") { $subagentCount++ }
    }

    Write-LogSuccess "Deployed $agentCount agents ($subagentCount subagents) to $AgentsDestDir"
    Write-Host "  Models resolved via tier registry."
    Write-Host "  Change provider: ./setup.ps1 -Provider <zai|anthropic|openai|openrouter>"
    Write-Host "  Pin per-agent:   ~/.config/opencode/agent-overrides.json"
}

function Set-LearningsDir {
    Write-Host ""
    Write-LogInfo "Setting up user-level learnings directory..."

    $learningsDir = Join-Path $ConfigDir "learnings"
    $categories = @("patterns", "decisions", "anti-patterns", "solutions", "conventions")

    if (-not (Test-Path $learningsDir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null
        }
        Write-LogInfo "Created $learningsDir"
    }

    foreach ($category in $categories) {
        $categoryDir = Join-Path $learningsDir $category
        if (-not (Test-Path $categoryDir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $categoryDir -Force | Out-Null
                New-Item -ItemType File -Path (Join-Path $categoryDir ".gitkeep") -Force | Out-Null
            }
        }
    }

    $indexFile = Join-Path $learningsDir "_index.md"
    if (-not (Test-Path $indexFile)) {
        if (-not $DryRun) {
            $indexContent = @"
# LEARNINGS Index (User-Level)

<!-- AUTO-GENERATED — manual edits to the listing below will be overwritten on next learning write -->

## Folder Structure

| Folder | Purpose |
|--------|---------|
| ``patterns/`` | Reusable code/architecture patterns (cross-project) |
| ``decisions/`` | Personal architectural decisions |
| ``anti-patterns/`` | Things to avoid |
| ``solutions/`` | Non-obvious fixes worth remembering |
| ``conventions/`` | Personal coding standards |

## Entries

<!-- Entries are appended here automatically when new learnings are saved -->

<!-- No entries yet -->
"@
            Set-Content -Path $indexFile -Value $indexContent -Encoding UTF8
        }
        Write-LogInfo "Created _index.md template"
    }

    Write-LogSuccess "User-level learnings directory ready at $learningsDir"
}

################################################################################
# SETUP: Environment Variables
################################################################################

function Set-ShellVariables {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              Environment Variables Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    Write-Host "PowerShell profile: $PROFILE"
    Write-Host ""

    # Decide whether we need to write anything to the profile before creating it.
    # Previously, an empty $PROFILE was created unconditionally as a side effect,
    # which surprised users who never wanted a profile at all.
    $profileExists = Test-Path $PROFILE

    # Offer to install autoresearch protocol helpers (ar-enable / ar-disable)
    if ($profileExists) {
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    } else {
        $profileContent = ""
    }
    if ($profileContent -notmatch 'function ar-enable') {
        if (Read-YesNo "Install 'ar-enable' / 'ar-disable' helpers in your PowerShell profile?" $false) {
            if (-not $profileExists) {
                $profileDir = Split-Path $PROFILE -Parent
                if (-not (Test-Path $profileDir)) {
                    if (-not $DryRun) {
                        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
                    }
                }
                if (-not $DryRun) {
                    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
                }
                Write-LogInfo "Created PowerShell profile: $PROFILE"
                $profileExists = $true
            } else {
                New-FileBackup $PROFILE
            }
            if (-not $DryRun) {
                Add-Content -Path $PROFILE -Value @'

function ar-enable { $env:AUTORESEARCH_PROTOCOL = "1"; Write-Host "autoresearch protocol: ON" }
function ar-disable { Remove-Item Env:\AUTORESEARCH_PROTOCOL -ErrorAction SilentlyContinue; Write-Host "autoresearch protocol: OFF" }
'@
            }
            Write-LogSuccess "Added ar-enable / ar-disable helpers to $PROFILE"
        } else {
            Write-LogInfo "Skipping ar-enable / ar-disable helpers"
        }
    } else {
        Write-LogInfo "ar-enable / ar-disable helpers already exist in $PROFILE"
    }

    if (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        # Re-read profile content in case we just created it / added ar-* above
        if (Test-Path $PROFILE) {
            $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        } else {
            $profileContent = ""
        }
        if ($profileContent -match "ZAI_API_KEY") {
            Write-LogInfo "ZAI_API_KEY already exists in $PROFILE"
        } else {
            if (Read-YesNo "Add ZAI_API_KEY to your PowerShell profile for persistent access?" $true) {
                if (-not $profileExists) {
                    $profileDir = Split-Path $PROFILE -Parent
                    if (-not (Test-Path $profileDir)) {
                        if (-not $DryRun) {
                            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
                        }
                    }
                    if (-not $DryRun) {
                        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
                    }
                    Write-LogInfo "Created PowerShell profile: $PROFILE"
                    $profileExists = $true
                } else {
                    New-FileBackup $PROFILE
                }
                if (-not $DryRun) {
                    Add-Content -Path $PROFILE -Value "`n# Z.AI API Key (added by opencode setup)"
                    Add-Content -Path $PROFILE -Value "`$env:ZAI_API_KEY = `"$ZaiApiKey`""
                }
                Write-LogSuccess "ZAI_API_KEY added to $PROFILE"
            } else {
                Write-LogInfo "Skipping profile update for ZAI_API_KEY"
            }
        }
    }

    # Register the PAYG `zai` provider in opencode's native auth store
    # (~/.local/share/opencode/auth.json) so `opencode auth list` shows it and
    # the built-in `zai` provider resolves. Mirrors the Docker entrypoint + the
    # bash register_zai_auth helper. MERGES — never clobbers existing entries.
    if (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        $authDir = Join-Path $HOME ".local\share\opencode"
        $authFile = Join-Path $authDir "auth.json"
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would register zai credential in $authFile"
        } else {
            if (-not (Test-Path $authDir)) {
                New-Item -ItemType Directory -Path $authDir -Force | Out-Null
            }
            $auth = @{}
            if (Test-Path $authFile) {
                try {
                    $obj = Get-Content $authFile -Raw | ConvertFrom-Json
                    $obj.PSObject.Properties | ForEach-Object { $auth[$_.Name] = $_.Value }
                } catch {
                    $auth = @{}
                }
            }
            $auth["zai"] = [PSCustomObject]@{ type = "api"; key = $ZaiApiKey }
            ($auth | ConvertTo-Json -Depth 10) | Set-Content -Path $authFile -Encoding UTF8
            Write-Host "  auth.json providers: $(($auth.Keys) -join ', ')"
            Write-LogSuccess "Registered zai credential in $authFile (native opencode auth store)"
        }
    }
}

################################################################################
# AUTO-UPDATE FUNCTIONS
################################################################################

function Update-LastCheckTime {
    $timestamp = [int][double]::Parse((Get-Date -UFormat %s))
    if (-not $DryRun) {
        Set-Content -Path $LastUpdateCheck -Value $timestamp
    }
    Write-LogDebug "Updated last check time"
}

function Test-ShouldCheckForUpdate {
    if (-not (Test-Path $LastUpdateCheck)) {
        return $true
    }

    $lastCheck = [int](Get-Content $LastUpdateCheck -Raw -ErrorAction SilentlyContinue)
    if (-not $lastCheck) { return $true }

    $current = [int][double]::Parse((Get-Date -UFormat %s))
    $diff = $current - $lastCheck

    switch ($ScheduleUpdate) {
        "daily"   { return $diff -ge 86400 }
        "weekly"  { return $diff -ge 604800 }
        "monthly" { return $diff -ge 2592000 }
        "manual"  { return $true }
        default   { return $diff -ge 604800 }
    }
}

function Get-OpenCodeVersion {
    param([switch]$Latest)

    if ($Latest) {
        # Call npm directly — Invoke-Expression swallows non-throwing failures
        # (npm writes to stderr and returns non-zero $LASTEXITCODE), causing
        # the caller to see an empty string instead of "unknown".
        try {
            $output = & npm view opencode-ai version 2>$null
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($output)) {
                return $output.Trim()
            }
            return "unknown"
        } catch {
            return "unknown"
        }
    }

    if (Test-CommandExists "opencode") {
        $v = & opencode --version 2>$null
        if ($v) { return $v.Trim() }
    }
    return "unknown"
}

function Invoke-AutoUpdate {
    if ($DisableAutoUpdate -and -not $EnableAutoUpdate) {
        Write-LogInfo "Auto-update is disabled"
        return
    }

    if (-not (Test-ShouldCheckForUpdate)) {
        Write-LogInfo "Skipping auto-update (scheduled time not reached)"
        return
    }

    Write-LogInfo "Checking for opencode-ai updates..."

    $current = Get-OpenCodeVersion
    $latest = Get-OpenCodeVersion -Latest

    if ($latest -eq "unknown") {
        Write-LogError "Could not fetch latest version from npm registry"
        return
    }

    Write-LogInfo "Current version: v$current"
    Write-LogInfo "Latest version: v$latest"

    if ($current -eq $latest) {
        Write-LogSuccess "opencode-ai is already up to date!"
        Update-LastCheckTime
        return
    }

    Write-LogInfo "Update available: v$current -> v$latest"

    if ($Yes -or (Read-YesNo "Update opencode-ai to v$latest?" $true)) {
        $backupDir = Join-Path $HOME ".opencode-update-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            if (Test-Path $ConfigFile) { Copy-Item $ConfigFile (Join-Path $backupDir "opencode.json") }
            $agentsDest = Join-Path $ConfigDir "AGENTS.md"
            if (Test-Path $agentsDest) { Copy-Item $agentsDest (Join-Path $backupDir "AGENTS.md") }
            if (Test-Path $SkillsDir) { Copy-Item $SkillsDir (Join-Path $backupDir "skills") -Recurse }
            $vgCfgUpd = Join-Path $ConfigDir "vibeguard.config.json"
            if (Test-Path $vgCfgUpd) { Copy-Item $vgCfgUpd (Join-Path $backupDir "vibeguard.config.json") }
            Remove-OldBackups
        }

        Write-LogInfo "Auto-updating opencode-ai to v$latest..."
        Invoke-WithDryRun "npm install -g opencode-ai@$latest"

        $newVersion = Get-OpenCodeVersion
        if ($newVersion -eq $latest) {
            Write-LogSuccess "opencode-ai updated successfully to v$newVersion"
            Update-LastCheckTime
        } else {
            Write-LogError "Update failed. Current version: v$newVersion"
        }
    }
}

function Show-CheckUpdate {
    Write-LogInfo "Checking for opencode-ai updates..."

    if (-not (Test-CommandExists "opencode")) {
        Write-LogWarn "opencode-ai is not installed"
        return
    }

    $current = Get-OpenCodeVersion
    $latest = Get-OpenCodeVersion -Latest

    if ($latest -eq "unknown") {
        Write-LogError "Could not fetch latest version from npm registry"
        return
    }

    Write-LogInfo "Current version: v$current"
    Write-LogInfo "Latest version: v$latest"

    if ($current -eq $latest) {
        Write-LogSuccess "opencode-ai is already up to date!"
    } else {
        Write-LogInfo "Update available: v$current -> v$latest"
        Write-LogInfo "Run: .\setup.ps1 -EnableAutoUpdate -ScheduleUpdate daily"
    }

    Update-LastCheckTime
}

################################################################################
# SUMMARY
################################################################################

function Show-Summary {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "                      Setup Summary" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    Write-Host "Platform Detection:"
    Write-Host "  [OK] OS: Windows $($env:OS)"
    Write-Host "  [OK] PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "  [OK] Profile: $PROFILE"
    Write-Host ""

    if (Test-CommandExists "nvm") {
        Write-Host "  [OK] nvm-windows: Installed (nvm)"
    } else {
        Write-Host "  [ ] nvm-windows: Not detected (install from github.com/coreybutler/nvm-windows/releases)"
    }

    if (Test-CommandExists "node") {
        $nv = & node --version 2>$null
        Write-Host "  [OK] Node.js: $nv"
    } else {
        Write-Host "  [X] Node.js: Not installed"
    }

    if (Test-CommandExists "opencode") {
        $ov = & opencode --version 2>$null
        Write-Host "  [OK] opencode-ai: Installed v$ov"
    } else {
        Write-Host "  [X] opencode-ai: Not installed"
    }

    if (Test-Path $ConfigFile) {
        Write-Host "  [OK] opencode.json: Copied to $ConfigDir\" -ForegroundColor Green
    } else {
        Write-Host "  [X] opencode.json: Not copied"
    }

    if (Test-Path (Join-Path $ConfigDir "AGENTS.md")) {
        Write-Host "  [OK] AGENTS.md: Copied to $ConfigDir\" -ForegroundColor Green
    } else {
        Write-Host "  [X] AGENTS.md: Not copied"
    }

    $skillCount = @(Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue).Count
    if ($skillCount -gt 0) {
        Write-Host "  [OK] skills: $skillCount skills deployed to $SkillsDir\" -ForegroundColor Green
        Write-Host "  [OK] skill profile: $SkillProfile (primary-visible skills in skill permissions)" -ForegroundColor Green
    } else {
        Write-Host "  [X] skills: Not deployed"
    }

    $vgSummary = Join-Path $ConfigDir "vibeguard.config.json"
    if (Test-Path $vgSummary) {
        Write-Host "  [OK] Secret masking: active (vibeguard)" -ForegroundColor Green
    } else {
        Write-Host "  [X] Secret masking: vibeguard.config.json not deployed"
    }

    Write-Host ""

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match "ZAI_API_KEY") {
        Write-Host "  [OK] ZAI_API_KEY: Added to profile"
    } elseif (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        Write-Host "  [ ] ZAI_API_KEY: Set in current session only"
    } else {
        Write-Host "  [X] ZAI_API_KEY: Not configured"
    }

    if (Test-CommandExists "gh") {
        $ghSummaryAuth = $null
        try {
            $ghSummaryAuth = & gh auth status 2>&1
        } catch {}
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] GitHub CLI: Installed and authenticated"
        } else {
            Write-Host "  [ ] GitHub CLI: Installed but not authenticated (run: gh auth login)"
        }
    } else {
        Write-Host "  [ ] GitHub CLI: Not installed (https://cli.github.com/)"
    }

    Write-Host ""
}

function Show-NextSteps {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "                      Setup Complete!" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:"
    Write-Host "  1. Restart terminal or run: . $PROFILE"
    Write-Host "  2. Verify installation: opencode --version"
    Write-Host ""
    Write-Host "Agents ($(Get-AgentCount (Join-Path $RepoDir 'agents'))):"
    Write-Host "  - build (default) - Full-featured coding agent"
    Write-Host "  - plan - Planning agent (read-only)"
    Write-Host "  - explore - Codebase exploration and analysis"
    Write-Host "  - image-analyzer-subagent - Images/screenshots to code, OCR, error diagnosis"
    Write-Host "  - zai-media-subagent - Media production: image/video gen, ASR, OCR (delegated)"
    Write-Host "  - discovery-specialist-subagent - Customer-facing discovery: Vision docs + wireframes"
    Write-Host "  - ... and $((Get-AgentCount (Join-Path $RepoDir 'agents')) - 6) more agents"
    Write-Host ""
    Write-Host "  Usage: opencode --agent <name> `"prompt`""
    Write-Host "         opencode `"prompt`" (uses build)"
     Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
      Write-Host "                     $(Get-SkillCount (Join-Path $RepoDir 'skills')) Skills Available" -ForegroundColor White
     Write-Host "=====================================================================" -ForegroundColor White
      Write-Host ""
      Get-SkillCategories (Join-Path $RepoDir 'skills')
     Write-Host ""
    Write-Host "  Run 'opencode --list-skills' for detailed descriptions"
    Write-Host "  Run 'opencode --skill <name> `"prompt`"' to invoke a skill"
    Write-Host ""
     Write-Host "MCP Servers:"
     Write-Host "  Auto-start: codegraph, web-reader, web-search"
     Write-Host "  Opt-in per-project: atlassian"
     Write-Host "  Opt-in global packs: next-devtools, markitdown, docling, chrome-devtools (+ autodesk pack adds 4)"
    Write-Host ""
    Write-Host "  Auth: opencode mcp auth atlassian / opencode mcp auth github"
    Write-Host ""
    Write-Host "Documentation:"
    Write-Host "  - Update CLI: .\setup.ps1 -Update"
    Write-Host "  - Config file: $ConfigFile"
    Write-Host "  - Log file: $LogFile"
    Write-Host "  - Full docs: https://opencode.ai"
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
}

################################################################################
# MAIN
################################################################################

function Main {
    if ($Help) {
        Show-Help
        return
    }

    # Validate -EnablePack early (fail fast, non-zero exit) before any config
    # work. Mirrors setup.sh's validate_enable_pack.
    Test-EnablePack

    if ($Update) {
        Write-Host "=== OpenCode CLI Updater v$ScriptVersion ===" -ForegroundColor White
        Write-Host ""
        Initialize-Logging
        Update-OpenCodeCLI
        Write-Host ""
        Write-Host "Update complete!"
        return
    }

    if ($CheckUpdate) {
        Initialize-Logging
        Show-CheckUpdate
        return
    }

    # v2.0 models-only mode: provider selection + model resolution only
    if ($ModelsOnly) {
        Write-Host "=== OpenCode Model Resolution v$ScriptVersion ===" -ForegroundColor White
        Write-Host ""
        Initialize-Logging
        if (-not (Test-CommandExists "node")) {
            Write-LogError "Node.js is required for model resolution."
            return
        }
        Set-ModelProvider
        # Config via resolver; agent files via the manifest path (#379).
        Invoke-Resolver -ConfigOnly
        $updateArgs = @("update")
        if ($Provider) { $updateArgs += @("--provider", $Provider) }
        & node (Join-Path $InstallDir "init.mjs") @updateArgs
        Write-Host ""
        Write-Host "Model resolution complete!"
        return
    }

    # v2.0 migrate-only mode: v1.x -> v2.0 migration + resolution only
    if ($Migrate) {
        Write-Host "=== OpenCode Migration v$ScriptVersion ===" -ForegroundColor White
        Write-Host ""
        Initialize-Logging
        if (-not (Test-CommandExists "node")) {
            Write-LogError "Node.js is required for model resolution."
            return
        }
        if (-not (Test-Path $AgentsDestDir)) {
            New-Item -ItemType Directory -Path $AgentsDestDir -Force | Out-Null
        }
        Invoke-Migration
        Invoke-Resolver
        Write-Host ""
        Write-Host "Migration + model resolution complete!"
        return
    }

    if ($SkillsOnly) {
        Write-Host "=== OpenCode Skills Deployment v$ScriptVersion ===" -ForegroundColor White
        Write-Host ""
        Initialize-Logging

        if (-not (Test-CommandExists "opencode")) {
            Write-LogError "OpenCode CLI is not installed globally"
            Write-LogInfo "Please install OpenCode first: npm install -g opencode-ai"
            exit 1
        }
        Write-LogSuccess "OpenCode is installed ($(Get-OpenCodeVersion))"

        if (-not (Test-Dependencies)) {
            Write-LogError "Dependency check failed."
            exit 1
        }

        Set-Configuration
        Show-Summary
        Write-Host ""
        Write-Host "Skills deployment complete!"
        return
    }

    Write-Host "=== OpenCode Configuration Setup v$ScriptVersion ===" -ForegroundColor White
    Write-Host ""
    Initialize-Logging

    # v2.0.0: Rollback mode (mutually exclusive with normal setup flow)
    if ($Rollback) {
        try {
            Invoke-Rollback
        } catch {
            Write-LogError $_.Exception.Message
            exit 1
        }
        return
    }

    if (-not $Quick) {
        if (-not (Test-Dependencies)) {
            Write-LogError "Dependency check failed. Please install missing dependencies."
            exit 1
        }

        if (-not (Test-Network)) {
            Write-LogWarn "Network connectivity issues detected. Some features may not work."
            if (-not (Read-YesNo "Continue anyway?" $false)) {
                exit 1
            }
        }

        if ($EnableAutoUpdate) {
            Write-LogInfo "Auto-update is enabled (schedule: $ScheduleUpdate)"
            Invoke-AutoUpdate
        }
    }

    if (-not $Quick -and -not $Yes) {
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host "                      Setup Mode Selection" -ForegroundColor White
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host ""
        Write-Host "  1) Quick setup (config + skills only)"
        Write-Host "  2) Skills-only setup"
        Write-Host "  3) Full setup (API keys, Node.js, OpenCode)"
        Write-Host "  4) Update OpenCode CLI only"
        Write-Host "  5) Install PeonPing (sound notifications)"
        Write-Host ""

        $option = Read-Prompt "Select option" "2"

        switch ($option) {
            "1" {
                Write-Host ""
                Write-LogInfo "Quick Setup: Copy opencode.json and skills only"
                $script:Quick = $true
            }
            "2" {
                Write-Host ""
                Write-LogInfo "Skills-Only Setup: Copy skills folder only"

                if (-not (Test-CommandExists "opencode")) {
                    Write-LogError "OpenCode CLI is not installed globally"
                    Write-LogInfo "Please install OpenCode first: npm install -g opencode-ai"
                    exit 1
                }

                Set-Configuration
                Show-Summary
                Write-Host ""
                Write-Host "Skills deployment complete!"
                return
            }
            "3" {
                Write-LogInfo "Running full setup..."
            }
            "4" {
                Write-Host ""
                Write-LogInfo "Update OpenCode CLI only"
                Update-OpenCodeCLI
                Write-Host ""
                Write-Host "Update complete!"
                return
            }
            "5" {
                Write-Host ""
                Write-LogInfo "PeonPing Sound Notifications"
                Set-PeonPing
                Write-Host ""
                Write-Host "PeonPing setup complete!"
                return
            }
            default {
                Write-LogWarn "Invalid option. Running full setup..."
            }
        }
        Write-Host ""
    }

    if (-not $Quick) {
        Set-GitHubCLI
        Set-ZaiApiKey
        Set-NodeJS
        Set-OpenCode
    } else {
        Write-LogInfo "Running quick setup: opencode.json and skills deployment only"
    }

    Set-ModelProvider
    Set-Configuration
    Set-LearningsDir
    Set-ShellVariables

    # v2.0.0: Zip backup (after all flat-file backups, before cleanup)
    New-ZipBackup | Out-Null

    Remove-OldBackups

    Show-Summary
    Show-NextSteps

    Write-Log "INFO" "=== OpenCode Setup Completed at $(Get-Date) ==="

    if (-not $Yes) {
        Write-Host "Press Enter to exit..."
        Read-Host
    }
}

Main
