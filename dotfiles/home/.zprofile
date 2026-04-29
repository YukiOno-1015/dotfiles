# .zshrc から読み込まれたときに PATH が重複しないようにする。
export DOTFILES_ZPROFILE_LOADED=1

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ロケールとエディタ
export EDITOR=vim
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

# ユーザー用 PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
)

# Homebrew で入れた Java
if [[ -d /opt/homebrew/opt/openjdk@21 ]]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
  path=("$JAVA_HOME/bin" $path)
fi

# ローカルの秘密情報関連の環境変数。このファイルは git 管理しない。
if [[ -f "$HOME/.vault.env" ]]; then
  source "$HOME/.vault.env"
fi

typeset -U path PATH
