# draw.io CLI

> 本書の一部は [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) の drawio skill (Apache License 2.0) を翻訳・改変して取り込んだものである。

draw.io Desktop にはコマンドラインインタフェースが同梱されており、Mermaid から `.drawio` への変換、ELK レイアウト (`--layout`) の適用、PNG/SVG/PDF へのエクスポートに使う。いずれも draw.io Desktop 本体のインストールが前提。

## CLI の所在

環境を判定してから CLI を探す。`which drawio` で先に PATH 上の有無を確認する。

- **Linux**: 多くの場合 PATH 上に `drawio` がある (snap/apt/flatpak 経由)。nix 環境では実体が nix store にあり、`which drawio` で得たシンボリックリンクを `readlink -f` で辿る必要がある (後述)。
- **macOS**: `/Applications/draw.io.app/Contents/MacOS/draw.io`
- **WSL2**: `/proc/version` に `microsoft` が含まれるかで判定する (`grep -qi microsoft /proc/version`)。Windows 側の draw.io Desktop を `/mnt/c/...` 経由で使う。既定パスは `/mnt/c/Program Files/draw.io/draw.io.exe`。パスにスペースを含むため二重引用符で囲む (バッククォートで囲むとコマンド置換になり誤動作する)。既定パスに無ければユーザ単位インストール `/mnt/c/Users/$WIN_USER/AppData/Local/Programs/draw.io/draw.io.exe` も確認する。
- **Windows (ネイティブ)**: `"C:\Program Files\draw.io\draw.io.exe"`

nix 環境で `app.asar` や CLI 実体のパスを特定するときは、`which drawio` で得たシンボリックリンクを辿る。

```bash
readlink -f $(which drawio)
```

## エクスポート・変換・レイアウトの共通形

```bash
drawio -x -f <format> [-e] [-b 10] [--layout <name|json>] -o <out> <in> --disable-gpu --no-sandbox
```

主要フラグは次の通り。

| フラグ                         | 意味                                                                                                           |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `-x`, `--export`               | エクスポートモード (非対話的。Mermaid 変換や `--layout` の単独適用にも使う)                                    |
| `-f`, `--format`               | 出力形式 (`xml` / `png` / `svg` / `pdf` / `jpg`)。Mermaid や `--layout` を `.drawio` として出すときも `-f xml` |
| `-e`, `--embed-diagram`        | 出力に drawio XML を埋め込む (PNG/SVG/PDF のみ)                                                                |
| `-o`, `--output`               | 出力先パス                                                                                                     |
| `-b`, `--border`               | 図の周囲の余白 (既定 0)                                                                                        |
| `-t`, `--transparent`          | 透過背景 (PNG のみ)                                                                                            |
| `-s`, `--scale`                | 拡大率                                                                                                         |
| `--width` / `--height`         | 指定サイズに収める (縦横比は保持)                                                                              |
| `-a`, `--all-pages`            | 全ページを出力 (PDF のみ)                                                                                      |
| `-p`, `--page-index`           | 特定ページのみ出力                                                                                             |
| `--layout <name\|json>`        | 出力前にレイアウトを適用する (プリセット名またはカスタム JSON 配列)                                            |
| `--mermaid-image <true/false>` | Mermaid (`.mmd`/`.mermaid`) を編集可能な図ではなく静的画像セルとして開く (既定 false)                          |

本ファイルは CLI が持つ機能の一覧であり、本 skill の成果物運用 (PNG = 確認用、SVG = 成果物) の方針は [export.md](./export.md) が定める。

## ELK による自動レイアウト (`--layout`)

XML で書いた図はおおまかな座標 (`0,0` でもよい) で書き、`--layout` で自動配置させることができる。ノード・エッジの構造さえ正しければ、座標計算は不要になる。

```bash
drawio -x -f xml --layout verticalFlow -o diagram.drawio diagram.drawio
```

エクスポートと同時に指定できる。

```bash
drawio -x -f png -e -b 10 --layout verticalFlow -o diagram.drawio.png diagram.drawio
```

プリセット名は次の通り。

| プリセット       | レイアウト                                              |
| ---------------- | ------------------------------------------------------- |
| `verticalFlow`   | 階層型・上から下へ (フローチャート・パイプライン向け)   |
| `horizontalFlow` | 階層型・左から右へ                                      |
| `verticalTree`   | ツリー型・上から下へ (階層構造・組織図向け)             |
| `horizontalTree` | ツリー型・左から右へ                                    |
| `radialTree`     | 放射状ツリー                                            |
| `organic`        | 力学モデル (ネットワーク・マインドマップ的なグラフ向け) |

より細かく制御したい場合は、プリセット名の代わりに JSON 配列 (`[` で始まる) を渡す。エディタのカスタムレイアウトダイアログと同じ形式。

```bash
drawio -x -f xml --layout '[{"layout":"elkLayered","config":{"elk.direction":"RIGHT"}}]' -o diagram.drawio diagram.drawio
```

各要素は `{"layout": <アルゴリズム>, "config": { … }}`。

