#!/usr/bin/env bash
set -euo pipefail

# nvim-offline-prepare.sh
# =======================
# Build an offline Neovim bundle in a temporary Linux x86_64 container.
# The container downloads and compiles all dependencies, then writes only the
# final tarball to the host output directory.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
NVIM_CONFIG="$DOTFILES_DIR/.config/nvim"
OUTPUT_DIR="$SCRIPT_DIR/nvim-offline-bundle-output"
TARBALL_NAME="nvim-offline-bundle.tar.gz"
NVIM_RELEASE_TAG="${NVIM_RELEASE_TAG:-}"
NVIM_PREPARE_TIMEOUT="${NVIM_PREPARE_TIMEOUT:-75m}"
BUILDER_IMAGE="${BUILDER_IMAGE:-ubuntu:24.04}"
ALLOW_EMPTY_MASON="${ALLOW_EMPTY_MASON:-0}"
PREPARE_SKIP_MASON_PACKAGES="${PREPARE_SKIP_MASON_PACKAGES:-}"

# ── Colors & Helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }
format_duration() {
    local total_seconds="$1"
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))
    printf "%02dh:%02dm:%02ds" "$hours" "$minutes" "$seconds"
}

# ── Checks ──────────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || {
    error "Docker is required but not installed."
    exit 1
}
if ! docker info >/dev/null 2>&1; then
    error "Docker is not running."
    exit 1
fi

if [ ! -d "$NVIM_CONFIG" ]; then
    error "Neovim config directory not found: $NVIM_CONFIG"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
# Clear previous run artifacts
rm -f "$OUTPUT_DIR/$TARBALL_NAME"

info "Starting Linux container (x86_64) to build offline bundle..."
info "  Source Config : $NVIM_CONFIG"
info "  Output Dir    : $OUTPUT_DIR"
info "  Docker Image  : $BUILDER_IMAGE"
if [ -n "$NVIM_RELEASE_TAG" ]; then
    info "  Neovim Tag    : $NVIM_RELEASE_TAG"
else
    info "  Neovim Tag    : latest stable"
fi
info "  Nvim Timeout  : $NVIM_PREPARE_TIMEOUT"
if [ "$ALLOW_EMPTY_MASON" = "1" ]; then
    warn "ALLOW_EMPTY_MASON=1 (will not fail if Mason installs 0 packages)"
fi
if [ -n "$PREPARE_SKIP_MASON_PACKAGES" ]; then
    warn "PREPARE_SKIP_MASON_PACKAGES=$PREPARE_SKIP_MASON_PACKAGES"
fi

# ── Run Builder Container ───────────────────────────────────────────────────
# We use --platform linux/amd64 to simulate a standard corporate Linux server.
# This ensures binaries (blink.cmp) and parsers (treesitter) are compiled for x86_64.

