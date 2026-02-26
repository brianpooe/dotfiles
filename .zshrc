# Homebrew / Linuxbrew (portable across macOS and Linux/WSL)
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Theme (kanagawa variants: dragon|wave)
# Example: export KANAGAWA_THEME="wave"
export KANAGAWA_THEME="${KANAGAWA_THEME:-wave}"
case "${KANAGAWA_THEME:l}" in
  wave|kanagawa-wave)
    export TMUX_THEME="wave"
    export NVIM_THEME="wave"
    export STARSHIP_THEME="wave"
    export WEZTERM_THEME="wave"
    export STARSHIP_CONFIG="$HOME/.config/starship/starship-wave.toml"
    ;;
  *)
    export TMUX_THEME="dragon"
    export NVIM_THEME="dragon"
    export STARSHIP_THEME="dragon"
    export WEZTERM_THEME="dragon"
    export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
    ;;
esac

# Write a deterministic tmux theme selector file so tmux servers don't depend
# on inherited shell env vars.
export TMUX_THEME_FILE="$HOME/.config/tmux/current-theme.conf"
mkdir -p "$HOME/.config/tmux"
if [ "$TMUX_THEME" = "wave" ]; then
  printf 'source-file %s\n' "$HOME/.config/tmux/wave-theme.conf" >| "$TMUX_THEME_FILE"
else
  printf 'source-file %s\n' "$HOME/.config/tmux/dragon-theme.conf" >| "$TMUX_THEME_FILE"
fi

# Starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zoxide - a better cd command
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Activate syntax highlighting
if command -v brew >/dev/null 2>&1 && [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Disable underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

# Activate autosuggestions
if command -v brew >/dev/null 2>&1 && [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ------------FZF--------------
# Set up fzf key bindings and fuzzy completion
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"

# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "
# -----------------------------

unalias lt 2>/dev/null
lt() {
  local level=${1:-3}
  shift
  eza --tree --all --level "$level" "$@"
}

# aliases
alias weztermconfig="nvim ~/.config/wezterm/wezterm.lua"
alias zshconfig="vim ~/.zshrc"
alias nvimconfig="vim ~/.config/nvim"
alias dev="cd $HOME/Documents"
alias ls="eza --no-filesize --long --color=always --icons=always --no-user"
alias ll="eza -lah --group-directories-first --no-filesize --long --color=always --icons=always --no-user"
alias vim="nvim"
alias crq="cargo run -q"
alias sudo="sudo "
if command -v apt >/dev/null 2>&1; then
  alias update="sudo apt update && sudo apt upgrade -y"
elif command -v brew >/dev/null 2>&1; then
  alias update="brew update && brew upgrade"
fi

if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  tmux attach -t default 2>/dev/null || tmux new -s default
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
  export NVIM_OFFLINE=1
fi
export NVIM_RELEASE_TAG=v0.11.6
export NVIM_PREPARE_TIMEOUT=120m
export BUILDER_IMAGE=ubuntu:24.04
