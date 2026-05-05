# .zshrc から読み込まれたときに PATH が重複しないようにする。
export DOTFILES_ZPROFILE_LOADED=1

# Homebrew (macOS と Linuxbrew の両方に対応)
case "$(uname -s)" in
  Darwin)
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    ;;
  Linux)
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
      eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
    ;;
esac

# ロケールとエディタ
export EDITOR=vim
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/python"
export UV_PROJECT_ENVIRONMENT=".venv"

# ユーザー用 PATH
path=(
  "$HOME/.jenv/bin"
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
)

# jenv が未導入の環境だけ、OS ごとの既定 OpenJDK を fallback として使う。
if ! command -v jenv >/dev/null 2>&1; then
  case "$(uname -s)" in
    Darwin)
      [[ -d /opt/homebrew/opt/openjdk@21 ]] && export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
      ;;
    Linux)
      for candidate in \
        /usr/lib/jvm/java-21-openjdk-amd64 \
        /usr/lib/jvm/java-21-openjdk-arm64 \
        /usr/lib/jvm/temurin-21-jdk-amd64 \
        /usr/lib/jvm/temurin-21-jdk-arm64; do
        if [[ -d "$candidate" ]]; then
          export JAVA_HOME="$candidate"
          break
        fi
      done
      ;;
  esac
  if [[ -n "${JAVA_HOME:-}" ]]; then
    path=("$JAVA_HOME/bin" $path)
  fi
fi

# ローカルの秘密情報関連の環境変数。このファイルは git 管理しない。
if [[ -f "$HOME/.vault.env" ]]; then
  source "$HOME/.vault.env"
fi

typeset -U path PATH
