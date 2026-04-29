# Vault

このディレクトリでは、Vault クライアント設定の雛形だけを管理します。

コミットしないもの:

- Vault token
- 公開リポジトリに出したくない実際の内部アドレス
- role ID や secret ID
- unseal key や recovery key

ローカルに置く想定のファイル:

- `~/.vault.env`
- `~/.config/vault/config.hcl`

`~/.vault.env` の例:

```zsh
export VAULT_ADDR="https://vault.example.internal:8200"
export VAULT_FORMAT=json
export VAULT_MOUNT=kv-dotfiles
export VAULT_PREFIX=dotfiles/mac
export VAULT_BOOTSTRAP_TOKEN=true
export VAULT_BOOTSTRAP_SSH_HOST=vault01
export VAULT_BOOTSTRAP_ADDR=http://127.0.0.1:8200
export VAULT_BOOTSTRAP_POLICY=dotfiles-mac
export VAULT_BOOTSTRAP_PERIOD=720h
```

## SSH / AWS の投入

現在の Mac にある SSH / AWS の認証情報を Vault に投入する場合は、リポジトリ直下で次を実行します。

```bash
source ~/.vault.env
vault login
scripts/vault-import-local-secrets.sh --dry-run
scripts/vault-import-local-secrets.sh
```

`vault token lookup` が許可されていない policy でも投入できるように、スクリプトは token の自己参照を必須にしていません。権限不足がある場合は、実際の `vault kv put` のタイミングでエラーになります。

既定の投入先は `kv-dotfiles/dotfiles/mac` です。変更したい場合:

```bash
VAULT_MOUNT=kv VAULT_PREFIX=personal/mac scripts/vault-import-local-secrets.sh
```

投入されるもの:

- `~/.ssh/config`
- `~/.ssh/config.d/*.conf`
- `~/.ssh` 直下の秘密鍵らしいファイル
- `~/.ssh` 直下の公開鍵 `*.pub`
- `~/.aws/config`
- `~/.aws/credentials`

投入しないもの:

- `known_hosts`
- `authorized_keys`
- `.ssh/backup/`
- `.ssh/.vscode/`
- FileZilla などのアプリ固有ファイル

## SSH / AWS の復元

Vault に投入済みの SSH / AWS 認証情報を Mac に復元する場合:

```bash
source ~/.vault.env
vault login
scripts/vault-restore-local-secrets.sh --dry-run
scripts/vault-restore-local-secrets.sh
```

`~/.vault-token` が無い、または無効な場合は、既定で `vault01` に SSH して dotfiles 用の限定 token を取得します。自動取得しない場合は `--no-bootstrap-token` を付けます。

復元先:

- `~/.ssh/config`
- `~/.ssh/config.d/*.conf`
- `~/.ssh` 直下の秘密鍵
- `~/.ssh` 直下の公開鍵 `*.pub`
- `~/.aws/config`
- `~/.aws/credentials`

既存ファイルは既定では上書きしません。上書きしたい場合は `--force` を付けます。
