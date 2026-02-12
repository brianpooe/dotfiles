#!/usr/bin/env bash
set -euo pipefail

# nvim-offline-install.sh
# =======================
# Deploys pre-downloaded Neovim dependencies on an offline / corporate proxy machine.
#
# Usage:
#   ./scripts/nvim-offline-install.sh <nvim-offline-bundle.tar.gz>
#
# What it does:
#   1. Extracts lazy.nvim plugins   → ~/.local/share/nvim/lazy/
#   2. Extracts Mason packages      → ~/.local/share/nvim/mason/
#   3. Copies lazy-lock.json        → .config/nvim/lazy-lock.json
#
# After running, add to your shell profile (~/.zshrc or ~/.bashrc):
#   export NVIM_OFFLINE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
NVIM_CONFIG="$DOTFILES_DIR/.config/nvim"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARNING:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

TARBALL="${1:-}"
if [ -z "$TARBALL" ]; then
    error "Usage: $0 <nvim-offline-bundle.tar.gz>"
    exit 1
fi

if [ ! -f "$TARBALL" ]; then
    error "File not found: $TARBALL"
    exit 1
fi

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
NVIM_DATA="$XDG_DATA_HOME/nvim"

info "Installing offline Neovim bundle..."
echo "    Source  : $TARBALL"
echo "    Target  : $NVIM_DATA"
echo ""

# ── Extract to temp directory ───────────────────────────────────────────────
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

info "Extracting bundle..."
tar -xzf "$TARBALL" -C "$TMPDIR"

BUNDLE_DIR="$TMPDIR/nvim-offline-bundle"
if [ ! -d "$BUNDLE_DIR/share/nvim" ]; then
    error "Invalid bundle: missing share/nvim directory"
    exit 1
fi

# ── Install lazy.nvim plugins ──────────────────────────────────────────────
if [ -d "$BUNDLE_DIR/share/nvim/lazy" ]; then
    PLUGIN_COUNT=$(ls -1 "$BUNDLE_DIR/share/nvim/lazy" 2>/dev/null | wc -l)
    info "Installing $PLUGIN_COUNT plugins to $NVIM_DATA/lazy/..."

    if [ -d "$NVIM_DATA/lazy" ]; then
        warn "Existing lazy/ directory found — backing up to lazy.bak/"
        rm -rf "$NVIM_DATA/lazy.bak"
        mv "$NVIM_DATA/lazy" "$NVIM_DATA/lazy.bak"
    fi

    mkdir -p "$NVIM_DATA"
    cp -r "$BUNDLE_DIR/share/nvim/lazy" "$NVIM_DATA/lazy"
fi

# ── Install Mason packages ─────────────────────────────────────────────────
if [ -d "$BUNDLE_DIR/share/nvim/mason" ]; then
    MASON_COUNT=$(ls -1 "$BUNDLE_DIR/share/nvim/mason/packages" 2>/dev/null | wc -l)
    info "Installing $MASON_COUNT Mason packages to $NVIM_DATA/mason/..."

    if [ -d "$NVIM_DATA/mason" ]; then
        warn "Existing mason/ directory found — backing up to mason.bak/"
        rm -rf "$NVIM_DATA/mason.bak"
        mv "$NVIM_DATA/mason" "$NVIM_DATA/mason.bak"
    fi

    cp -r "$BUNDLE_DIR/share/nvim/mason" "$NVIM_DATA/mason"
fi

# ── Install lazy-lock.json ─────────────────────────────────────────────────
if [ -f "$BUNDLE_DIR/lazy-lock.json" ] && [ -d "$NVIM_CONFIG" ]; then
    info "Installing lazy-lock.json to $NVIM_CONFIG/"
    cp "$BUNDLE_DIR/lazy-lock.json" "$NVIM_CONFIG/lazy-lock.json"
fi

# ── Verify ──────────────────────────────────────────────────────────────────
echo ""
info "Installation complete!"
echo ""
echo "    Plugins : $NVIM_DATA/lazy/"
echo "    Mason   : $NVIM_DATA/mason/"
echo ""
echo "    ┌─────────────────────────────────────────────────────────┐"
echo "    │  Add the following to your ~/.zshrc (or ~/.bashrc):     │"
echo "    │                                                         │"
echo "    │    export NVIM_OFFLINE=1                                │"
echo "    │                                                         │"
echo "    │  Then restart your shell or run: source ~/.zshrc        │"
echo "    └─────────────────────────────────────────────────────────┘"
echo ""
echo "    This tells Neovim to skip all network operations:"
echo "    - Plugin update checks (lazy.nvim)"
echo "    - Auto-install of LSP servers & tools (Mason)"
echo "    - Auto-install of Treesitter parsers"
echo "    - Auto-install of DAP adapters"
echo ""
echo "    To re-enable network access later, unset NVIM_OFFLINE"
