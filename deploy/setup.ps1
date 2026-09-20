# deploy/setup.ps1 — Windows thin launcher (#474)
#
# ONE interactive implementation lives in deploy/setup.sh (bash). This file is
# a thin Windows bootstrap: it translates the historical PowerShell flags and
# forwards EVERYTHING to setup.sh via Git-Bash or WSL. It performs no
# deployment selection logic of its own — the #470 plan model, the #471
# credential capture, the #473 picker, and the #470 D2 decline contract are
# inherited by delegation (this resolves the parity-bug class: #465, #466,
# #469, and the #490 disclosure items).
#
# Requires: Git-Bash (Git for Windows) or WSL, plus node >= 26.4.
# Previous native-PowerShell behavior is preserved through the flag mapping
# below; old flags keep working as aliases.

param(
    [switch]$Quick,
    [switch]$SkillsOnly,
    [switch]$DryRun,
    [switch]$Yes,
    [switch]$Update,
    [switch]$Rollback,
    [string]$RollbackTarget,
    [switch]$ModelsOnly,
    [switch]$Migrate,
    [switch]$Select,
    [switch]$CheckCatalog,
    [switch]$ListItems,
    [string]$SavePreset,
    [string]$Preset,
    [string]$EnablePack,
    [string]$Provider,
    [string]$SkillProfile,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ── Bootstrap: node >= 26.4 (picker dependency; opencode tolerates it) ──
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "node is required. Install Node.js 26+ (https://nodejs.org) or 'nvm install 26'."
    exit 1
}
$nodeVersion = [version]((node --version) -replace '^v', '')
if ($nodeVersion -lt [version]"26.4") {
    Write-Error "node >= 26.4 is required for --select (found $nodeVersion). Install Node.js 26+ and re-run."
    exit 1
}

# ── Bash discovery: Git-Bash first, then WSL ──
$bashExe = $null
$cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
if ($cmd) { $bashExe = $cmd.Source }
if (-not $bashExe) {
    foreach ($candidate in @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "$env:ProgramFiles\Git\usr\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )) {
        if (Test-Path $candidate) { $bashExe = $candidate; break }
    }
}
$useWsl = $false
if (-not $bashExe) {
    if (Get-Command wsl.exe -ErrorAction SilentlyContinue) { $useWsl = $true }
    else {
        Write-Error "No bash host found. Install Git for Windows (provides bash.exe) or enable WSL, then re-run."
        exit 1
    }
}

# ── Flag translation: historical ps1 flags → setup.sh args ──
$forward = @()
if ($Quick)         { $forward += "--quick" }
if ($SkillsOnly)    { $forward += "--skills-only" }
if ($DryRun)        { $forward += "--dry-run" }
if ($Yes)           { $forward += "--yes" }
if ($Update)        { $forward += "--update" }
if ($ModelsOnly)    { $forward += "--models-only" }
if ($Migrate)       { $forward += "--migrate" }
if ($Select)        { $forward += "--select" }
if ($CheckCatalog)  { $forward += "--check-catalog" }
if ($ListItems)     { $forward += "--list-items" }
if ($SavePreset)    { $forward += @("--save-preset", $SavePreset) }
if ($Preset)        { $forward += @("--preset", $Preset) }
if ($EnablePack)    { $forward += @("--enable-pack", $EnablePack) }
if ($Provider)      { $forward += @("--provider", $Provider) }
if ($SkillProfile)  { $forward += @("--skill-profile", $SkillProfile) }
if ($Force)         { $forward += "--force" }
if ($Rollback) {
    if ($RollbackTarget) { $forward += @("--rollback", $RollbackTarget) }
    else { $forward += "--rollback" }
}

# ── Forward everything to the bash implementation ──
$setupSh = Join-Path $PSScriptRoot "setup.sh"
if ($useWsl) {
    # Resolve the script's real path inside WSL (the caller's cwd is NOT the
    # script dir — README invokes from the repo root, the script lives in
    # deploy/).
    $wslScript = (wsl.exe wslpath -a "$($setupSh -replace '\\', '/')" | ForEach-Object { $_.Trim() })
    wsl.exe bash "$wslScript" @forward
    exit $LASTEXITCODE
}

& $bashExe $setupSh @forward
exit $LASTEXITCODE
