# Theme (kanagawa variants: dragon|wave)
# Example: export KANAGAWA_THEME="wave"
export KANAGAWA_THEME="wave"
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

# Starship
eval "$(starship init zsh)"

# zoxide - a better cd command
eval "$(zoxide init zsh)"

# Activate syntax highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Disable underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

# Activate autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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

if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  tmux attach -t default 2>/dev/null || tmux new -s default
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NVIM_RELEASE_TAG=v0.11.6
export NVIM_PREPARE_TIMEOUT=120m
export BUILDER_IMAGE=ubuntu:24.04
