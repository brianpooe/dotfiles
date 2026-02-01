# =============================================================================
# Dotfiles Setup Script for Windows
# =============================================================================
# This script installs all required dependencies before cloning/using dotfiles
# Uses: winget (Windows Package Manager)
# Run as Administrator for best results
# =============================================================================

#Requires -Version 5.1

# Set execution policy for this script
$ErrorActionPreference = "Continue"

# Colors and formatting
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "============================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Cyan
}

# =============================================================================
# Check if winget is available
# =============================================================================

function Test-WingetAvailable {
    try {
        $null = winget --version
        return $true
    }
    catch {
        return $false
    }
}

function Install-Winget {
    Write-Header "Checking Windows Package Manager (winget)"

    if (Test-WingetAvailable) {
        Write-Success "winget is already installed"
        return $true
    }

    Write-Info "winget is not installed. Attempting to install..."

    # Try to install via Microsoft Store (App Installer)
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        Write-Success "winget installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install winget automatically"
        Write-Info "Please install 'App Installer' from Microsoft Store manually"
        Write-Info "URL: https://aka.ms/getwinget"
        return $false
    }
}

# =============================================================================
# Install packages using winget
# =============================================================================

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$PackageName
    )

    Write-Info "Installing $PackageName..."

    # Check if already installed
    $installed = winget list --id $PackageId 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match $PackageId) {
        Write-Success "$PackageName is already installed"
        return
    }

    # Install package
    winget install --id $PackageId --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$PackageName installed successfully"
    }
    else {
        Write-Warning "Failed to install $PackageName (may already be installed or requires manual intervention)"
    }
}

