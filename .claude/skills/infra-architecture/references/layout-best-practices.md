# レイアウトとスタイルのベストプラクティス

> 本書の一部は [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) の drawio skill (Apache License 2.0) を翻訳・改変して取り込んだものである。

## フォント設定

日本語テキストを使用する場合、必ず `fontFamily` を明示的に指定する。

```
fontFamily=Helvetica;  ← 推奨（英語と日本語の両方に対応）
```

他の選択肢は次の通り。

- `fontFamily=Arial;`
- `fontFamily=Noto Sans JP;`（日本語フォントがある場合）

## テキストサイズ

フォントサイズの正準値は次の通り。他のリファレンスはこれに従う。

- ノードのラベル (アイコン下に置くラベル等): `fontSize=12;`
- エッジ・コネクタのラベル: `fontSize=12;`
- 図形内に文を収めるボックス: `fontSize=18;`
- タイトル: `fontSize=24;` 以上

PNG 出力時の可読性は `--scale 2` 以上のエクスポートで確保する。小さいフォントでも潰れない。

## 日本語テキストの幅確保

日本語は英語より幅を取るため、十分な `width` を設定する。

- 1 文字あたり 30-40px を目安にする
- 例:「データベース」（6 文字）→ 180-240px

## 角丸

`rounded=1` だけを指定すると `arcSize` の既定が短辺に対する割合（%）で効くため、矩形が大きいほど角丸が比例して大きくなる（実描画で確認: 2026-08-23、drawio 31.3.1。120x60 では小さな角丸、400x300 では半径 40px 超の大きな角丸になった）。`absoluteArcSize=1;arcSize=<px>` を併記すると、サイズによらず指定したピクセル値で固定される（同じ確認で 120x60 でも 400x300 でも半径 8px に固定された）。公式 style-reference の表でも `arcSize` は "Corner radius for rounded shapes (0–50, as percentage)" と割合として定義されている。

本 skill の規則は次の通り。

- 既定は角丸なし（`rounded=0`）。枠（VPC/VNet/Subnet/Namespace/データセンター等の境界コンテナ）は必ず `rounded=0`。AWS の group シェイプが直角なので、混在しても揃う。
- 凡例や汎用ノードなど小さな箱を角丸にしたい場合に限り、`rounded=1;absoluteArcSize=1;arcSize=8;` を必ずセットで書く。`rounded=1` 単独は禁止（サイズに比例して角丸が肥大する）。
- エッジの `rounded=1`（曲がり角の丸め）は別物で、この規則の対象外。

## 図形の配置順序

XML の記述順が描画順になる。重要な原則は次の通り。

1. 矢印（edge）は図形（vertex）の後に配置
2. ラベルは矢印の後に配置

```xml
<mxCell id="source" value="開始" ... />
<mxCell id="target" value="終了" ... />
<mxCell id="arrow1" edge="1" source="source" target="target" ... />
<mxCell id="label1" value="処理" parent="arrow1" ... />
```

## 矢印とラベルの距離

矢印とラベルは**20px 以上**離すこと。重なると視認性が悪くなる。

## エッジのスタイル

まず構造（ノード・エッジ・コンテナ）を確定して XML を書く。waypoint (`<Array as="points">`) と `exitX`/`exitY`/`entryX`/`entryY` は最初から書かず、PNG 目視と幾何チェック（[readability-checks.md](./readability-checks.md)）で問題が出た箇所にだけ足す。座標計算を散文で何度もやり直さない。コンテナ無しの流れ部分は `--layout verticalFlow` 等に任せてよい（[drawio-cli.md](./drawio-cli.md)）。

以下は問題が出たときの処方として使う。

- 直角コネクターには `edgeStyle=orthogonalEdgeStyle` を使用する
- 矢印の直前（ターゲット側）と直後（ソース側）に**20px 以上の直線セグメント**を確保する。不足するとノードとエッジが視覚的に重なる
- `rounded=1` をエッジに付けるとベンドが曲線になり見た目が整う
- `jettySize=auto` で直交エッジのポート間隔を自動調整し、複数エッジの重なりを防ぐ
- ノードが近すぎる・軸が揃っている場合、auto-router がベンドを図形直近に置いてアローヘッドが潰れることがある。ノード間隔を広げるか、明示的な経由点で最終セグメントを 20px 以上確保すること
- エッジが重なる場合は `<Array as="points">` で経由点を明示する
- 1 ノードから複数エッジが出る場合は、各エッジに異なる `exitX`/`exitY` ポートを与え、ラベルはターゲット側の水平セグメントに `labelBackgroundColor=#ffffff` 付きで置く。合流点に複数ラベルを重ねない
- 逆に複数エッジが 1 ノードへ収束する場合、ターゲット側は合流点なので上の規則を適用するとラベルが重なる。収束エッジのラベルは各エッジのソース側セグメントに置く (`x` を負値にしてソース寄りへずらす)

```xml
<mxGeometry relative="1" as="geometry">
  <Array as="points">
    <mxPoint x="200" y="300" />
  </Array>
</mxGeometry>
```

## グリッドとスナップ

- グリッドサイズ: `gridSize="10"`
- 座標は 10 の倍数で配置すると整列しやすい
- ノード間隔の目安: 水平 200px/垂直 120px
- 汎用ノードのサイズの目安: 矩形 140x60/菱形 140x80/円 60x60/円柱 100x70（ベンダーアイコンは各 provider リファレンスの既定サイズに従う）

## 公式 skill の一般原則

- 意味的に正しいシェイプを使う（例: データベースは `shape=cylinder3`、判断は `rhombus`）
- ラベルはユーザの言語に合わせる
- 関連するノードはコンテナにまとめ、外部アクタ（ユーザ・外部システム等）はコンテナの外に置く
- エッジが多数収束する場合は、個々の依存関係を全部引くのではなく、ハブとなるノード（ゲートウェイ・ブローカー等）を置いて経路を集約する
- 副次的な情報はエッジではなくノードのラベルに書く。エッジは関係そのものに意味がある場合にだけ引く
