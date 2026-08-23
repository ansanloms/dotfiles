# draw.io XML 形式の詳細

## 概要

draw.io の内部形式である XML の構造と、各要素・属性の詳細説明。

## 基本構造

```xml
<mxfile host="app.diagrams.net">
  <diagram name="Page-1" id="diagram-id">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="827" pageHeight="1169">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- ここに図形やエッジを追加 -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### トップレベル要素

#### `<mxfile>`

draw.io ファイルのルート要素。

属性は次の通り。

- `host`: エディタのホスト（例: `app.diagrams.net`）
- `modified`: 最終更新日時
- `agent`: エージェント情報
- `version`: バージョン番号

#### `<diagram>`

1 つのページを表す。複数ページの場合は複数の `<diagram>` 要素を含む。

属性は次の通り。

- `name`: ページ名（デフォルト: `Page-1`）
- `id`: ページの一意な ID

#### `<mxGraphModel>`

グラフモデルのルート。

属性は次の通り。

- `dx`, `dy`: ビューポートのオフセット
- `grid`: グリッドの表示（`0` または `1`）
- `gridSize`: グリッドのサイズ（デフォルト: `10`）
- `guides`: ガイドの表示（`0` または `1`）
- `tooltips`: ツールチップの表示（`0` または `1`）
- `connect`: 接続の有効化（`0` または `1`）
- `arrows`: 矢印の表示（`0` または `1`）
- `fold`: 折りたたみの有効化（`0` または `1`）
- `page`: ページの表示（`0` または `1`）
- `pageScale`: ページのスケール（デフォルト: `1`）
- `pageWidth`: ページ幅（デフォルト: `827` = A4）
- `pageHeight`: ページ高さ（デフォルト: `1169` = A4）

### `<root>`

すべての図形とエッジを含むコンテナ。

必須の 2 つのセルは次の通り。

- `id="0"`: レイヤー 0（デフォルトの親）
- `id="1"`: レイヤー 1（デフォルトのレイヤー）

## mxCell 要素

図形（vertex）とエッジ（edge）を表す基本要素。

### 基本属性

```xml
<mxCell
  id="unique_id"
  value="表示テキスト"
  style="..."
  vertex="1"
  parent="parent_id">
  <mxGeometry ... />
</mxCell>
```

#### 必須属性

- `id`: 一意な識別子（文字列）
- `parent`: 親セルの ID（通常は `"1"`）

#### 図形とエッジの区別

- 図形（vertex）は `vertex="1"` を指定する
- エッジ（edge）は `edge="1"` + `source="source_id"` + `target="target_id"` を指定する

#### その他の属性

- `value`: 表示テキスト（HTML 可）
- `style`: スタイル文字列（セミコロン区切り）
- `connectable`: 接続可能か（`0` または `1`）
- `visible`: 表示するか（`0` または `1`）

### mxGeometry 要素

図形やエッジの位置とサイズを定義。

```xml
<mxGeometry x="100" y="200" width="120" height="60" as="geometry" />
```

#### 図形の場合

- `x`, `y`: 絶対座標（親が `id="1"` の場合）
- `width`, `height`: サイズ
- `as="geometry"`: 必須

#### エッジの場合

```xml
<mxGeometry relative="1" as="geometry">
  <mxPoint x="100" y="200" as="sourcePoint" />
  <mxPoint x="300" y="400" as="targetPoint" />
  <Array as="points">
    <mxPoint x="200" y="300" />
  </Array>
</mxGeometry>
```

- `relative="1"`: 相対座標を使用
- `<mxPoint>`: ソースとターゲットの座標
- `<Array as="points">`: 経由点のリスト（エッジが重なる場合や迂回が必要な場合に明示する）

> 自動ルーティングに任せるとエッジが重なったり視認性が下がることがある。複数のエッジが同じ経路を通る場合は `<Array as="points">` で経由点を指定して分離する。

#### ラベルの場合

エッジに付属するラベルは特殊な geometry を持つ。

```xml
<mxGeometry x="0" y="30" relative="1" as="geometry">
  <mxPoint as="offset" />
