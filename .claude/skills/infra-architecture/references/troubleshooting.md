# トラブルシューティング

> 本書の一部は [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) の drawio skill (Apache License 2.0) を翻訳・改変して取り込んだものである。

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

## アイコンが表示されない（空表示）

**症状**: `shape=` や `image=` でアイコンを指定したのに描画されず、ラベルだけ表示される。

**原因**: ライブラリ別の style 方言の取り違え（例: GCP に AWS の `resIcon` を使う、Azure の画像パスの大文字小文字違い）や、サービス正式名から推測したステンシル名・画像名が無効（例: 存在しない `mxgraph.aws4.elastic_container_service`）。

**解決策**: 名前を推測せず、インストール済み drawio 本体や shape 索引から有効名を確認してから指定する。手順は [icon-lookup.md](./icon-lookup.md) と各 provider リファレンス (`aws-architecture.md`/`gcp-architecture.md`/`azure-architecture.md`/`generic-infra-architecture.md`) を参照。

```bash
# $ASAR は icon-lookup.md の方法で特定した app.asar のパス
grep -aoE 'resIcon=mxgraph\.aws4\.[a-z0-9_]+' "$ASAR" \
  | sed 's/resIcon=//' | sort -u
```

## `mxgraph.networks.cloud` のラベルが見えない

**症状**: `mxgraph.networks.cloud` (汎用ネットワークの雲アイコン) のラベルが白背景で見えない。

**原因**: sidebar の既定 style が `fontColor=#ffffff` でラベルを雲の中に白文字で描くため。

**解決策**: [generic-infra-architecture.md](./generic-infra-architecture.md) の基本 style（ラベルを下に、`fontColor=#0066CC`）に揃える。

## drawio CLI が見つからない

**症状**: `drawio` コマンドが見つからない、または `which drawio` が失敗する。

**原因**: draw.io Desktop が未導入、または PATH の外にインストールされている。

**解決策**: [drawio-cli.md](./drawio-cli.md) の「CLI の所在」を参照して環境別のパスを確認する。XML の `.drawio` 作成自体は CLI が無くても行える（エクスポートと `--layout` にのみ CLI が必要）。

## エクスポート結果が空・壊れる

**症状**: PNG/SVG/PDF のエクスポート結果が空、または壊れたファイルになる。

**原因**: 入力 XML が整形式でない（XML コメントの混入、未エスケープの特殊文字等）。

**解決策**: [xml-format.md](./xml-format.md) の「生成後のチェックリスト」で入力 XML を確認する。

## 図が開けるが真っ白

**症状**: `.drawio` は開けるが、キャンバスに何も表示されない。

**原因**: ルートセル `id="0"` または `id="1"` が無い。

**解決策**: `<root>` に `<mxCell id="0"/>` と `<mxCell id="1" parent="0"/>` の両方があるか確認する。

## エッジが描画されない

**症状**: `source`/`target` を指定したのに線が表示されない。

**原因**: エッジの `mxCell` が自己終了タグで、`<mxGeometry relative="1" as="geometry"/>` を子要素に持っていない。

**解決策**: エッジは必ず子要素として `<mxGeometry relative="1" as="geometry"/>` を持たせる。

## `--layout` が何もしない / エラー

**症状**: `--layout` を指定してもレイアウトが変わらない、またはエラーになる。

**原因**: プリセット名の誤り、カスタム JSON が配列 (`[` 始まり) になっていない、または drawio Desktop のバージョンが古い（手元の 31.3.1 では動作確認済み）。

**解決策**: [drawio-cli.md](./drawio-cli.md) の「ELK による自動レイアウト」のプリセット表か、`[` で始まる JSON 配列を使う。

## `--layout libavoid` が終わらない

**症状**: `--layout libavoid` が長時間終わらず、出力ファイルも生成されない。

**原因**: 手元の環境（Linux ヘッドレス、drawio 31.3.1）で実測したところ、`timeout 300`（5 分）を待っても完走しなかった。

**解決策**: 本 skill では `--layout libavoid` を使わない。エッジの整理は [layout-best-practices.md](./layout-best-practices.md) の手動 waypoint と [readability-checks.md](./readability-checks.md) の幾何チェックで行う。

## Mermaid から直接 PNG でクラッシュ

**症状**: `.mmd` から `-e` 付きで直接 PNG にエクスポートするとクラッシュする。

**原因**: 公式の drawio skill によれば、現行の draw.io Desktop では Mermaid → PNG (embed 付き) の直接変換が壊れているとされている（この記述は本環境では未検証）。

**解決策**: いったん `.drawio` に変換してからエクスポートする 2 段階の経路を使う。詳細は [drawio-cli.md](./drawio-cli.md) の「Mermaid から `.drawio` への変換」を参照。
