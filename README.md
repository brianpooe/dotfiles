# dotfiles

## Neovim Offline Setup (Corporate Proxy)

If you're behind a corporate proxy where Mason, Treesitter, or plugin installs fail, you can pre-download everything on a machine with internet access and deploy offline.

### Prerequisites

On the machine with internet access, make sure you have:

- `nvim` (same version as the target machine)
- `git`, `make`, `gcc` (for telescope-fzf-native, treesitter parsers)
- `node` + `npm` (for Mason JS-based tools: prettier, eslint_d, etc.)
- `python3` + `pip` (for Mason Python-based tools: debugpy, ruff, etc.)
- `cargo` (optional, for blink.cmp fuzzy matcher)

### Step 1: Prepare the bundle (with internet)

```bash
./scripts/nvim-offline-prepare.sh
```

This pre-downloads:

- All lazy.nvim plugins (git clones + build steps)
- All Mason packages (LSP servers, linters, formatters, DAP adapters)
- All Treesitter parsers (compiled .so files)

Output: `scripts/nvim-offline-bundle.tar.gz`

### Step 2: Install the bundle (on the proxy machine)

Transfer the tarball to your corporate machine, then run:

```bash
./scripts/nvim-offline-install.sh nvim-offline-bundle.tar.gz
```

This extracts plugins to `~/.local/share/nvim/lazy/` and Mason packages to `~/.local/share/nvim/mason/`.

### Step 3: Enable offline mode

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
export NVIM_OFFLINE=1
```

Then restart your shell or run `source ~/.zshrc`.

### What offline mode disables

| Component         | Behavior when `NVIM_OFFLINE=1`                          |
| ----------------- | ------------------------------------------------------- |
| **lazy.nvim**     | Disables update checker, sets git timeout to 1s         |
| **Mason**         | Skips `ensure_installed` for LSP servers and tools      |
| **Treesitter**    | Disables `auto_install` for parsers                     |
| **mason-nvim-dap**| Disables `automatic_installation` for debug adapters    |

### Re-enabling network access

To go back to normal (online) mode:

```bash
unset NVIM_OFFLINE
```

Or remove the `export NVIM_OFFLINE=1` line from your shell profile.