</mxGeometry>
```

- `relative="1"`: エッジに対する相対位置
- `x`: エッジの長さに対する割合（`-1` から `1`）
- `y`: エッジからの距離（ピクセル）
- `<mxPoint as="offset" />`: オフセット

## style 属性

セミコロン区切りの key=value 形式。

### 基本スタイル

#### 図形の形状

- `shape=rectangle` - 長方形（デフォルト）
- `shape=ellipse` - 楕円
- `shape=rhombus` - 菱形
- `shape=parallelogram` - 平行四辺形
- `shape=hexagon` - 六角形
- `shape=triangle` - 三角形
- `shape=cylinder3` - 円柱（DB 表現に使用）
- `shape=cloud` - 雲

#### 色

- `fillColor=#dae8fc` - 塗りつぶし色（16 進数）
- `strokeColor=#6c8ebf` - 枠線の色
- `gradientColor=#7ea6e0` - グラデーションの色
- `fontColor=#000000` - フォントの色

#### 線のスタイル

- `strokeWidth=2` - 線の太さ
- `dashed=1` - 破線（`0` または `1`）
- `dashPattern=5 5` - 破線のパターン

#### フォント

- `fontFamily=Helvetica` - フォントファミリー
- `fontSize=18` - フォントサイズ
- `fontStyle=0` - フォントスタイル（`0`=通常、`1`=太字、`2`=斜体、`3`=太字+斜体）

#### テキスト配置

- `align=center` - 水平方向の配置（`left`, `center`, `right`）
- `verticalAlign=middle` - 垂直方向の配置（`top`, `middle`, `bottom`）
- `labelPosition=center` - ラベルの位置
- `verticalLabelPosition=bottom` - ラベルの垂直位置

#### 角丸

- `rounded=1` - 角丸を有効化（`0` または `1`）
- `arcSize=10` - 角丸の半径

#### 回転

- `rotation=45` - 回転角度（度）

#### HTML サポート

- `html=1` - HTML テキストを有効化（`0` または `1`）
- `whiteSpace=wrap` - テキストの折り返し（`wrap`, `nowrap`）

### エッジのスタイル

#### エッジのスタイル

- `edgeStyle=orthogonalEdgeStyle` - 直交スタイル
- `edgeStyle=elbowEdgeStyle` - エルボースタイル
- `edgeStyle=segmentEdgeStyle` - セグメントスタイル

#### 矢印

- `startArrow=classic` - 開始矢印
- `endArrow=classic` - 終了矢印
- `startFill=1` - 開始矢印の塗りつぶし（`0` または `1`）
- `endFill=1` - 終了矢印の塗りつぶし（`0` または `1`）

矢印の種類は次の通り。

- `classic` - 古典的な矢印
- `block` - ブロック矢印
- `open` - 開いた矢印
- `diamond` - ダイヤモンド
- `oval` - 楕円
- `none` - なし

#### ルーティング

- `rounded=0` - エッジの角を丸める（`0` または `1`）
- `orthogonalLoop=1` - 直交ループ
- `jettySize=auto` - ジェッティのサイズ

## グループとコンテナ

### コンテナの種類

| 種別                             | style                          | 用途                                                           |
| -------------------------------- | ------------------------------ | -------------------------------------------------------------- |
| **グループ（不可視）**           | `group;`                       | 視覚的な境界が不要な場合。`pointerEvents=0` が自動的に含まれる |
| **スイムレーン（タイトル付き）** | `swimlane;startSize=30;`       | タイトルバーが必要な場合、またはコンテナ自身に接続が必要な場合 |
| **カスタムコンテナ**             | `container=1;pointerEvents=0;` | 任意の形状をコンテナとして使いたい場合                         |

`pointerEvents=0;` はコンテナ自身が接続を横取りしないようにするために必要。コンテナ自身を接続可能にする必要がある場合のみ省略し、その場合は `swimlane` を使う。

### グループ化

複数の図形をグループ化するには、親子関係を使用する。

```xml
<!-- 親（グループ） -->
<mxCell id="group1" value="グループ"
  style="rounded=1;whiteSpace=wrap;html=1;dashed=1;dashPattern=5 5;fillColor=none;fontFamily=Helvetica;fontSize=18;"
  vertex="1" parent="1">
  <mxGeometry x="80" y="80" width="280" height="200" as="geometry" />
</mxCell>

<!-- 子 1 -->
<mxCell id="child1" value="子要素 1"
  style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontFamily=Helvetica;fontSize=18;"
  vertex="1" parent="group1">
  <mxGeometry x="20" y="40" width="120" height="60" as="geometry" />
</mxCell>

<!-- 子 2 -->
<mxCell id="child2" value="子要素 2"
  style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontFamily=Helvetica;fontSize=18;"
  vertex="1" parent="group1">
  <mxGeometry x="140" y="120" width="120" height="60" as="geometry" />
</mxCell>
```

子要素の座標は親に対する相対座標になる。

