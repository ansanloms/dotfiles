# nvim-remote

呼び出し側から渡された nvim の socket パスを使い、socket 経由 (`nvim --server --remote-tab`/`--remote-send`) でファイル・diff・コマンド出力を nvim へ流し込む skill。

## できること

- nvim でファイルを開く
- 2 ファイル間や `git diff` などの差分を nvim で見せる
- 長文の出力を nvim で見せる

socket の解決 (導出・発見・生存確認・複数時の選択) とフォールバック判断は呼び出し側の責務。この skill は渡された live な socket パスでの操作手順のみを担う。

## 発動する場面

nvim でファイルを開く/diff を見せる/長文出力を見せる際に、呼び出し側から socket パスを受け取って実行するとき。

## 導入

```sh
apm install ansanloms/skills/nvim-remote --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
