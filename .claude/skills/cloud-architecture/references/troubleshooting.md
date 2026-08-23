# トラブルシューティング

## Docker コンテナで drawio コマンドが動作しない

**症状**: `Missing X server or $DISPLAY` エラーが表示される。

**解決策**: `xvfb-run -a` を使って仮想ディスプレイで実行する。

```bash
xvfb-run -a drawio -x -f png ... --disable-gpu --no-sandbox
```

## 日本語が文字化けする（豆腐表示）

**症状**: PNG/SVG 出力で日本語が四角（豆腐）として表示される。

**解決策**: XML ファイルで `fontFamily=Helvetica;` を明示的に指定する。

## テキストが途切れる

→ `width` を大きくする（日本語は 1 文字 30-40px）。

## 矢印がラベルで隠れる

→ XML の記述順を変更する（矢印 → ラベルの順）。

## AWS アイコンが表示されない（空表示）

**症状**: `shape=mxgraph.aws4.resourceIcon` を指定したのにアイコンが描画されず、ラベルだけ表示される。

**原因**: `resIcon` に無効なステンシル名を指定している（サービス正式名からの推測ミス等。例: 存在しない `mxgraph.aws4.elastic_container_service`）。

**解決策**: インストール済み drawio 本体から有効名を確認してから指定する。`app.asar` の発見方法と合わせて [aws-architecture.md](./aws-architecture.md) の「resIcon 名の正規の取得元」を参照。

```bash
# $ASAR は aws-architecture.md の方法で特定した app.asar のパス
grep -aoE 'resIcon=mxgraph\.aws4\.[a-z0-9_]+' "$ASAR" \
  | sed 's/resIcon=//' | sort -u
```