### コンテナ（スイムレーン）

```xml
<mxCell id="container1"
  style="swimlane;fontStyle=1;childLayout=stackLayout;horizontal=1;startSize=30;horizontalStack=0;resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=1;marginBottom=0;fillColor=#dae8fc;strokeColor=#6c8ebf;fontFamily=Helvetica;fontSize=18;"
  vertex="1" parent="1">
  <mxGeometry x="80" y="80" width="200" height="150" as="geometry" />
</mxCell>
```

重要な属性は次の通り。

> **`pointerEvents=0;`**はコンテナに必須のスタイル。これを付けないとコンテナ自身がクリックやコネクション操作を横取りし、子要素に対するエッジが正しく接続できなくなる。VPC やサブネットなどのグループコンテナには必ず指定する。

- `swimlane` - スイムレーンスタイル
- `childLayout=stackLayout` - 子要素のレイアウト
- `startSize=30` - ヘッダーのサイズ
- `collapsible=1` - 折りたたみ可能

## レイヤー

複数のレイヤーを使用する場合は次のようにする。

```xml
<root>
  <mxCell id="0" />
  <mxCell id="1" parent="0" />
  <mxCell id="layer2" value="Layer 2" parent="0" />

  <!-- レイヤー 1 の図形 -->
  <mxCell id="shape1" ... parent="1" />

  <!-- レイヤー 2 の図形 -->
  <mxCell id="shape2" ... parent="layer2" />
</root>
```

## 接続ポイント

図形の特定の位置に接続するには、接続ポイントを使用する。

```xml
<mxCell id="edge1"
  style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;"
  edge="1" source="source_id" target="target_id" parent="1">
  <mxGeometry relative="1" as="geometry" />
</mxCell>
```

接続ポイントの位置は次の通り。

- `exitX`, `exitY`: 出口の位置（0 から 1）
- `exitDx`, `exitDy`: 出口のオフセット（ピクセル）
- `entryX`, `entryY`: 入口の位置（0 から 1）
- `entryDx`, `entryDy`: 入口のオフセット（ピクセル）

位置の値は次の通り。

- `0` - 左/上
- `0.5` - 中央
- `1` - 右/下

## メタデータ

図形にメタデータを追加する方法は次の通り。

```xml
<mxCell id="shape1" value="図形 1" ... >
  <mxGeometry ... />
  <object label="メタデータ" prop1="value1" prop2="value2" />
</mxCell>
```

## 圧縮形式

draw.io は XML を base64 エンコード + deflate 圧縮して保存することがある。

非圧縮形式で保存するには次のようにする。

1. draw.io で開く
2. 名前を付けて保存
3. 「Compressed」のチェックを外す

## CRITICAL: XML 整形式の要件

### XML コメントに `--` を使用禁止

XML 仕様（XML 1.0 §2.5）により、コメント内でのダブルハイフン（`--`）は禁止されている。draw.io のパースエラーの原因になる。

```xml
<!-- NG: スキーマ -- テーブル定義 -->
<!-- OK: スキーマ / テーブル定義 -->
<!-- OK: スキーマ (テーブル定義) -->
```

### 特殊文字のエスケープ

属性値やテキスト内で次の文字はエスケープが必要。

| 文字 | エスケープ |
| ---- | ---------- |
| `&`  | `&amp;`    |
| `<`  | `&lt;`     |
| `>`  | `&gt;`     |
| `"`  | `&quot;`   |

```xml
<!-- NG -->
<mxCell value="A & B" .../>
<!-- OK -->
<mxCell value="A &amp; B" .../>
```

## デバッグのヒント

### よくあるエラー

1. ID の重複: すべての `id` 属性は一意でなければならない

2. parent が存在しない: すべての `parent` 属性は有効な ID を参照しなければならない

3. source/target が存在しない: エッジの `source` と `target` は有効な図形の ID を参照しなければならない

4. style の構文エラー: セミコロン区切り、`key=value` 形式。最後のセミコロンは省略可能

## 参考資料

- [draw.io XML format](https://www.drawio.com/doc/faq/diagram-source-edit)
- [draw.io style reference](https://www.drawio.com/doc/faq/drawio-style-reference.html)
- [draw.io XML Schema (XSD)](https://www.drawio.com/assets/mxfile.xsd)
- [mxGraph JavaScript API](https://jgraph.github.io/mxgraph/docs/js-api/files/index-txt.html)
- [draw.io GitHub examples](https://github.com/jgraph/drawio-diagrams)
