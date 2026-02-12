#!/usr/bin/env bash
set -euo pipefail

# nvim-offline-prepare.sh
# =======================
# Pre-downloads ALL Neovim dependencies for offline use behind a corporate proxy.
#
# Produces a *clean, Linux-safe tarball*:
#   - No AppleDouble (._*) files
#   - No extended attributes, ACLs, or resource forks
#
# Run on a machine with unrestricted internet access.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
NVIM_CONFIG="$DOTFILES_DIR/.config/nvim"
BUNDLE_DIR="${1:-$SCRIPT_DIR/nvim-offline-bundle}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

# ── macOS archive hygiene ────────────────────────────────────────────────────
# Absolutely critical: prevents creation of ._* AppleDouble files
export COPYFILE_DISABLE=1

# ── Verify prerequisites ────────────────────────────────────────────────────
command -v nvim >/dev/null 2>&1 || {
    error "nvim is not installed"
    exit 1
}
command -v git >/dev/null 2>&1 || {
    error "git is not installed"
    exit 1
}

if [ ! -f "$NVIM_CONFIG/init.lua" ]; then
    error "Neovim config not found at $NVIM_CONFIG/init.lua"
    exit 1
fi

info "Preparing offline Neovim bundle..."
echo "    Neovim config : $NVIM_CONFIG"
echo "    Bundle output : $BUNDLE_DIR"
echo ""

mkdir -p "$BUNDLE_DIR/share/nvim" "$BUNDLE_DIR/state/nvim" "$BUNDLE_DIR/cache/nvim"

# Use isolated XDG directories
export XDG_DATA_HOME="$BUNDLE_DIR/share"
export XDG_STATE_HOME="$BUNDLE_DIR/state"
export XDG_CACHE_HOME="$BUNDLE_DIR/cache"

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

# ── Step 2: Install plugins, treesitter parsers, Mason packages ─────────────
info "Step 2/3: Installing plugins, parsers, and Mason packages..."
info "  This runs everything in a single headless nvim session..."

nvim --headless \
    -u "$NVIM_CONFIG/init.lua" \
    -c "lua require('lazy').sync({wait=true})" \
    -c "lua vim.wait(5000)" \
    -c "lua vim.wait(120000, function()
        local ok, registry = pcall(require, 'mason-registry')
        if not ok then return true end
        for _, pkg in ipairs(registry.get_all_packages()) do
            if pkg:is_installing() then return false end
        end
        return true
    end, 2000)" \
    -c "MasonToolsInstallSync" \
    -c "qa" 2>&1 || warn "Some installs reported warnings (usually harmless)"

# ── Verification ────────────────────────────────────────────────────────────
TS_PARSER_DIR="$XDG_DATA_HOME/nvim/lazy/nvim-treesitter/parser"
if [ -d "$TS_PARSER_DIR" ]; then
    TS_COUNT=$(ls -1 "$TS_PARSER_DIR"/*.so 2>/dev/null | wc -l)
    info "  $TS_COUNT treesitter parsers compiled"
fi

if [ -d "$XDG_DATA_HOME/nvim/mason/packages" ]; then
    MASON_COUNT=$(ls -1 "$XDG_DATA_HOME/nvim/mason/packages" | wc -l)
    info "  $MASON_COUNT Mason packages installed"
fi

# ── Step 3: Sanitize + Package ──────────────────────────────────────────────
info "Step 3/3: Sanitizing bundle..."

# Hard-delete any AppleDouble files (defensive)
find "$BUNDLE_DIR" -name '._*' -type f -delete

# Fail hard if any remain
if find "$BUNDLE_DIR" -name '._*' | grep -q .; then
    error "AppleDouble files detected after cleanup. Aborting."
    exit 1
fi

# Copy lockfile for reproducibility
if [ -f "$NVIM_CONFIG/lazy-lock.json" ]; then
    cp "$NVIM_CONFIG/lazy-lock.json" "$BUNDLE_DIR/"
    info "Copied lazy-lock.json"
fi

info "Creating tarball..."
TARBALL="$(cd "$(dirname "$BUNDLE_DIR")" && pwd)/nvim-offline-bundle.tar.gz"

tar \
    --no-xattrs \
    --no-acls \
    --no-selinux \
    -czf "$TARBALL" \
    -C "$(dirname "$BUNDLE_DIR")" \
    "$(basename "$BUNDLE_DIR")"

TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
info "Bundle created successfully!"
echo ""
echo "    Tarball : $TARBALL ($TARBALL_SIZE)"
echo ""
echo "    Plugins            : ${PLUGIN_COUNT:-unknown}"
echo "    Treesitter parsers : ${TS_COUNT:-0}"
echo "    Mason packages     : ${MASON_COUNT:-0}"
echo ""
echo "    Next steps:"
echo "    1. Transfer the tarball to the offline machine"
echo "    2. Run: ./scripts/nvim-offline-install.sh $TARBALL"
echo "    3. export NVIM_OFFLINE=1"
