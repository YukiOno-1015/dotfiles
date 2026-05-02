#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは、Vault に保存した SSH / AWS の認証情報を現在の Mac に復元する。
# 既存ファイルは上書きせず、同名ファイルがある場合はスキップする。

VAULT_MOUNT="${VAULT_MOUNT:-kv-dotfiles}"
VAULT_PREFIX="${VAULT_PREFIX:-dotfiles/mac}"
VAULT_BOOTSTRAP_TOKEN="${VAULT_BOOTSTRAP_TOKEN:-true}"
VAULT_BOOTSTRAP_SSH_HOST="${VAULT_BOOTSTRAP_SSH_HOST:-vault01}"
VAULT_BOOTSTRAP_ADDR="${VAULT_BOOTSTRAP_ADDR:-http://127.0.0.1:8200}"
VAULT_BOOTSTRAP_POLICY="${VAULT_BOOTSTRAP_POLICY:-dotfiles-mac}"
VAULT_BOOTSTRAP_PERIOD="${VAULT_BOOTSTRAP_PERIOD:-720h}"
SSH_DIR="${SSH_DIR:-$HOME/.ssh}"
AWS_DIR="${AWS_DIR:-$HOME/.aws}"
SECRETS_ENV_FILE="${SECRETS_ENV_FILE:-$HOME/.secrets.env}"
DRY_RUN=false
FORCE=false

usage() {
  cat << 'USAGE'
使い方: scripts/vault-restore-local-secrets.sh [--dry-run] [--force]

環境変数:
  VAULT_ADDR      Vault の接続先です。例: http://192.168.100.161:8200
  VAULT_MOUNT     KV secrets engine の mount 名です。既定値: kv-dotfiles
  VAULT_PREFIX    復元元の prefix です。既定値: dotfiles/mac
  VAULT_BOOTSTRAP_TOKEN     token がない場合に SSH 経由で取得するかです。既定値: true
  VAULT_BOOTSTRAP_SSH_HOST  token 発行に使う SSH Host です。既定値: vault01
  VAULT_BOOTSTRAP_ADDR      サーバ上で使う Vault 接続先です。既定値: http://127.0.0.1:8200
  VAULT_BOOTSTRAP_POLICY    発行する token の policy です。既定値: dotfiles-mac
  VAULT_BOOTSTRAP_PERIOD    発行する token の period です。既定値: 720h
  SSH_DIR         SSH ファイルの復元先です。既定値: ~/.ssh
  AWS_DIR         AWS ファイルの復元先です。既定値: ~/.aws
  SECRETS_ENV_FILE  シェル用 secrets env の復元先です。既定値: ~/.secrets.env

オプション:
  --dry-run       ファイルを変更せず、実行内容だけ表示します。
  --force         既存ファイルも上書きします。
  --no-bootstrap-token  SSH 経由の Vault token 取得を行いません。

通常は `~/.vault-token` が無い場合も自動取得します。
USAGE
}

log() {
  printf '%s\n' "$*"
}

require_command() {
  if ! command -v "$1" > /dev/null 2>&1; then
    log "コマンドが見つかりません: $1"
    exit 1
  fi
}

vault_path() {
  printf '%s/%s' "${VAULT_PREFIX}" "$1"
}

vault_list() {
  vault kv list -format=json -mount="${VAULT_MOUNT}" "$(vault_path "$1")" 2> /dev/null |
    tr -d '[]",' |
    awk 'NF { print $1 }'
}

vault_field() {
  local path="$1"
  local field="$2"
  vault kv get -field="${field}" -mount="${VAULT_MOUNT}" "$(vault_path "${path}")"
}

has_vault_token() {
  [[ -f "${HOME}/.vault-token" ]] || return 1
  vault token lookup > /dev/null 2>&1
}

