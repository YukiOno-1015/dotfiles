#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${DOTFILES_DIR}/home"
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"
DRY_RUN=false
RESTORE_SECRETS=false
FORCE_SECRETS=false
INSTALL_RUNTIMES=false

usage() {
  cat << 'USAGE'
使い方: ./install.sh [--dry-run] [--restore-secrets] [--force-secrets] [--install-runtimes]

オプション:
  --dry-run           ファイルを変更せず、実行内容だけ表示します。
  --restore-secrets   Vault から SSH / AWS 認証情報を復元します。
  --force-secrets     Vault からの復元時に既存ファイルも上書きします。
  --install-runtimes  nodenv / uv で Node.js / Python をインストールします。
  -h, --help          このヘルプを表示します。
USAGE
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --restore-secrets)
      RESTORE_SECRETS=true
      ;;
    --force-secrets)
      FORCE_SECRETS=true
      RESTORE_SECRETS=true
      ;;
    --install-runtimes)
      INSTALL_RUNTIMES=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      log "不明なオプションです: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ ! -d "${SOURCE_DIR}" ]]; then
  log "元ディレクトリが見つかりません: ${SOURCE_DIR}"
  exit 1
fi

link_file() {
  local source="$1"
  local relative_path="${source#"${SOURCE_DIR}/"}"
  local target="${HOME}/${relative_path}"
  local target_dir
  target_dir="$(dirname "${target}")"

  if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
    log "リンク済み: ${target}"
    return
  fi

  if [[ -e "${target}" || -L "${target}" ]]; then
    local backup_target="${BACKUP_DIR}/${relative_path}"
    log "バックアップ: ${target} -> ${backup_target}"
    run mkdir -p "$(dirname "${backup_target}")"
    run mv "${target}" "${backup_target}"
  fi

  log "リンク作成: ${target} -> ${source}"
  run mkdir -p "${target_dir}"
  run ln -s "${source}" "${target}"
}

while IFS= read -r -d '' file; do
  link_file "${file}"
done < <(find "${SOURCE_DIR}" -type f -print0 | sort -z)

if command -v git > /dev/null 2>&1; then
  log "git core.excludesfile を設定"
  run git config --global core.excludesfile "${HOME}/.gitignore_global"
fi

if command -v jenv > /dev/null 2>&1; then
  log "jenv export plugin を有効化"
  eval "$(jenv init -)" 2>/dev/null || true
  run jenv enable-plugin export || true
fi

if [[ "${INSTALL_RUNTIMES}" == "true" ]]; then
  runtime_script="${DOTFILES_DIR}/scripts/install-runtimes.sh"

  if [[ ! -x "${runtime_script}" ]]; then
    log "ランタイムインストールスクリプトが見つからないか、実行できません: ${runtime_script}"
    exit 1
  fi

  runtime_args=()
  if [[ "${DRY_RUN}" == "true" ]]; then
    runtime_args+=(--dry-run)
  fi

  log "Node.js / Python ランタイムをインストールします。"
  "${runtime_script}" "${runtime_args[@]}"
fi

if [[ "${RESTORE_SECRETS}" == "true" ]]; then
  restore_script="${DOTFILES_DIR}/scripts/vault-restore-local-secrets.sh"

  if [[ ! -x "${restore_script}" ]]; then
    log "Vault 復元スクリプトが見つからないか、実行できません: ${restore_script}"
    exit 1
  fi

  if [[ -f "${HOME}/.vault.env" ]]; then
    # shellcheck disable=SC1091
    source "${HOME}/.vault.env"
  elif [[ -f "${HOME}/.vault.env.example" ]]; then
    log "${HOME}/.vault.env がないため ${HOME}/.vault.env.example を読み込みます。必要に応じて ${HOME}/.vault.env を作成してください。"
    # shellcheck disable=SC1091
    source "${HOME}/.vault.env.example"
  fi

  restore_args=()
  if [[ "${DRY_RUN}" == "true" ]]; then
    restore_args+=(--dry-run)
  fi
  if [[ "${FORCE_SECRETS}" == "true" ]]; then
    restore_args+=(--force)
  fi

  log "Vault から SSH / AWS 認証情報を復元します。"
  "${restore_script}" "${restore_args[@]}"
fi

log "完了しました。"
