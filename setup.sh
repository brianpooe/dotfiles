#!/usr/bin/env bash

# =============================================================================
# Dotfiles Setup Script
# =============================================================================
# This script installs all required dependencies before cloning/using dotfiles
# Supports: macOS (Homebrew), Linux (Homebrew), Windows (winget via PowerShell)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)    OS="macos" ;;
        Linux*)     OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*)    OS="windows" ;;
        *)          OS="unknown" ;;
    esac
    echo "$OS"
}

# =============================================================================
# Package Manager Installation
# =============================================================================

install_homebrew() {
    if command -v brew &> /dev/null; then
        print_success "Homebrew is already installed"
        brew update
    else
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Linux
        if [[ "$OS" == "linux" ]]; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed successfully"
    fi
}

# =============================================================================
# macOS/Linux Installation (Homebrew)
# =============================================================================

install_brew_packages() {
    print_header "Installing Homebrew packages"

    # Essential tools
    local essential_packages=(
        "git"
        "neovim"
        "tmux"
        "zsh"
        "starship"
    )

    # Terminal & Shell utilities
    local shell_utils=(
        "fzf"
        "fd"
        "bat"
        "eza"
        "zoxide"
        "lazygit"
        "ripgrep"
        "tree"
        "wget"
        "curl"
        "make"
    )

    # Programming languages & runtimes
    local languages=(
        "node"
        "python@3"
        "go"
        "rust"
        "lua"
        "luarocks"
    )

    # Development tools
    local dev_tools=(
        "cmake"
        "gcc"
    )

    # Install essential packages
    print_info "Installing essential packages..."
    for pkg in "${essential_packages[@]}"; do
        if brew list "$pkg" &> /dev/null; then
            print_success "$pkg is already installed"
        else
            print_info "Installing $pkg..."
            brew install "$pkg" || print_warning "Failed to install $pkg"
        fi
    done

    # Install shell utilities
    print_info "Installing shell utilities..."
    for pkg in "${shell_utils[@]}"; do
        if brew list "$pkg" &> /dev/null; then
            print_success "$pkg is already installed"
        else
            print_info "Installing $pkg..."
            brew install "$pkg" || print_warning "Failed to install $pkg"
        fi
    done

    # Install programming languages
    print_info "Installing programming languages..."
    for pkg in "${languages[@]}"; do
        if brew list "$pkg" &> /dev/null; then
            print_success "$pkg is already installed"
        else
            print_info "Installing $pkg..."
            brew install "$pkg" || print_warning "Failed to install $pkg"
        fi
    done

    # Install development tools
    print_info "Installing development tools..."
    for pkg in "${dev_tools[@]}"; do
        if brew list "$pkg" &> /dev/null; then
            print_success "$pkg is already installed"
        else
            print_info "Installing $pkg..."
            brew install "$pkg" || print_warning "Failed to install $pkg"
        fi
    done
}

install_brew_casks() {
    print_header "Installing Homebrew Casks (GUI applications)"

    # Only run on macOS
    if [[ "$OS" != "macos" ]]; then
        print_warning "Cask installation is only available on macOS"
        return
    fi

    local casks=(
        "wezterm"
        "font-jetbrains-mono-nerd-font"
        "karabiner-elements"
    )

    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &> /dev/null; then
            print_success "$cask is already installed"
        else
            print_info "Installing $cask..."
            brew install --cask "$cask" || print_warning "Failed to install $cask"
        fi
    done
}

install_linux_specific() {
    print_header "Installing Linux-specific packages"

    # WezTerm on Linux
    if ! command -v wezterm &> /dev/null; then
        print_info "Installing WezTerm..."
        brew install wezterm || print_warning "Failed to install wezterm via brew"
    else
        print_success "WezTerm is already installed"
    fi

    # JetBrains Mono Nerd Font
    print_info "Installing JetBrains Mono Nerd Font..."
    brew tap homebrew/linux-fonts 2>/dev/null || true
    brew install font-jetbrains-mono-nerd-font 2>/dev/null || {
        # Alternative: Download directly
        print_info "Downloading JetBrains Mono Nerd Font..."
        mkdir -p ~/.local/share/fonts
        curl -fLo "/tmp/JetBrainsMono.zip" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
        unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/
        fc-cache -fv
        rm /tmp/JetBrainsMono.zip
        print_success "JetBrains Mono Nerd Font installed"
    }
}