bootstrap_vault_token() {
  local remote_command
  local token_tmp

  if [[ "${VAULT_BOOTSTRAP_TOKEN}" != "true" ]]; then
    log "Vault token が見つからないか無効です。vault login を実行してください。"
    exit 1
  fi

  require_command ssh

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] ${VAULT_BOOTSTRAP_SSH_HOST} から Vault token を取得して ${HOME}/.vault-token に保存します。"
    return
  fi

  remote_command="$(
    printf 'export VAULT_ADDR=%q; vault token create -policy=%q -period=%q -field=token' \
      "${VAULT_BOOTSTRAP_ADDR}" \
      "${VAULT_BOOTSTRAP_POLICY}" \
      "${VAULT_BOOTSTRAP_PERIOD}"
  )"
  token_tmp="${HOME}/.vault-token.tmp.$$"

  log "${VAULT_BOOTSTRAP_SSH_HOST} から Vault token を取得します。"
  # remote_command はローカルで安全に quote 済み。
  # shellcheck disable=SC2029
  if ! ssh "${VAULT_BOOTSTRAP_SSH_HOST}" "${remote_command}" > "${token_tmp}"; then
    rm -f "${token_tmp}"
    log "Vault token の取得に失敗しました。"
    exit 1
  fi

  chmod 600 "${token_tmp}"
  mv "${token_tmp}" "${HOME}/.vault-token"
  log "Vault token を ${HOME}/.vault-token に保存しました。"
}

write_secret_file() {
  local path="$1"
  local field="$2"
  local target="$3"
  local mode="${4:-600}"

  if [[ -e "${target}" && "${FORCE}" != "true" ]]; then
    log "既存のためスキップ: ${target}"
    return
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] 復元: ${path}.${field} -> ${target} (${mode})"
    return
  fi

  mkdir -p "$(dirname "${target}")"
  vault_field "${path}" "${field}" > "${target}"
  chmod "${mode}" "${target}"
  log "復元: ${target}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --force)
      FORCE=true
      ;;
    --no-bootstrap-token)
      VAULT_BOOTSTRAP_TOKEN=false
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

require_command vault
require_command awk
require_command tr

if [[ -z "${VAULT_ADDR:-}" ]]; then
  log "VAULT_ADDR が設定されていません。~/.vault.env を作成して読み込むか、環境変数で指定してください。"
  exit 1
fi

if [[ "${DRY_RUN}" != "true" ]]; then
  if ! has_vault_token; then
    bootstrap_vault_token
  fi
  vault status > /dev/null
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  log "[dry-run] ディレクトリ作成: ${SSH_DIR} (700)"
else
  mkdir -p "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
fi

write_secret_file ssh/config config "${SSH_DIR}/config" 600

while IFS= read -r name; do
  [[ -n "${name}" ]] || continue
  write_secret_file "ssh/config.d/${name}" content "${SSH_DIR}/config.d/${name}" 600
done < <(vault_list ssh/config.d)

while IFS= read -r name; do
  [[ -n "${name}" ]] || continue
  mode="$(vault_field "ssh/keys/${name}" mode 2> /dev/null || printf '600')"
  write_secret_file "ssh/keys/${name}" content "${SSH_DIR}/${name}" "${mode}"
done < <(vault_list ssh/keys)

while IFS= read -r name; do
  [[ -n "${name}" ]] || continue
  mode="$(vault_field "ssh/public_keys/${name}" mode 2> /dev/null || printf '644')"
  write_secret_file "ssh/public_keys/${name}" content "${SSH_DIR}/${name}" "${mode}"
done < <(vault_list ssh/public_keys)

while IFS= read -r name; do
  [[ -n "${name}" ]] || continue
  mode="$(vault_field "ssh/xml/${name}" mode 2> /dev/null || printf '600')"
  write_secret_file "ssh/xml/${name}" content "${SSH_DIR}/${name}" "${mode}"
done < <(vault_list ssh/xml)

if [[ "${DRY_RUN}" == "true" ]]; then
  log "[dry-run] ディレクトリ作成: ${AWS_DIR} (700)"
else
  mkdir -p "${AWS_DIR}"
  chmod 700 "${AWS_DIR}"
fi

write_secret_file aws config "${AWS_DIR}/config" 600
write_secret_file aws credentials "${AWS_DIR}/credentials" 600

if [[ "${DRY_RUN}" == "true" ]] || vault kv get -mount="${VAULT_MOUNT}" "$(vault_path secrets/env)" > /dev/null 2>&1; then
  mode="$(vault_field secrets/env mode 2> /dev/null || printf '600')"
  write_secret_file secrets/env content "${SECRETS_ENV_FILE}" "${mode}"
fi

log "完了しました。"