function Install-EssentialPackages {
    Write-Header "Installing Essential Packages"

    $packages = @(
        @{ Id = "Git.Git"; Name = "Git" },
        @{ Id = "Neovim.Neovim"; Name = "Neovim" },
        @{ Id = "wez.wezterm"; Name = "WezTerm" },
        @{ Id = "Starship.Starship"; Name = "Starship" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -PackageName $pkg.Name
    }
}

function Install-ShellUtilities {
    Write-Header "Installing Shell Utilities"

    $packages = @(
        @{ Id = "junegunn.fzf"; Name = "fzf (Fuzzy Finder)" },
        @{ Id = "sharkdp.fd"; Name = "fd (File Finder)" },
        @{ Id = "sharkdp.bat"; Name = "bat (Cat Alternative)" },
        @{ Id = "eza-community.eza"; Name = "eza (ls Alternative)" },
        @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide (Smarter cd)" },
        @{ Id = "JesseDuffield.lazygit"; Name = "lazygit (Git UI)" },
        @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep (Search Tool)" },
        @{ Id = "GnuWin32.Make"; Name = "Make (Build Tool)" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -PackageName $pkg.Name
    }
}

function Install-ProgrammingLanguages {
    Write-Header "Installing Programming Languages & Runtimes"

    $packages = @(
        @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" },
        @{ Id = "Python.Python.3.12"; Name = "Python 3.12" },
        @{ Id = "GoLang.Go"; Name = "Go" },
        @{ Id = "Rustlang.Rustup"; Name = "Rust (rustup)" },
        @{ Id = "DEVCOM.Lua"; Name = "Lua" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -PackageName $pkg.Name
    }
}

function Install-DevelopmentTools {
    Write-Header "Installing Development Tools"

    $packages = @(
        @{ Id = "Microsoft.VisualStudio.2022.BuildTools"; Name = "Visual Studio Build Tools" },
        @{ Id = "Kitware.CMake"; Name = "CMake" },
        @{ Id = "LLVM.LLVM"; Name = "LLVM/Clang" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -PackageName $pkg.Name
    }
}

function Install-Fonts {
    Write-Header "Installing Fonts"

    # JetBrains Mono Nerd Font
    Write-Info "Installing JetBrains Mono Nerd Font..."

    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    $tempDir = "$env:TEMP\JetBrainsMono"
    $zipFile = "$env:TEMP\JetBrainsMono.zip"

    try {
        # Download font
        Invoke-WebRequest -Uri $fontUrl -OutFile $zipFile -UseBasicParsing

        # Extract
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

        # Install fonts
        $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $tempDir -Filter "*.ttf" | ForEach-Object {
            $fontPath = $_.FullName
            $fontsFolder.CopyHere($fontPath, 0x10)
        }

        # Cleanup
        Remove-Item -Path $zipFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-Success "JetBrains Mono Nerd Font installed"
    }
    catch {
        Write-Warning "Failed to install JetBrains Mono Nerd Font automatically"
        Write-Info "Please download manually from: https://www.nerdfonts.com/font-downloads"
    }
}

function Install-OptionalTools {
    Write-Header "Installing Optional Tools"

    $packages = @(
        @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
        @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7" },
        @{ Id = "Docker.DockerDesktop"; Name = "Docker Desktop" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -PackageName $pkg.Name
    }
}

# =============================================================================
# Install NVM for Windows
# =============================================================================

function Install-NvmWindows {
    Write-Header "Installing NVM for Windows"

    # Check if nvm is already installed
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        Write-Success "NVM for Windows is already installed"
        return
    }

    Write-Info "Installing NVM for Windows..."
    Install-WingetPackage -PackageId "CoreyButler.NVMforWindows" -PackageName "NVM for Windows"
}

# =============================================================================
# Configure Environment
# =============================================================================

function Update-EnvironmentPath {
    Write-Header "Updating Environment Path"

    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Success "Environment path updated"
    Write-Info "You may need to restart your terminal for all changes to take effect"
}

# =============================================================================
# Verify Installations
# =============================================================================

function Test-Installations {
    Write-Header "Verifying Installations"

    $tools = @(
        @{ Command = "git"; Name = "Git" },
        @{ Command = "nvim"; Name = "Neovim" },
        @{ Command = "wezterm"; Name = "WezTerm" },
        @{ Command = "starship"; Name = "Starship" },
        @{ Command = "fzf"; Name = "fzf" },
        @{ Command = "fd"; Name = "fd" },
        @{ Command = "bat"; Name = "bat" },
        @{ Command = "eza"; Name = "eza" },
        @{ Command = "zoxide"; Name = "zoxide" },
        @{ Command = "lazygit"; Name = "lazygit" },
        @{ Command = "node"; Name = "Node.js" },
        @{ Command = "python"; Name = "Python" },
        @{ Command = "go"; Name = "Go" },
        @{ Command = "rustc"; Name = "Rust" },
        @{ Command = "cargo"; Name = "Cargo" }
    )

    $missing = @()

    foreach ($tool in $tools) {
        try {
            $version = & $tool.Command --version 2>$null | Select-Object -First 1
            if ($version) {
                Write-Success "$($tool.Name): $version"
            }
            else {
                throw "Not found"
            }
        }
        catch {
            Write-Error "$($tool.Name): not found"
            $missing += $tool.Name
        }
    }

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Warning "Some tools were not found: $($missing -join ', ')"
        Write-Info "You may need to restart your terminal or install them manually"
    }
    else {
        Write-Host ""
        Write-Success "All tools verified successfully!"
    }
}

# =============================================================================
# Post-Installation Notes
# =============================================================================

function Show-PostInstallNotes {
    Write-Header "Post-Installation Notes"

    Write-Host "Installation complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart your terminal/PowerShell session"
    Write-Host "  2. Clone your dotfiles repository"
    Write-Host "  3. Copy/symlink configuration files to their proper locations:"
    Write-Host "     - %LOCALAPPDATA%\nvim\         (Neovim)"
    Write-Host "     - %USERPROFILE%\.config\wezterm\  (WezTerm)"
    Write-Host "     - %USERPROFILE%\.config\starship.toml (Starship)"
    Write-Host ""
    Write-Host "  4. Start Neovim and let plugins install automatically (via lazy.nvim)"
    Write-Host ""
    Write-Host "Configure Starship in PowerShell profile:" -ForegroundColor Cyan
    Write-Host '  Add to $PROFILE: Invoke-Expression (&starship init powershell)'
    Write-Host ""
    Write-Host "Configure zoxide in PowerShell profile:" -ForegroundColor Cyan
    Write-Host '  Add to $PROFILE: Invoke-Expression (& { (zoxide init powershell | Out-String) })'
    Write-Host ""
    Write-Host "Mason will automatically install LSP servers, formatters, and linters"
    Write-Host "when you open Neovim for the first time."
    Write-Host ""
}

# =============================================================================
# Main Installation Flow
# =============================================================================

function Main {
    Write-Header "Dotfiles Setup Script for Windows"

    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "Running without administrator privileges. Some installations may fail."
        Write-Info "Consider running this script as Administrator for best results."
        Write-Host ""
    }

    # Check and install winget
    if (-not (Install-Winget)) {
        Write-Error "winget is required but could not be installed. Exiting."
        exit 1
    }

    # Install all packages
    Install-EssentialPackages
    Install-ShellUtilities
    Install-ProgrammingLanguages
    Install-DevelopmentTools
    Install-NvmWindows
    Install-Fonts
    Install-OptionalTools

    # Update environment and verify
    Update-EnvironmentPath
    Test-Installations
    Show-PostInstallNotes
}

# Run main function
Main