- アルゴリズム: `elkLayered`/`elkTree`/`elkRadial`/`elkOrganic`/`elkStress`/`elkBox`
- `config`: `elk.` で始まるキーは ELK のオプション (例: `elk.direction` は `UP`/`DOWN`/`LEFT`/`RIGHT`、`elk.spacing.nodeNode`、`elk.layered.spacing.nodeNodeBetweenLayers`)。`edgeStyle` (例: `orthogonal`) と `corners` (例: `rounded`) はコネクタの見た目を制御する

**本 skill での位置づけ**: コンテナの空間配置に意味がある構成図本体には使わない (ELK が頂点を動かしてしまう)。コンテナ無しの流れ (パイプライン・データフロー概念図) や、構造だけ先に書いて配置を任せたい下書きに使う。

### 実行例 (実測)

手元の環境 (drawio 31.3.1) で、座標を `0,0` に置いた 4 ノード (Users→LB→Web→DB) に `verticalFlow` を適用したところ完走し、ノードは x=12、y=12/82/152/222 に縦並びになり、エッジに `exitX`/`exitY`/`entryX`/`entryY` と `<Array as="points">` が付与された。出力は `<mxfile host="Electron">` ラッパ付きだった。

```bash
drawio -x -f xml --layout verticalFlow --no-sandbox --disable-gpu -o flow-layout.drawio flow.drawio
```

## 直交エッジの障害物回避 (`--layout libavoid`)

`--layout libavoid` は頂点の位置を動かさず、エッジだけを直交ルートで障害物 (他の図形) を避けて再配線するパス。手で配置した XML のコネクタが図形を貫通しているときに使う想定の機能。

**本 skill では使わない。**手元の環境 (drawio 31.3.1、Linux ヘッドレス) で実測したところ、`timeout 300` (5 分) を待っても完走せず、出力ファイルも生成されなかった。

```bash
# 実測: 完走しない (exit 124、出力なし)
drawio -x -f xml --layout libavoid --no-sandbox --disable-gpu -o flow-avoid.drawio flow-layout.drawio
```

エッジの整理は [layout-best-practices.md](./layout-best-practices.md) の手動 waypoint と [readability-checks.md](./readability-checks.md) の幾何チェックで行う。

## Mermaid から `.drawio` への変換

drawio CLI は Mermaid (`.mmd`/`.mermaid`) を読み込んで `.drawio` (mxGraphModel XML) に変換できる。

```bash
drawio -x -f xml -o diagram.drawio diagram.mmd
```

### 実行例 (実測)

次の内容の `t.mmd` を変換したところ完走し、5.1KB の `.drawio` が生成された。ノードは `<UserObject label=... mermaidId=...>` 形式になっていた。

```
flowchart LR
  A[Users] --> B[LB] --> C[Web] --> D[(DB)]
```

```bash
drawio -x -f xml --no-sandbox --disable-gpu -o t-mmd.drawio t.mmd
```

公式の drawio skill によれば、`.mmd` から `-e` 付きで直接 PNG へエクスポートすると現行の draw.io Desktop でクラッシュするとされている (この記述は本環境では未検証)。安全のため、いったん `.drawio` に変換してからエクスポートする 2 段階の経路を使う。

本 skill の対象 (ベンダーアイコン入りの構成図) では Mermaid を使わないが、構成図に添えるフロー図 (概念的なデータの流れ等) を同じ `.drawio` 形式で用意したい場合の手段として利用できる。

## ブラウザ URL 出力 (任意)

`.drawio` の XML を圧縮・base64 エンコードして `https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=...` 形式の URL を作ると、draw.io Desktop 無しでブラウザから直接開ける。本環境では未検証。

```bash
URL=$(node -e '
const fs = require("fs");
const zlib = require("zlib");
const xml = fs.readFileSync(process.argv[1], "utf8");
const compressed = zlib.deflateRawSync(encodeURIComponent(xml)).toString("base64");
const payload = encodeURIComponent(JSON.stringify({ type: "xml", compressed: true, data: compressed }));
console.log("https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=" + payload);
' "diagram.drawio")
```

開き方は環境で異なる。

- **Linux**: `xdg-open "$URL"`
- **macOS**: `open "$URL"`
- **WSL2**: `.url` ファイル経由で `cmd.exe` から開く。`cmd.exe` の `start` は `&` をコマンド区切りとして扱い `#` 以降を切り捨てるため、URL を直接渡すと `#create=...` のペイロードが失われる。一時ファイルを経由させる。

```bash
TMPFILE=$(mktemp --suffix=.url)
printf '[InternetShortcut]\r\nURL=%s\r\n' "$URL" > "$TMPFILE"
cmd.exe /c start "" "$(wslpath -w "$TMPFILE")"
```

URL はハッシュフラグメントに圧縮済みの図全体を埋め込むため、大きな図はブラウザの URL 長上限 (ブラウザにより概ね 32K〜2MB) を超えることがある。超える場合は `.drawio` を出力してローカルで開く方式に切り替える。

## ファイル命名

本 skill のファイル命名規則は [export.md](./export.md) を優先する (`.drawio` = 編集用ソース、`.drawio.svg` = 成果物、`.drawio` は残す)。公式の drawio skill はエクスポート後に中間生成物の `.drawio` を削除する運用だが、本 skill では `.drawio` を残す点が異なる。