PREPARE_STARTED_AT="$(date +%s)"
if ! docker run --rm \
    --platform linux/amd64 \
    -v "$NVIM_CONFIG:/input/nvim:ro" \
    -v "$OUTPUT_DIR:/output" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -e TARBALL_NAME="$TARBALL_NAME" \
    -e NVIM_RELEASE_TAG="$NVIM_RELEASE_TAG" \
    -e NVIM_PREPARE_TIMEOUT="$NVIM_PREPARE_TIMEOUT" \
    -e ALLOW_EMPTY_MASON="$ALLOW_EMPTY_MASON" \
    -e PREPARE_SKIP_MASON_PACKAGES="$PREPARE_SKIP_MASON_PACKAGES" \
    "$BUILDER_IMAGE" /bin/bash -c '

    set -euo pipefail
    NVIM_PREPARE_TIMEOUT="${NVIM_PREPARE_TIMEOUT:-75m}"
    ALLOW_EMPTY_MASON="${ALLOW_EMPTY_MASON:-0}"

    echo ">> [Container] Installing dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    # Build/runtime tools for Lazy, Treesitter, Mason, and common package installers.
    apt-get update -qq && apt-get install -y -qq \
        ca-certificates \
        git \
        curl \
        wget \
        unzip \
        tar \
        gzip \
        jq \
        build-essential \
        python3 \
        python3-venv \
        python3-pip \
        lua5.1 \
        luarocks \
        nodejs \
        npm \
        >/dev/null
    update-ca-certificates >/dev/null 2>&1 || true

    echo ">> [Container] Preparing writable config copy..."
    mkdir -p /tmp/config
    cp -a /input/nvim /tmp/config/nvim
    chmod -R u+rwX /tmp/config/nvim

    echo ">> [Container] Fetching Neovim release..."
    cd /tmp

    if [ -n "${NVIM_RELEASE_TAG:-}" ]; then
        TAG="$NVIM_RELEASE_TAG"
    else
        TAG="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | jq -r .tag_name)"
    fi

    if [ -z "$TAG" ] || [ "$TAG" = "null" ]; then
        echo "Error: Could not determine a Neovim release tag."
        exit 1
    fi

    echo ">> [Container] Downloading $TAG for x86_64..."
    ASSET=""
    for CANDIDATE in nvim-linux-x86_64.tar.gz nvim-linux64.tar.gz; do
        URL="https://github.com/neovim/neovim/releases/download/${TAG}/${CANDIDATE}"
        if curl -fL --retry 3 --retry-delay 2 -o nvim-linux.tar.gz "$URL"; then
            ASSET="$CANDIDATE"
            break
        fi
    done
    if [ -z "$ASSET" ]; then
        echo "Error: Failed to download Neovim archive for tag $TAG."
        exit 1
    fi

    # Verify download integrity ( > 1MB )
    FILESIZE=$(stat -c%s nvim-linux.tar.gz)
    if [ "$FILESIZE" -lt 1000000 ]; then
        echo "Error: Download failed (file too small)."
        cat nvim-linux.tar.gz
        exit 1
    fi

    tar -xf nvim-linux.tar.gz
    NVIM_DIR="${ASSET%.tar.gz}"
    if [ ! -x "/tmp/$NVIM_DIR/bin/nvim" ]; then
        NVIM_DIR="$(find /tmp -maxdepth 1 -type d -name "nvim-linux*" | head -n1 | xargs -r basename)"
    fi
    if [ -z "$NVIM_DIR" ] || [ ! -x "/tmp/$NVIM_DIR/bin/nvim" ]; then
        echo "Error: Neovim binary directory not found after extraction."
        exit 1
    fi
    export PATH="/tmp/$NVIM_DIR/bin:$PATH"

    # Define isolated runtime paths so host files are never added to the bundle.
    export XDG_CONFIG_HOME="/tmp/config"
    export RUNTIME_ROOT="/tmp/runtime"
    export XDG_DATA_HOME="$RUNTIME_ROOT/share"
    export XDG_STATE_HOME="$RUNTIME_ROOT/state"
    export XDG_CACHE_HOME="$RUNTIME_ROOT/cache"
    export NVIM_OFFLINE_PREPARE=1

    mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

    echo ">> [Container] 1/5 Bootstrapping lazy.nvim..."
    # We bootstrap lazy.nvim manually first
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
        "$XDG_DATA_HOME/nvim/lazy/lazy.nvim" || true

    echo ">> [Container] 2/5 Restoring Lazy plugins..."
    if ! timeout "$NVIM_PREPARE_TIMEOUT" nvim --headless \
        -c "set nomore" \
        -c "Lazy! restore" \
        -c "qa!"; then
        echo "Error: Lazy restore failed or timed out after $NVIM_PREPARE_TIMEOUT."
        exit 1
    fi

    echo ">> [Container] 3/5 Building Treesitter parsers..."
    if ! timeout "$NVIM_PREPARE_TIMEOUT" nvim --headless \
        -c "set nomore" \
        -c "TSUpdateSync" \
        -c "qa!"; then
        echo "Error: TSUpdateSync failed or timed out after $NVIM_PREPARE_TIMEOUT."
        exit 1
    fi

    echo ">> [Container] 4/5 Installing Mason tools..."
    if ! timeout "$NVIM_PREPARE_TIMEOUT" nvim --headless \
        -c "set nomore" \
        -c "MasonToolsInstallSync" \
        -c "qa!"; then
        echo "Error: MasonToolsInstallSync failed or timed out after $NVIM_PREPARE_TIMEOUT."
        echo "Tip: retry with NVIM_PREPARE_TIMEOUT=120m if needed."
        exit 1
    fi

    # Verification (safe with pipefail even when directories are missing)
    PLUGIN_COUNT=0
    if [ -d "$XDG_DATA_HOME/nvim/lazy" ]; then
        PLUGIN_COUNT=$(find "$XDG_DATA_HOME/nvim/lazy" -mindepth 1 -maxdepth 1 -type d | wc -l)
    fi

    MASON_COUNT=0
    if [ -d "$XDG_DATA_HOME/nvim/mason/packages" ]; then
        MASON_COUNT=$(find "$XDG_DATA_HOME/nvim/mason/packages" -mindepth 1 -maxdepth 1 -type d | wc -l)
    fi

    echo ">> [Container] Installed $PLUGIN_COUNT plugins and $MASON_COUNT Mason packages."
    if [ "$MASON_COUNT" -eq 0 ]; then
        if [ "$ALLOW_EMPTY_MASON" = "1" ]; then
            echo ">> [Container] WARNING: No Mason packages detected under $XDG_DATA_HOME/nvim/mason/packages."
        else
            echo "Error: No Mason packages were installed. Aborting to avoid an incomplete offline bundle."
            echo "Tip: set ALLOW_EMPTY_MASON=1 only if you intentionally want a plugins-only bundle."
            exit 1
        fi
    fi

    # Cleanup junk
    echo ">> [Container] 5/5 Packaging & Cleaning..."
    BUNDLE_ROOT="/tmp/bundle"
    mkdir -p "$BUNDLE_ROOT"
    cp -a "$XDG_DATA_HOME" "$BUNDLE_ROOT/share"
    find "$BUNDLE_ROOT" -name ".git" -type d -exec rm -rf {} +
    find "$BUNDLE_ROOT" -name "._*" -type f -delete

    # Copy lockfile
    if [ -f "$XDG_CONFIG_HOME/nvim/lazy-lock.json" ]; then
        cp "$XDG_CONFIG_HOME/nvim/lazy-lock.json" "$BUNDLE_ROOT/"
    fi

    # Create the Tarball
    tar --exclude="._*" -czf "/output/$TARBALL_NAME" -C "$BUNDLE_ROOT" .

    # Fix ownership
    chown "$HOST_UID:$HOST_GID" "/output/$TARBALL_NAME"

    echo ">> [Container] Done."
'; then
    PREPARE_ENDED_AT="$(date +%s)"
    PREPARE_ELAPSED="$((PREPARE_ENDED_AT - PREPARE_STARTED_AT))"
    error "Offline prepare container failed after $(format_duration "$PREPARE_ELAPSED"). Review the container logs above."
    exit 1
fi
PREPARE_ENDED_AT="$(date +%s)"
PREPARE_ELAPSED="$((PREPARE_ENDED_AT - PREPARE_STARTED_AT))"

# ── Summary ─────────────────────────────────────────────────────────────────
TARBALL="$OUTPUT_DIR/$TARBALL_NAME"

if [ -f "$TARBALL" ]; then
    SIZE=$(du -h "$TARBALL" | cut -f1)
    echo ""
    info "Success! Bundle created at:"
    echo "   $TARBALL ($SIZE)"
    echo "   Elapsed: $(format_duration "$PREPARE_ELAPSED")"
    echo ""
    echo "   Target Platform: Linux (x86_64)"
else
    error "Docker container finished but tarball was not found."
    exit 1
fi
