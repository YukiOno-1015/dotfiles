# SSH

このディレクトリでは、SSH クライアントの共通設定だけを管理します。

コミットしないもの:

- `id_rsa`、`id_ed25519`、`*.pem`、`*.ppk` などの秘密鍵
- `known_hosts`
- `authorized_keys`
- 公開したくないホスト固有の情報

共通で使う SSH 設定は `~/.ssh/config.d/*.conf` として管理します。
接続先 IP やユーザー名を含むため `*.conf` は git 管理せず (`.gitignore` 済み)、Vault の `ssh/config.d/*` を正とします。
雛形は `00-example.conf.example` を参照してください。

- 更新後の Vault 反映: `scripts/vault-import-local-secrets.sh`
- 新しい端末への復元: `./install.sh --restore-secrets` (または `scripts/vault-restore-local-secrets.sh`)

端末固有で公開したくない設定は `~/.ssh/config.local` に置きます。
