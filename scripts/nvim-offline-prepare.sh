#!/usr/bin/env bash
set -euo pipefail

# nvim-offline-prepare.sh
# =======================
# Spins up a temporary x86_64 Linux container to download/compile ALL Neovim
# dependencies (Lazy, TreeSitter, Mason, blink.cmp) for a Linux target.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
NVIM_CONFIG="$DOTFILES_DIR/.config/nvim"
OUTPUT_DIR="$SCRIPT_DIR/nvim-offline-bundle-output"

# ── Colors & Helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

# ── Checks ──────────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || {
    error "Docker is required but not installed."
    exit 1
}
if ! docker info >/dev/null 2>&1; then
    error "Docker is not running."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
# Clear previous run artifacts
rm -rf "$OUTPUT_DIR/nvim-offline-bundle.tar.gz"

info "Starting Linux container (x86_64) to build offline bundle..."
info "  Source Config : $NVIM_CONFIG"
info "  Output Dir    : $OUTPUT_DIR"

# ── Run Builder Container ───────────────────────────────────────────────────
# We use --platform linux/amd64 to simulate a standard corporate Linux server.
# This ensures binaries (blink.cmp) and parsers (treesitter) are compiled for x86_64.

docker run --rm \
    --platform linux/amd64 \
    -v "$NVIM_CONFIG:/root/.config/nvim:ro" \
    -v "$OUTPUT_DIR:/output" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    ubuntu:22.04 /bin/bash -c '

    set -e

    echo ">> [Container] Installing dependencies..."
    # Install build tools needed for Mason/TreeSitter compilations
    apt-get update -qq && apt-get install -y -qq \
        git curl wget unzip tar gzip build-essential python3 python3-venv nodejs npm \
        >/dev/null

    echo ">> [Container] Fetching Neovim (latest stable)..."
    cd /tmp

    # Robustly fetch the latest tag to avoid "Not Found" errors
    TAG=$(curl -sL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name":' | sed -E "s/.*\"([^\"]+)\".*/\1/")

    if [ -z "$TAG" ]; then
        echo "Error: Could not determine latest Neovim version via GitHub API."
        exit 1
    fi

    echo ">> [Container] Downloading $TAG for x86_64..."
    URL="https://github.com/neovim/neovim/releases/download/${TAG}/nvim-linux64.tar.gz"

    curl -L -o nvim-linux64.tar.gz "$URL"

    # Verify download integrity ( > 1MB )
    FILESIZE=$(stat -c%s nvim-linux64.tar.gz)
    if [ "$FILESIZE" -lt 1000000 ]; then
        echo "Error: Download failed (file too small). URL: $URL"
        cat nvim-linux64.tar.gz
        exit 1
    fi

    tar -xf nvim-linux64.tar.gz
    export PATH="/tmp/nvim-linux64/bin:$PATH"

    # Define isolated XDG paths for the bundle
    export BUNDLE_ROOT="/output/bundle"
    export XDG_DATA_HOME="$BUNDLE_ROOT/share"
    export XDG_STATE_HOME="$BUNDLE_ROOT/state"
    export XDG_CACHE_HOME="$BUNDLE_ROOT/cache"
    export NVIM_OFFLINE_PREPARE=1

    mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

    echo ">> [Container] 1/3 Syncing Lazy plugins..."
    # We bootstrap lazy.nvim manually first
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
        "$XDG_DATA_HOME/nvim/lazy/lazy.nvim" || true

    echo ">> [Container] 2/3 Running Headless Installation..."
    # This runs nvim inside the container to:
    # 1. Download all plugins
    # 2. Compile TreeSitter parsers (generating .so files for Linux)
    # 3. Install Mason tools (downloading Linux binaries)
    nvim --headless \
        -c "lua require(\"lazy\").restore({wait=true})" \
        -c "lua vim.wait(1000)" \
        -c "MasonToolsInstallSync" \
        -c "qa"

    # Verification
    PLUGIN_COUNT=$(find "$XDG_DATA_HOME/nvim/lazy" -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo ">> [Container] Installed $PLUGIN_COUNT plugins."

    # Cleanup junk
    echo ">> [Container] 3/3 Packaging & Cleaning..."
    find "$BUNDLE_ROOT" -name ".git" -type d -exec rm -rf {} +

    # Copy lockfile
    if [ -f /root/.config/nvim/lazy-lock.json ]; then
        cp /root/.config/nvim/lazy-lock.json "$BUNDLE_ROOT/"
    fi

    # Create the Tarball
    cd /output
    tar -czf nvim-offline-bundle.tar.gz -C "$BUNDLE_ROOT" .

    # Fix ownership
    chown "$HOST_UID:$HOST_GID" nvim-offline-bundle.tar.gz

    echo ">> [Container] Done."
'

# ── Summary ─────────────────────────────────────────────────────────────────
TARBALL="$OUTPUT_DIR/nvim-offline-bundle.tar.gz"

if [ -f "$TARBALL" ]; then
    SIZE=$(du -h "$TARBALL" | cut -f1)
    echo ""
    info "Success! Bundle created at:"
    echo "   $TARBALL ($SIZE)"
    echo ""
    echo "   Target Platform: Linux (x86_64)"
else
    error "Docker container finished but tarball was not found."
    exit 1
fi
