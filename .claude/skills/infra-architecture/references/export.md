# エクスポート

> [!NOTE]
>
> `--no-sandbox --disable-gpu` を付ければ、ディスプレイの無いヘッドレス環境（Docker / WSL2 など）でも多くの場合そのままレンダリングできる。実行中に標準エラーへ出る GPU / EGL / Vulkan 系の警告は無害な雑音であり、失敗ではない。成否は出力ファイルが生成されたかで判断する。
> `Missing X server or $DISPLAY` エラーで失敗する環境に限り、コマンド先頭に `xvfb-run -a` を付けて仮想ディスプレイで実行する。例: `xvfb-run -a drawio -x -f png ... --disable-gpu --no-sandbox`
> `HOME` が書き込み不可の環境では `HOME` を書き込み可能な一時ディレクトリに向けて実行する。

> [!NOTE]
>
> `--disable-gpu` `--no-sandbox` は必ず末尾に付ける。
> @refs: https://github.com/jgraph/drawio-desktop/issues/1056

## 出力ファイルの規則

- 編集用ソースは `.drawio` (XML)。図の作成・修正はこのファイルに対して行う (source of truth)
- 成果物 SVG は `.drawio.svg` という拡張子で出力する (drawio XML を埋め込んだ編集可能 SVG)
- SVG は `.drawio` と同一ディレクトリに出力する
- 確認用 PNG は中間生成物。一時ディレクトリ (例: `/tmp`) に出力し、成果物ディレクトリには残さない。ファイル名はタスク固有の接頭辞か `mktemp` で一意化する (並行タスクとの衝突を防ぐ)
- `.drawio` は任意の場所・任意のファイル名でよい
- 既存ファイルは上書きする

ファイル名の例を以下に示す。

```
diagram.drawio           # 編集用ソース (source of truth)
diagram.drawio.svg       # 成果物 (drawio XML 埋め込み、単体で再編集可能)
/tmp/diagram.png         # 確認用 (一時ディレクトリ。成果物に残さない)
```

成果物は `.drawio` (編集用ソース) と `.drawio.svg` (配布用) の両方を残す。

> [!IMPORTANT]
>
> 図の修正は必ず `.drawio` 側で行い、再度エクスポートして `.drawio.svg` を更新する。`.drawio.svg` を直接編集・Read してはならない。`.drawio.svg` はファイルの 8 割超が描画データで占められ、直接読むとトークンを浪費するうえ、描画部分を手で編集しても再エクスポートで上書きされる。

## 確認用 PNG の出力

開発中の視覚的確認には PNG を使用する。確認用 PNG は中間生成物なので、一時ディレクトリ (例: `/tmp`) に出力し、成果物ディレクトリには残さない。

```bash
# 確認用 PNG（高解像度）
drawio -x -f png --scale 2.5 --border 10 -o /tmp/diagram.png input.drawio --disable-gpu --no-sandbox

# 透過背景を使用
drawio -x -f png --scale 2.5 --transparent --border 10 -o /tmp/diagram.png input.drawio --disable-gpu --no-sandbox
```

## 成果物用 SVG の出力

ドキュメントに埋め込む最終成果物には SVG を使用する。`-e` (`--embed-diagram`) を付けて drawio XML を埋め込み、`.drawio.svg` という名前で出力する。これにより成果物単体で再編集できる。

次のコマンドを既定とする。

```bash
# 成果物 SVG (既定。drawio XML 埋め込み)
drawio -x -e -f svg --border 10 -o diagram.drawio.svg input.drawio --disable-gpu --no-sandbox
```

次のオプションは必要な場合のみ既定のコマンドに足す。

```bash
# 透過背景が必要な場合は --transparent を足す
drawio -x -e -f svg --transparent --border 10 -o diagram.drawio.svg input.drawio --disable-gpu --no-sandbox

# 特定のページだけ出力する場合は -p で指定する
drawio -x -e -f svg -p 0 --border 10 -o diagram.drawio.svg input.drawio --disable-gpu --no-sandbox
```

`-e` を付けないと描画のみの SVG になり、`.drawio.svg` としての再編集ができない。成果物には必ず `-e` を付ける。

埋め込みの確認は、`.drawio.svg` を Read せずヘッダ部分だけを見る (Read 禁止と両立する検証手順)。

```bash
head -c 2000 diagram.drawio.svg | grep -q 'content="&lt;mxfile' && echo embedded
```

## 主要なオプション

- `-x`: XML モード（非対話的）
- `-e`: drawio XML を SVG/PNG に埋め込む（成果物 SVG では必須。`.drawio.svg` 単体で再編集可能になる）
- `-f png|svg`: 出力形式（PDF も `-e` 付きで埋め込み出力できる。`-f pdf`）
- `--scale 2.5`: 拡大率（PNG のみ）
- `--transparent`: 透過背景
- `--border 10`: ボーダー幅（ピクセル）
- `-p 0`: ページインデックス（0 から始まる）
- `--layout <name|json>`: エクスポート前に自動レイアウトを適用する。詳細は [drawio-cli.md](./drawio-cli.md)

## PNG と SVG の使い分け

### PNG(確認用)

- 高解像度で視覚的に確認しやすい
- 画像ビューアで即座に開ける
- レイアウトの微調整時に便利

### SVG(成果物用)

- ベクター形式なので拡大しても画質が劣化しない
- テキストがそのまま残る
- ドキュメントに埋め込むのに最適
- `-e` 付きで出力すれば drawio XML が埋め込まれ、`.drawio.svg` 単体で drawio.com 等から再編集できる

## drawio CLI のその他の機能

Mermaid から `.drawio` への変換、ELK による自動レイアウト（`--layout`）、ブラウザ URL 出力は [drawio-cli.md](./drawio-cli.md) を参照。

公式の drawio skill はエクスポート後に `.drawio` を削除する運用だが、本 skill では `.drawio`（編集用ソース）を残す。上記「出力ファイルの規則」を参照。
