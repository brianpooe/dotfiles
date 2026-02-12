#!/usr/bin/env bash
set -euo pipefail

# nvim-offline-prepare.sh
# =======================
# Pre-downloads ALL Neovim dependencies for offline use behind a corporate proxy.
#
# Run this on a machine with unrestricted internet access. It will:
#   1. Bootstrap lazy.nvim and install all plugins (git clones + build steps)
#   2. Install all Mason packages (LSP servers, linters, formatters, DAP adapters)
#   3. Package everything into a portable tarball
#
# Treesitter parsers are compiled automatically during step 1 via the
# :TSUpdate build step and ensure_installed in the config.
#
# Prerequisites:
#   - nvim (same version as the target machine)
#   - git, make, gcc/cc (for telescope-fzf-native, treesitter parsers)
#   - node + npm  (for Mason JS-based tools: prettier, eslint_d, etc.)
#   - python3 + pip (for Mason Python-based tools: debugpy, ruff, etc.)
#   - cargo (optional, for blink.cmp fuzzy matcher)
#
# Usage:
#   ./scripts/nvim-offline-prepare.sh [bundle-dir]
#
# After completion, transfer the tarball to the offline machine and run:
#   ./scripts/nvim-offline-install.sh nvim-offline-bundle.tar.gz

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
NVIM_CONFIG="$DOTFILES_DIR/.config/nvim"
BUNDLE_DIR="${1:-$SCRIPT_DIR/nvim-offline-bundle}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARNING:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

# ── Verify prerequisites ────────────────────────────────────────────────────
command -v nvim >/dev/null 2>&1 || { error "nvim is not installed"; exit 1; }
command -v git  >/dev/null 2>&1 || { error "git is not installed";  exit 1; }

if [ ! -f "$NVIM_CONFIG/init.lua" ]; then
    error "Neovim config not found at $NVIM_CONFIG/init.lua"
    exit 1
fi

info "Preparing offline Neovim bundle..."
echo "    Neovim config : $NVIM_CONFIG"
echo "    Bundle output : $BUNDLE_DIR"
echo ""

mkdir -p "$BUNDLE_DIR/share/nvim" "$BUNDLE_DIR/state/nvim" "$BUNDLE_DIR/cache/nvim"

# Use isolated XDG directories so we don't touch the user's existing nvim data
export XDG_DATA_HOME="$BUNDLE_DIR/share"
export XDG_STATE_HOME="$BUNDLE_DIR/state"
export XDG_CACHE_HOME="$BUNDLE_DIR/cache"

# Make sure NVIM_OFFLINE is NOT set during preparation (we need network access)
unset NVIM_OFFLINE

# ── Step 1: Bootstrap lazy.nvim ─────────────────────────────────────────────
info "Step 1/3: Bootstrapping lazy.nvim..."
LAZY_DIR="$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_DIR" ]; then
    git clone --filter=blob:none --branch=stable \
        https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
else
    info "  lazy.nvim already present, skipping clone"
fi

# ── Step 2: Install all plugins + treesitter parsers ────────────────────────
info "Step 2/3: Installing plugins via Lazy sync..."
info "  This clones all plugin repos, runs build steps (fzf-native, treesitter"
info "  parsers), and installs mason-nvim-dap adapters."

# Lazy sync installs all plugins and runs build steps (:TSUpdate compiles
# treesitter parsers, telescope-fzf-native runs make, etc.).
# After sync completes, mason-nvim-dap fires async installs for DAP adapters.
# We poll the Mason registry and wait for all async installs to finish before
# quitting, so nothing gets aborted.
nvim --headless \
    -u "$NVIM_CONFIG/init.lua" \
    -c "lua require('lazy').sync({wait=true})" \
    -c "lua vim.wait(120000, function()
        local ok, registry = pcall(require, 'mason-registry')
        if not ok then return true end
        for _, pkg in ipairs(registry.get_all_packages()) do
            if pkg:is_installing() then return false end
        end
        return true
    end, 2000)" \
    -c "qa" 2>&1 || warn "Lazy sync reported warnings (may be normal for headless)"

# Verify treesitter parsers
TS_PARSER_DIR="$XDG_DATA_HOME/nvim/lazy/nvim-treesitter/parser"
if [ -d "$TS_PARSER_DIR" ]; then
    TS_COUNT=$(ls -1 "$TS_PARSER_DIR"/*.so 2>/dev/null | wc -l)
    info "  $TS_COUNT treesitter parsers compiled"
else
    warn "  No treesitter parser directory found"
fi

# ── Step 3: Install Mason packages ─────────────────────────────────────────
info "Step 3/3: Installing Mason packages (LSP servers, linters, formatters)..."
info "  This downloads binaries and may take several minutes..."
nvim --headless \
    -u "$NVIM_CONFIG/init.lua" \
    -c "MasonToolsInstallSync" \
    -c "qa" 2>&1 || warn "Some Mason packages may have failed"

# Verify Mason installations
info "Verifying Mason packages..."
if [ -d "$XDG_DATA_HOME/nvim/mason/packages" ]; then
    MASON_COUNT=$(ls -1 "$XDG_DATA_HOME/nvim/mason/packages" 2>/dev/null | wc -l)
    info "  $MASON_COUNT Mason packages installed"
else
    warn "  No Mason packages directory found - Mason installs may have failed"
    warn "  You can install Mason packages manually and re-run this script"
fi

# ── Copy lazy-lock.json ────────────────────────────────────────────────────
if [ -f "$NVIM_CONFIG/lazy-lock.json" ]; then
    cp "$NVIM_CONFIG/lazy-lock.json" "$BUNDLE_DIR/"
    info "Copied lazy-lock.json to bundle"
fi

# ── Create tarball ──────────────────────────────────────────────────────────
info "Creating tarball..."
TARBALL="$(cd "$(dirname "$BUNDLE_DIR")" && pwd)/nvim-offline-bundle.tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$BUNDLE_DIR")" "$(basename "$BUNDLE_DIR")"
TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
info "Bundle created successfully!"
echo ""
echo "    Tarball : $TARBALL ($TARBALL_SIZE)"
echo ""
if [ -d "$XDG_DATA_HOME/nvim/lazy" ]; then
    PLUGIN_COUNT=$(ls -1 "$XDG_DATA_HOME/nvim/lazy" 2>/dev/null | wc -l)
    echo "    Plugins            : $PLUGIN_COUNT"
fi
if [ -d "$TS_PARSER_DIR" ]; then
    echo "    Treesitter parsers : ${TS_COUNT:-0}"
fi
if [ -d "$XDG_DATA_HOME/nvim/mason/packages" ]; then
    echo "    Mason packages     : ${MASON_COUNT:-0}"
fi
echo ""
echo "    Next steps:"
echo "    1. Transfer the tarball to your corporate/offline machine"
echo "    2. Run: ./scripts/nvim-offline-install.sh $TARBALL"
echo "    3. Add 'export NVIM_OFFLINE=1' to your ~/.zshrc or ~/.bashrc"
