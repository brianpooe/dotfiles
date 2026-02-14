#!/usr/bin/env bash
set -euo pipefail

# nvim-offline-install.sh
# =======================
# Deploys pre-downloaded Neovim dependencies on an offline / corporate proxy machine.
# Compatible with the Docker-generated offline bundle.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
NVIM_CONFIG="$DOTFILES_DIR/.config/nvim"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

# ── Archive hygiene (defensive) ──────────────────────────────────────────────
export COPYFILE_DISABLE=1

TARBALL="${1:-}"
if [ -z "$TARBALL" ]; then
    error "Usage: $0 <nvim-offline-bundle.tar.gz>"
    exit 1
fi

if [ ! -f "$TARBALL" ]; then
    error "File not found: $TARBALL"
    exit 1
fi

copy_tree() {
    local src="$1"
    local dst="$2"
    rsync -a --delete "$src/" "$dst/"
}

rewrite_mason_paths() {
    local mason_root="$1"
    local rewritten=0

    if [ ! -d "$mason_root" ]; then
        return 0
    fi

    while IFS= read -r -d '' file; do
        # Only rewrite text files.
        if ! LC_ALL=C grep -Iq . "$file"; then
            continue
        fi
        if ! grep -q '/mason/packages/' "$file"; then
            continue
        fi

        local tmp
        tmp="$(mktemp)"
        local escaped_root="${mason_root//&/\\&}"
        sed -E "s|/[^\"'[:space:]]*/mason/packages/|$escaped_root/packages/|g" "$file" >"$tmp"

        if ! cmp -s "$file" "$tmp"; then
            cat "$tmp" >"$file"
            chmod +x "$file" || true
            rewritten=$((rewritten + 1))
        fi
        rm -f "$tmp"
    done < <(find "$mason_root" -type f -print0)

    info "Rewrote $rewritten Mason file(s) in $mason_root"
}

if ! command -v rsync >/dev/null 2>&1; then
    warn "rsync not found; using cp -a fallback."
    copy_tree() {
        local src="$1"
        local dst="$2"
        rm -rf "$dst"
        mkdir -p "$dst"
        cp -a "$src/." "$dst/"
    }
fi

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
NVIM_DATA="$XDG_DATA_HOME/nvim"

info "Installing offline Neovim bundle..."
echo "    Source : $TARBALL"
echo "    Target : $NVIM_DATA"
echo ""

# ── Extract to temp directory ───────────────────────────────────────────────
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

info "Extracting bundle..."
# Note: Docker tarball creates a flat structure (share/ at root)
tar \
    --no-xattrs \
    --no-acls \
    --no-selinux \
    -xzf "$TARBALL" \
    -C "$TMPDIR"

# [CRITICAL CHANGE]
# The Docker script places 'share' directly in the root of the tarball.
# We no longer look for a 'nvim-offline-bundle' subdirectory.
BUNDLE_DIR="$TMPDIR"

if [ ! -d "$BUNDLE_DIR/share/nvim" ]; then
    error "Invalid bundle structure: 'share/nvim' directory not found."
    echo "    Debug: Extracted contents of $TMPDIR:"
    ls -F "$TMPDIR"
    exit 1
fi

# ── Sanity check: NO AppleDouble files ──────────────────────────────────────
if find "$BUNDLE_DIR" -name '._*' | grep -q .; then
    error "AppleDouble (._*) files detected in bundle. Refusing to install."
    exit 1
fi

# ── Install lazy.nvim plugins ──────────────────────────────────────────────
# Path in bundle: share/nvim/lazy
SOURCE_LAZY="$BUNDLE_DIR/share/nvim/lazy"

if [ -d "$SOURCE_LAZY" ]; then
    PLUGIN_COUNT=$(ls -1 "$SOURCE_LAZY" | wc -l)
    info "Installing $PLUGIN_COUNT plugins..."

    if [ -d "$NVIM_DATA/lazy" ]; then
        warn "Existing lazy/ directory found — backing up to lazy.bak/"
        rm -rf "$NVIM_DATA/lazy.bak"
        mv "$NVIM_DATA/lazy" "$NVIM_DATA/lazy.bak"
    fi

    mkdir -p "$NVIM_DATA"
    copy_tree "$SOURCE_LAZY" "$NVIM_DATA/lazy"
fi

# ── Install Mason packages ─────────────────────────────────────────────────
# Path in bundle: share/nvim/mason
SOURCE_MASON="$BUNDLE_DIR/share/nvim/mason"

if [ -d "$SOURCE_MASON" ]; then
    MASON_COUNT=$(ls -1 "$SOURCE_MASON/packages" 2>/dev/null | wc -l)
    info "Installing $MASON_COUNT Mason packages..."

    if [ -d "$NVIM_DATA/mason" ]; then
        warn "Existing mason/ directory found — backing up to mason.bak/"
        rm -rf "$NVIM_DATA/mason.bak"
        mv "$NVIM_DATA/mason" "$NVIM_DATA/mason.bak"
    fi

    copy_tree "$SOURCE_MASON" "$NVIM_DATA/mason"
    rewrite_mason_paths "$NVIM_DATA/mason"

    if rg -n '/tmp/runtime/share/nvim/mason/packages/' "$NVIM_DATA/mason" -S >/dev/null 2>&1; then
        error "Stale Mason package paths detected after rewrite. Aborting."
        exit 1
    fi
fi

# ── Install lazy-lock.json ─────────────────────────────────────────────────
if [ -f "$BUNDLE_DIR/lazy-lock.json" ] && [ -d "$NVIM_CONFIG" ]; then
    info "Installing lazy-lock.json..."
    cp "$BUNDLE_DIR/lazy-lock.json" "$NVIM_CONFIG/lazy-lock.json"
fi

# ── Final verification ─────────────────────────────────────────────────────
if find "$NVIM_DATA" -name '._*' | grep -q .; then
    error "Post-install AppleDouble files detected. Installation aborted."
    exit 1
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
info "Installation complete!"
echo ""
echo "    Plugins : $NVIM_DATA/lazy/"
echo "    Mason   : $NVIM_DATA/mason/"
echo ""
echo "    ┌─────────────────────────────────────────────────────────┐"
echo "    │  Add the following to your ~/.zshrc or ~/.bashrc:       │"
echo "    │                                                         │"
echo "    │    export NVIM_OFFLINE=1                                │"
echo "    │                                                         │"
echo "    │  Then restart your shell or run: source ~/.zshrc        │"
echo "    └─────────────────────────────────────────────────────────┘"
