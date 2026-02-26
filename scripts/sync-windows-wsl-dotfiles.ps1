[CmdletBinding()]
param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$WslUser,
    [string]$RepoName = "dotfiles",
    [string]$RepoRoot,
    [string]$WindowsWeztermPath,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Resolve-WslUser {
    param([string]$DistroName)
    $value = (& wsl.exe -d $DistroName -e sh -lc 'whoami' 2>$null | Select-Object -First 1)
    if (-not $value) {
        throw "Unable to resolve WSL user from distro '$DistroName'. Pass -WslUser explicitly."
    }
    return $value.Trim()
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        if ($DryRun) {
            Write-Step "[dry-run] mkdir $Path"
            return
        }
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Sync-Directory {
    param(
        [string]$Source,
        [string]$Target
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source directory: $Source"
    }

    Write-Step "Sync dir: $Source -> $Target"
    Ensure-Directory -Path $Target

    if ($DryRun) {
        return
    }

    $null = & robocopy "$Source" "$Target" /MIR /R:2 /W:1 /NFL /NDL /NP /NJH /NJS
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed for '$Source' -> '$Target' (exit code $LASTEXITCODE)"
    }
}

function Sync-File {
    param(
        [string]$Source,
        [string]$Target
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source file: $Source"
    }

    Write-Step "Sync file: $Source -> $Target"

    $parent = Split-Path -Parent $Target
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    if ($DryRun) {
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Target -Force
}

function Normalize-WslLineEndings {
    param(
        [string]$DistroName,
        [string]$UserName
    )

    # Normalize LF endings for files consumed inside WSL. This avoids tmux/zsh
    # parse issues when source files were checked out with CRLF on Windows.
    $script = @'
set -eu
sanitize() {
  f="$1"
  [ -f "$f" ] || return 0
  sed -i "s/\r$//" "$f"
}

sanitize "$HOME/.zshrc"
sanitize "$HOME/.vimrc"

for d in "$HOME/.config/nvim" "$HOME/.config/tmux" "$HOME/.config/starship"; do
  [ -d "$d" ] || continue
  find "$d" -type f \( -name "*.lua" -o -name "*.toml" -o -name "*.conf" -o -name "*.vim" -o -name "*.vimrc" -o -name "*.sh" -o -name "*.zsh" \) -exec sed -i "s/\r$//" {} +
done
'@

    Write-Step "Normalizing line endings in WSL targets (LF)"
    if ($DryRun) {
        return
    }

    & wsl.exe -d $DistroName -u $UserName -e sh -lc $script
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to normalize line endings in WSL (exit code $LASTEXITCODE)"
    }
}

if (-not $WslUser) {
    $WslUser = Resolve-WslUser -DistroName $Distro
}

$wslHome = "\\wsl.localhost\$Distro\home\$WslUser"
if (-not $RepoRoot) {
    $RepoRoot = Join-Path $wslHome $RepoName
}
$repoConfigRoot = Join-Path $RepoRoot ".config"
$wslConfigRoot = Join-Path $wslHome ".config"

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "Repo root not found: $RepoRoot"
}

if (-not $WindowsWeztermPath) {
    $defaultDot = Join-Path $env:USERPROFILE ".wezterm.lua"
    $defaultPlain = Join-Path $env:USERPROFILE "wezterm.lua"
    if ((Test-Path -LiteralPath $defaultPlain) -and -not (Test-Path -LiteralPath $defaultDot)) {
        $WindowsWeztermPath = $defaultPlain
    }
    else {
        $WindowsWeztermPath = $defaultDot
    }
}

Write-Step "Distro           : $Distro"
Write-Step "WSL User         : $WslUser"
Write-Step "Repo Root        : $RepoRoot"
Write-Step "WSL Config Root  : $wslConfigRoot"
Write-Step "Windows WezTerm  : $WindowsWeztermPath"
if ($DryRun) {
    Write-Step "Mode             : dry-run"
}

Ensure-Directory -Path $wslConfigRoot

$configDirs = @(
    "nvim",
    "tmux",
    "starship"
)

foreach ($dir in $configDirs) {
    $src = Join-Path $repoConfigRoot $dir
    $dst = Join-Path $wslConfigRoot $dir
    Sync-Directory -Source $src -Target $dst
}

Sync-File -Source (Join-Path $RepoRoot ".zshrc") -Target (Join-Path $wslHome ".zshrc")
Sync-File -Source (Join-Path $RepoRoot ".tmux.conf") -Target (Join-Path $wslHome ".tmux.conf")
Sync-File -Source (Join-Path $repoConfigRoot ".vimrc") -Target (Join-Path $wslHome ".vimrc")
Sync-File -Source (Join-Path $repoConfigRoot "wezterm\wezterm.lua") -Target $WindowsWeztermPath
Normalize-WslLineEndings -DistroName $Distro -UserName $WslUser

Write-Step "Done."
