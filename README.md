# dotfiles

## Windows + WSL Sync (No Stow)

If you use manual copy/paste on Windows, you can sync configs automatically with:

`scripts/sync-windows-wsl-dotfiles.ps1`

This script runs in Windows PowerShell and syncs:

- `nvim`, `tmux`, `starship` -> `\\wsl.localhost\<distro>\home\<user>\.config`
- `.zshrc` -> `\\wsl.localhost\<distro>\home\<user>\.zshrc`
- `.config/.vimrc` -> `\\wsl.localhost\<distro>\home\<user>\.vimrc`
- `.config/wezterm/wezterm.lua` -> Windows WezTerm config path

### Run From Windows PowerShell

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu-24.04\home\<user>\dotfiles\scripts\sync-windows-wsl-dotfiles.ps1" -Distro "Ubuntu-24.04" -WslUser "<user>" -WindowsWeztermPath "C:\Users\<user>\wezterm.lua" -DryRun
```

Apply:

```powershell
powershell -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu-24.04\home\<user>\dotfiles\scripts\sync-windows-wsl-dotfiles.ps1" -Distro "Ubuntu-24.04" -WslUser "<user>" -WindowsWeztermPath "C:\Users\<user>\wezterm.lua"
```

Notes:

- `-WslUser` can be omitted; the script auto-detects it from WSL.
- `-WindowsWeztermPath` can be omitted; the script defaults to `%USERPROFILE%\.wezterm.lua` (or `%USERPROFILE%\wezterm.lua` if that exists and `.wezterm.lua` does not).

## Neovim Offline Setup (Corporate Proxy)

If you're behind a corporate proxy where Mason, Treesitter, or plugin installs fail, you can pre-download everything on a machine with internet access and deploy offline.

### Prerequisites

On the machine with internet access, make sure you have:

- Docker (Linux containers enabled)

### Step 1: Prepare the bundle (with internet)

```bash
./scripts/nvim-offline-prepare.sh
```

Optionally pin Neovim to a specific tag:

```bash
NVIM_RELEASE_TAG=v0.11.6 ./scripts/nvim-offline-prepare.sh
```

This pre-downloads:

- All lazy.nvim plugins (git clones + build steps)
- All Mason packages (LSP servers, linters, formatters, DAP adapters)
- All Treesitter parsers (compiled .so files)

Output: `scripts/nvim-offline-bundle-output/nvim-offline-bundle.tar.gz`

### Step 2: Install the bundle (on the proxy machine)

Transfer the tarball to your corporate machine, then run:

```bash
./scripts/nvim-offline-install.sh ./scripts/nvim-offline-bundle-output/nvim-offline-bundle.tar.gz
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
