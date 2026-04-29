# zsh が非ログインの対話シェルとして起動したときも、ログインシェル用の環境変数を読み込む。
if [[ -f "$HOME/.zprofile" && -z "${DOTFILES_ZPROFILE_LOADED:-}" ]]; then
  source "$HOME/.zprofile"
fi

# nodenv
if command -v nodenv >/dev/null 2>&1; then
  eval "$(nodenv init - zsh)"
fi

# jenv
if command -v jenv >/dev/null 2>&1; then
  eval "$(jenv init - zsh)"
fi

# 履歴
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt append_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt share_history

# 補完
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# プロンプト
autoload -Uz colors
colors
PROMPT='%F{cyan}%n@%m%f:%F{green}%~%f %# '

# エイリアス
alias ll='ls -la'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status --short'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias jv='jenv versions'
alias jl='jenv local'
alias jg='jenv global'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias l='eza --group-directories-first --icons=auto'
  alias la='eza -a --group-directories-first --icons=auto'
  alias ll='eza -la --group-directories-first --git --icons=auto'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
  alias lta='eza --tree --level=2 -a --group-directories-first --icons=auto'
  alias ltl='eza --tree --level=3 -la --group-directories-first --git --icons=auto'
  alias lsd='eza -D --group-directories-first --icons=auto'
  alias lss='eza -la --sort=size --reverse --group-directories-first --git --icons=auto'
  alias lst='eza -la --sort=modified --reverse --group-directories-first --git --icons=auto'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  alias batp='bat --style=plain'
  alias batn='bat --style=numbers'
  alias batl='bat --style=changes,numbers'
  alias batw='bat --show-all'
  alias batdiff='bat --diff'
  alias preview='bat --style=numbers,changes --color=always --line-range=:200'
fi

if command -v vault >/dev/null 2>&1; then
  alias vst='vault status'
  alias vlog='vault login'
  alias vlogout='vault token revoke -self'
  alias vwho='vault token lookup'
  alias vls='vault kv list'
  alias vget='vault kv get'
  alias vput='vault kv put'
fi
