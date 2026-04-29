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
  "$HOME/.jenv/bin"
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
)

# jenv が未導入の環境だけ、Homebrew で入れた Java を fallback として使う。
if ! command -v jenv >/dev/null 2>&1 && [[ -d /opt/homebrew/opt/openjdk@21 ]]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
  path=("$JAVA_HOME/bin" $path)
fi

# ローカルの秘密情報関連の環境変数。このファイルは git 管理しない。
if [[ -f "$HOME/.vault.env" ]]; then
  source "$HOME/.vault.env"
fi

typeset -U path PATH
