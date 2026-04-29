#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは、現在の Mac にある SSH / AWS の認証情報を Vault に投入する。
# 秘密情報は標準出力に出さず、Vault CLI の file value 機能で読み込ませる。

VAULT_MOUNT="${VAULT_MOUNT:-kv-dotfiles}"
VAULT_PREFIX="${VAULT_PREFIX:-dotfiles/mac}"
SSH_DIR="${SSH_DIR:-$HOME/.ssh}"
AWS_DIR="${AWS_DIR:-$HOME/.aws}"
DRY_RUN=false

usage() {
  cat << 'USAGE'
使い方: scripts/vault-import-local-secrets.sh [--dry-run]

環境変数:
  VAULT_ADDR      Vault の接続先です。例: https://vault.example.internal:8200
  VAULT_MOUNT     KV secrets engine の mount 名です。既定値: kv-dotfiles
  VAULT_PREFIX    投入先の prefix です。既定値: dotfiles/mac
  SSH_DIR         SSH ファイルの読み取り元です。既定値: ~/.ssh
  AWS_DIR         AWS ファイルの読み取り元です。既定値: ~/.aws

投入先:
  <mount> の <prefix>/ssh/config
  <mount> の <prefix>/ssh/keys/<file-name>
  <mount> の <prefix>/ssh/public_keys/<file-name>
  <mount> の <prefix>/aws

事前に `vault login` を済ませてください。
USAGE
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] %q' "$1"
    shift
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
  else
    "$@"
  fi
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

vault_kv_put() {
  local path="$1"
  shift
  if [[ "${DRY_RUN}" == "true" ]]; then
    run vault kv put -mount="${VAULT_MOUNT}" "$(vault_path "${path}")" "$@"
  else
    vault kv put -mount="${VAULT_MOUNT}" "$(vault_path "${path}")" "$@" > /dev/null
  fi
}

is_ssh_private_key() {
  local file="$1"

  [[ -f "${file}" ]] || return 1

  case "$(basename "${file}")" in
    *.pub | known_hosts | known_hosts.old | authorized_keys | config | *.bak | *.xml | .DS_Store)
      return 1
      ;;
  esac

  case "${file}" in
    */config.d/* | */backup/* | */.vscode/*)
      return 1
      ;;
  esac

  if head -n 1 "${file}" | grep -Eq '^(-----BEGIN .*PRIVATE KEY-----|PuTTY-User-Key-File-)'; then
    return 0
  fi

  case "${file}" in
    *.pem | *.ppk)
      return 0
      ;;
  esac

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
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

require_command find
require_command head
require_command grep

if [[ "${DRY_RUN}" != "true" ]]; then
  require_command vault
  if [[ -z "${VAULT_ADDR:-}" ]]; then
    log "VAULT_ADDR が設定されていません。~/.vault.env を作成して読み込むか、環境変数で指定してください。"
    exit 1
  fi
  vault status > /dev/null
fi

if [[ -f "${SSH_DIR}/config" ]]; then
  log "SSH config を Vault に投入します。"
  vault_kv_put ssh/config "config=@${SSH_DIR}/config"
fi

if [[ -d "${SSH_DIR}/config.d" ]]; then
  log "SSH config.d を Vault に投入します。"
  while IFS= read -r -d '' file; do
    local_name="$(basename "${file}")"
    vault_kv_put "ssh/config.d/${local_name}" "content=@${file}"
  done < <(find "${SSH_DIR}/config.d" -maxdepth 1 -type f -name '*.conf' -print0 | sort -z)
fi

log "SSH 秘密鍵を検出して Vault に投入します。"
while IFS= read -r -d '' file; do
  if is_ssh_private_key "${file}"; then
    key_name="$(basename "${file}")"
    file_mode="$(stat -f '%Lp' "${file}")"
    vault_kv_put "ssh/keys/${key_name}" "content=@${file}" "mode=${file_mode}"
  fi
done < <(find "${SSH_DIR}" -maxdepth 1 -type f -print0 | sort -z)

log "SSH 公開鍵を検出して Vault に投入します。"
while IFS= read -r -d '' file; do
  key_name="$(basename "${file}")"
  file_mode="$(stat -f '%Lp' "${file}")"
  vault_kv_put "ssh/public_keys/${key_name}" "content=@${file}" "mode=${file_mode}"
done < <(find "${SSH_DIR}" -maxdepth 1 -type f -name '*.pub' -print0 | sort -z)

aws_args=()
if [[ -f "${AWS_DIR}/config" ]]; then
  aws_args+=("config=@${AWS_DIR}/config")
fi
if [[ -f "${AWS_DIR}/credentials" ]]; then
  aws_args+=("credentials=@${AWS_DIR}/credentials")
fi

if [[ "${#aws_args[@]}" -gt 0 ]]; then
  log "AWS config / credentials を Vault に投入します。"
  vault_kv_put aws "${aws_args[@]}"
fi

log "完了しました。"