# =============================================================================
# Node.js Version Manager (NVM) Installation
# =============================================================================

install_nvm() {
    print_header "Installing NVM (Node Version Manager)"

    if [[ -d "$HOME/.nvm" ]]; then
        print_success "NVM is already installed"
    else
        print_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        print_success "NVM installed successfully"
    fi

    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS Node.js
    if command -v nvm &> /dev/null; then
        print_info "Installing latest LTS Node.js..."
        nvm install --lts
        nvm use --lts
        print_success "Node.js LTS installed"
    fi
}

# =============================================================================
# Tmux Plugin Manager (TPM) Installation
# =============================================================================

install_tpm() {
    print_header "Installing Tmux Plugin Manager (TPM)"

    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        print_success "TPM is already installed"
    else
        print_info "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        print_success "TPM installed successfully"
        print_info "Remember to press prefix + I inside tmux to install plugins"
    fi
}

# =============================================================================
# Set Zsh as default shell
# =============================================================================

set_zsh_default() {
    print_header "Setting Zsh as default shell"

    if [[ "$SHELL" == *"zsh"* ]]; then
        print_success "Zsh is already the default shell"
    else
        local zsh_path
        zsh_path=$(which zsh)

        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            print_info "Adding Zsh to /etc/shells (requires sudo)..."
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi

        print_info "Changing default shell to Zsh..."
        chsh -s "$zsh_path"
        print_success "Default shell changed to Zsh"
        print_warning "Please log out and back in for changes to take effect"
    fi
}

# =============================================================================
# Verify installations
# =============================================================================

verify_installations() {
    print_header "Verifying installations"

    local tools=(
        "git"
        "nvim"
        "tmux"
        "zsh"
        "starship"
        "fzf"
        "fd"
        "bat"
        "eza"
        "zoxide"
        "lazygit"
        "node"
        "python3"
        "go"
        "rustc"
        "cargo"
        "lua"
    )

    local missing=()

    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version
            version=$($tool --version 2>/dev/null | head -n1 || echo "installed")
            print_success "$tool: $version"
        else
            print_error "$tool: not found"
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "\nSome tools were not installed: ${missing[*]}"
        print_info "You may need to install them manually or check for errors above"
    else
        print_success "\nAll tools installed successfully!"
    fi
}

# =============================================================================
# Post-installation notes
# =============================================================================

print_post_install_notes() {
    print_header "Post-Installation Notes"

    echo -e "${GREEN}Installation complete!${NC}\n"

    echo "Next steps:"
    echo "  1. Clone your dotfiles repository"
    echo "  2. Symlink or copy configuration files to their proper locations:"
    echo "     - ~/.config/nvim/     (Neovim)"
    echo "     - ~/.config/wezterm/  (WezTerm)"
    echo "     - ~/.config/starship.toml (Starship)"
    echo "     - ~/.tmux.conf        (Tmux)"
    echo "     - ~/.zshrc            (Zsh)"
    echo ""
    echo "  3. Start Neovim and let plugins install automatically (via lazy.nvim)"
    echo "  4. Start tmux and press 'prefix + I' to install tmux plugins"
    echo ""
    echo "Mason will automatically install LSP servers, formatters, and linters"
    echo "when you open Neovim for the first time."
    echo ""

    if [[ "$OS" == "macos" ]]; then
        echo "macOS-specific:"
        echo "  - Configure Karabiner-Elements for keyboard remapping"
        echo "  - Import karabiner configuration from dotfiles"
    fi
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
    print_header "Dotfiles Setup Script"

    OS=$(detect_os)
    print_info "Detected operating system: $OS"

    case "$OS" in
        macos|linux)
            install_homebrew
            install_brew_packages

            if [[ "$OS" == "macos" ]]; then
                install_brew_casks
            else
                install_linux_specific
            fi

            install_nvm
            install_tpm
            set_zsh_default
            verify_installations
            print_post_install_notes
            ;;
        windows)
            print_error "Please run setup-windows.ps1 for Windows installation"
            exit 1
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
