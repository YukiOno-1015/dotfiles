#!/usr/bin/env bash
set -euo pipefail

# nodenv と uv で、普段使う Node.js / Python をまとめてインストールする。

NODE_VERSIONS="${NODE_VERSIONS:-20 22 24}"
NODE_GLOBAL_VERSION="${NODE_GLOBAL_VERSION:-22}"
UV_PYTHON_VERSIONS="${UV_PYTHON_VERSIONS:-3.11 3.12 3.13}"
DRY_RUN=false

usage() {
  cat << 'USAGE'
使い方: scripts/install-runtimes.sh [--dry-run]

環境変数:
  NODE_VERSIONS        nodenv で入れる Node.js バージョンです。既定値: 20 22 24
  NODE_GLOBAL_VERSION  nodenv global に設定する Node.js バージョンです。既定値: 22
  UV_PYTHON_VERSIONS   uv で入れる Python バージョンです。既定値: 3.11 3.12 3.13

Node.js は major / minor 指定の場合、node-build の一覧から最新パッチへ解決します。
例: NODE_VERSIONS="20 22.11 24.0.1"
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

resolve_node_version() {
  local requested="$1"
  local pattern
  local resolved

  if [[ "${requested}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '%s\n' "${requested}"
    return
  fi

  pattern="^${requested//./\\.}(\\.|$)"
  resolved="$(
    nodenv install --list |
      sed 's/^[[:space:]]*//' |
      grep -E "${pattern}" |
      grep -Ev '(-dev|-rc|-beta|-alpha)' |
      tail -n 1
  )"

  if [[ -z "${resolved}" ]]; then
    log "Node.js ${requested} に一致するバージョンが見つかりません。"
    exit 1
  fi

  printf '%s\n' "${resolved}"
}

install_node_versions() {
  local requested
  local resolved
  local global_version

  require_command nodenv

  for requested in ${NODE_VERSIONS}; do
    resolved="$(resolve_node_version "${requested}")"
    log "Node.js ${requested} -> ${resolved} をインストールします。"
    run nodenv install -s "${resolved}"
  done

  run nodenv rehash

  if [[ -n "${NODE_GLOBAL_VERSION}" ]]; then
    global_version="$(resolve_node_version "${NODE_GLOBAL_VERSION}")"
    log "nodenv global を ${global_version} に設定します。"
    run nodenv global "${global_version}"
  fi
}

install_python_versions() {
  local version

  require_command uv

  for version in ${UV_PYTHON_VERSIONS}; do
    log "Python ${version} を uv でインストールします。"
    run uv python install "${version}"
  done
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

install_node_versions
install_python_versions

log "完了しました。"
