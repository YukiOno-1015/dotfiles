# dotfiles

Mac の設定ファイルを管理するための dotfiles です。

## 方針

- `home/` 配下のファイルを `$HOME` にシンボリックリンクします。
- 既存ファイルがある場合は `~/.dotfiles-backup/<timestamp>/` に退避します。
- 秘密情報、端末固有の設定、巨大な生成物はコミットしません。

## セットアップ

```bash
cd dotfiles
./install.sh
```

実際に変更せず確認する場合:

```bash
./install.sh --dry-run
```

Vault から SSH / AWS 認証情報も復元する場合:

```bash
./install.sh --restore-secrets
```

既存の SSH / AWS ファイルも上書きして復元する場合:

```bash
./install.sh --restore-secrets --force-secrets
```

Node.js / Python の複数バージョンもまとめてインストールする場合:

```bash
./install.sh --install-runtimes
```

バージョンを指定する場合:

```bash
NODE_VERSIONS="20 22 24" UV_PYTHON_VERSIONS="3.11 3.12 3.13" ./install.sh --install-runtimes
```

## 管理対象

```text
home/
├── .aws/
│   ├── README.md
│   └── config
├── .config/
│   ├── vault/
│   │   ├── README.md
│   │   └── config.hcl.example
│   └── wezterm/
│       ├── keybinds.lua
│       └── wezterm.lua
├── .gitconfig
├── .gitignore_global
├── .hgignore_global
├── .npmrc
├── .profile
├── .ssh/
│   ├── README.md
│   ├── config
│   └── config.d/
│       ├── 00-example.conf.example
│       ├── 10-git.conf
│       ├── 15-jump-host.conf
│       ├── 20-sakura-vpn.conf
│       ├── 30-aws.conf
│       ├── 40-proxmox-k8s-auto.conf
│       └── 90-local-manual.conf
├── .vault.env.example
├── .vimrc
├── .zprofile
└── .zshrc
```

## Vault

Vault の接続先や token はコミットしません。ローカルで `~/.vault.env` を作成して、必要な環境変数だけ置きます。

```bash
cp ~/.vault.env.example ~/.vault.env
vim ~/.vault.env
```

管理するのは `~/.config/vault/config.hcl.example` のような雛形だけです。

現在の SSH / AWS 認証情報を Vault に投入する場合:

```bash
source ~/.vault.env
vault login
scripts/vault-import-local-secrets.sh --dry-run
scripts/vault-import-local-secrets.sh
```

Vault から SSH / AWS 認証情報を復元する場合:

```bash
source ~/.vault.env
scripts/vault-restore-local-secrets.sh --dry-run
scripts/vault-restore-local-secrets.sh
```

`~/.vault-token` が無い、または無効な場合は、既定で `vault01` に SSH して dotfiles 用の限定 token を取得します。自動取得しない場合は `--no-bootstrap-token` を付けます。

既存ファイルも上書きする場合は `--force` を付けます。
`install.sh --restore-secrets` から呼び出すこともできます。

policy で `auth/token/lookup-self` が許可されていなくても動くように、スクリプトは `vault token lookup` を必須にしていません。

既定の投入先は `kv-dotfiles/dotfiles/mac` です。

## Java / jenv

Java の切り替えは `jenv` を使います。`ansible-mac` 側で `jenv` と Homebrew の OpenJDK をインストールし、`jenv add` まで実行します。

dotfiles 側では `~/.jenv/bin` を PATH に追加し、zsh 起動時に `jenv init` を実行します。`jenv` がない環境では fallback として Homebrew の `openjdk@21` を使います。

よく使う alias:

```bash
jv  # jenv versions
jl  # jenv local
jg  # jenv global
```

## Node.js / nodenv

Node.js の切り替えは `nodenv` を使います。`ansible-mac` 側で `nodenv` と `node-build` をインストールします。

dotfiles 側では zsh 起動時に `nodenv init` を実行します。複数バージョンをまとめて入れる場合は `scripts/install-runtimes.sh` または `install.sh --install-runtimes` を使います。

よく使う alias:

```bash
nv  # nodenv versions
nl  # nodenv local
ng  # nodenv global
ni  # nodenv install
nr  # nodenv rehash
```

## Python / uv

Python は `uv` で複数バージョンとプロジェクトごとの `.venv` を扱います。

dotfiles 側では `UV_PYTHON_INSTALL_DIR` と `UV_PROJECT_ENVIRONMENT=.venv` を設定します。複数 Python をまとめて入れる場合は `scripts/install-runtimes.sh` または `install.sh --install-runtimes` を使います。

よく使う alias / function:

```bash
uvp         # uv python list
uvpi        # uv python install
uvs         # uv sync
uvr         # uv run
uvv         # uv venv
uva         # source .venv/bin/activate
uvvenv 3.12 # uv venv --python 3.12 .venv
```

## ファイルを追加する

たとえば `~/.config/example/config.toml` を管理したい場合:

```bash
mkdir -p home/.config/example
cp ~/.config/example/config.toml home/.config/example/config.toml
./install.sh
```

## Ansible から使う場合

隣の `ansible-mac` で Homebrew や macOS 設定を入れたあと、このリポジトリの `install.sh` を実行すると、CLI 環境の設定まで反映できます。

Vault CLI と `~/.vault.env` / `~/.vault-token` がある環境なら、Ansible から `scripts/vault-restore-local-secrets.sh` を呼び出して SSH / AWS 認証情報を復元できます。
dotfiles の展開と同時に復元する場合は、Ansible から `./install.sh --restore-secrets` を呼び出します。
