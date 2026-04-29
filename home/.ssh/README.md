# SSH

このディレクトリでは、SSH クライアントの共通設定だけを管理します。

コミットしないもの:

- `id_rsa`、`id_ed25519`、`*.pem`、`*.ppk` などの秘密鍵
- `known_hosts`
- `authorized_keys`
- 公開したくないホスト固有の情報

共通で使う SSH 設定は `~/.ssh/config.d/*.conf` として管理します。
端末固有で公開したくない設定は `~/.ssh/config.local` に置きます。
