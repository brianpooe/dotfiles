# =============================================================================
# Dotfiles Setup Script for Windows (WSL Host Setup)
# =============================================================================
# This script prepares the Windows host for WSL-based dotfiles usage
# - Installs WSL if not present
# - Installs Windows Terminal
# - Installs fonts (required on Windows host for WSL terminals)
# - Installs WezTerm (optional terminal emulator)
#
# After running this script, run setup.sh inside your WSL distribution
# =============================================================================

#Requires -Version 5.1

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
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Cyan
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

    $installed = winget list --id $PackageId 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match $PackageId) {
        Write-Success "$PackageName is already installed"
        return
    }

    winget install --id $PackageId --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$PackageName installed successfully"
    }
    else {
        Write-Warning "Failed to install $PackageName (may already be installed or requires manual intervention)"
    }
}

# =============================================================================
# Install WSL
# =============================================================================

function Install-WSL {
    Write-Header "Setting up Windows Subsystem for Linux (WSL)"

    # Check if WSL is already installed
    $wslStatus = wsl --status 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "WSL is already installed"

        # List installed distributions
        Write-Info "Installed WSL distributions:"
        wsl --list --verbose
        return
    }

    Write-Info "Installing WSL with Ubuntu (default)..."
    Write-Warning "This may require a system restart"

    try {
        wsl --install
        Write-Success "WSL installation initiated"
        Write-Warning "Please restart your computer if prompted, then run this script again"
    }
    catch {
        Write-Error "Failed to install WSL"
        Write-Info "Try running: wsl --install"
        Write-Info "Or enable WSL through Windows Features"
    }
}

# =============================================================================
# Install Terminal Emulators
# =============================================================================

function Install-Terminals {
    Write-Header "Installing Terminal Emulators"

    $packages = @(
        @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
        @{ Id = "wez.wezterm"; Name = "WezTerm" }
    )

    foreach ($pkg in $packages) {
        Install-WingetPackage -PackageId $pkg.Id -PackageName $pkg.Name
    }
}

# =============================================================================
# Install Fonts
# =============================================================================

function Install-Fonts {
    Write-Header "Installing Fonts (Required for terminal icons)"

    Write-Info "Installing JetBrains Mono Nerd Font..."

    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    $tempDir = "$env:TEMP\JetBrainsMono"
    $zipFile = "$env:TEMP\JetBrainsMono.zip"

    try {
        # Download font
        Write-Info "Downloading font files..."
        Invoke-WebRequest -Uri $fontUrl -OutFile $zipFile -UseBasicParsing

        # Extract
        Write-Info "Extracting font files..."
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

        # Install fonts
        Write-Info "Installing fonts to system..."
        $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
        $fontFiles = Get-ChildItem -Path $tempDir -Filter "*.ttf"

        foreach ($fontFile in $fontFiles) {
            $fontsFolder.CopyHere($fontFile.FullName, 0x10)
        }

        # Cleanup
        Remove-Item -Path $zipFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-Success "JetBrains Mono Nerd Font installed ($($fontFiles.Count) files)"
    }
    catch {
        Write-Warning "Failed to install JetBrains Mono Nerd Font automatically"
        Write-Info "Please download manually from: https://www.nerdfonts.com/font-downloads"
    }
}

# =============================================================================
# Install Git (for cloning dotfiles on Windows side if needed)
# =============================================================================

function Install-Git {
    Write-Header "Installing Git"

    Install-WingetPackage -PackageId "Git.Git" -PackageName "Git"
}

# =============================================================================
# Post-Installation Notes
# =============================================================================

function Show-PostInstallNotes {
    Write-Header "Windows Host Setup Complete!"

    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. Open WSL (type 'wsl' in terminal or search for Ubuntu)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. Clone your dotfiles inside WSL:" -ForegroundColor Cyan
    Write-Host "     git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles"
    Write-Host ""
    Write-Host "  3. Run the setup script inside WSL:" -ForegroundColor Cyan
    Write-Host "     cd ~/dotfiles && chmod +x setup.sh && ./setup.sh"
    Write-Host ""
    Write-Host "  4. Configure your terminal (Windows Terminal or WezTerm):" -ForegroundColor Cyan
    Write-Host "     - Set font to 'JetBrainsMono Nerd Font'"
    Write-Host "     - Set default profile to your WSL distribution"
    Write-Host ""
    Write-Host "Windows Terminal settings location:" -ForegroundColor Yellow
    Write-Host "  Settings > Profiles > Ubuntu > Appearance > Font face"
    Write-Host ""
    Write-Host "WezTerm will use your WSL dotfiles config automatically if configured." -ForegroundColor Yellow
    Write-Host ""
}

# =============================================================================
# Main
# =============================================================================

function Main {
    Write-Header "Dotfiles Setup - Windows Host Preparation"

    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "Running without administrator privileges."
        Write-Warning "WSL installation and some font operations may fail."
        Write-Info "Consider running this script as Administrator."
        Write-Host ""
    }

    # Check and install winget
    if (-not (Install-Winget)) {
        Write-Error "winget is required but could not be installed. Exiting."
        exit 1
    }

    # Install components
    Install-WSL
    Install-Git
    Install-Terminals
    Install-Fonts

    # Show next steps
    Show-PostInstallNotes
}

# Run main function
Main
