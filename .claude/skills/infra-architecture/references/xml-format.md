# draw.io XML 形式の詳細

> 本書の一部は [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) の drawio skill (Apache License 2.0) を翻訳・改変して取り込んだものである。

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
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

図形やエッジは `<root>` の中に、`<mxCell id="1" parent="0" />` の後ろへ追加していく。

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
- `adaptiveColors`: ダークモード時の自動配色（`auto`/`simple`/`none`/`default`）。任意。詳細は「[ダークモードの色](#ダークモードの色)」を参照

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

> 自動ルーティングに任せるとエッジが重なったり視認性が下がることがある。複数のエッジが同じ経路を通る場合は `<Array as="points">` で経由点を指定して分離する。ただし最初から waypoint を書く必要はない。詳細は [layout-best-practices.md](./layout-best-practices.md) の「エッジのスタイル」を参照。

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
- `fontStyle=0` - フォントスタイル。`1`=太字、`2`=斜体、`4`=下線のビット和で指定する（例: `3`=太字+斜体、`0`=通常）

#### テキスト配置

- `align=center` - 水平方向の配置（`left`, `center`, `right`）
- `verticalAlign=middle` - 垂直方向の配置（`top`, `middle`, `bottom`）
- `labelPosition=center` - ラベルの位置
- `verticalLabelPosition=bottom` - ラベルの垂直位置

#### 角丸

- `rounded=1` - 角丸を有効化（`0` または `1`）。本 skill では既定 `rounded=0`。角丸にする場合は必ず `absoluteArcSize=1;arcSize=<px>` を併記する（詳細は [layout-best-practices.md](./layout-best-practices.md) の「角丸」）
- `arcSize=10` - 角丸の半径。`absoluteArcSize=1` が無いと短辺に対する割合（%）として解釈され、矩形が大きいほど角丸が大きくなる
- `absoluteArcSize=1` - `arcSize` をピクセル絶対値として扱う

#### 回転

- `rotation=45` - 回転角度（度）

#### HTML サポート

- `html=1` - HTML テキストを有効化（`0` または `1`）
- `whiteSpace=wrap` - テキストの折り返し（`wrap`, `nowrap`）

### HTML ラベル

`value` に HTML タグ (`<b>`, `<br>`, `<font>` 等) を含める場合は、必ず `html=1` をスタイルに含める。`html=1` が無いとタグがそのまま文字として表示される。すべてのセルに常に `html=1` を含めておくのがよい (プレーンテキストには影響しない)。

HTML は XML エスケープする: `<` → `&lt;`、`>` → `&gt;`、`&` → `&amp;`、`"` → `&quot;`。

改行は `&#xa;`（`html=0`/`html=1` どちらでも可）または `&lt;br&gt;`（`html=1` のみ）を使う。`\n` はリテラルの `\n` として表示されるため使わない。

ラベル全体を太字・斜体・下線にする場合は `fontStyle` を使う（`1`=太字、`2`=斜体、`4`=下線、ビット和で組み合わせ可）。ラベルの一部だけを装飾する場合は `<b>`/`<i>`/`<u>` タグを使う。同じ装飾を `fontStyle` と HTML タグの両方で指定しない（冗長なうえ、`html=1` を付け忘れるとタグがそのまま表示される）。

### エッジのスタイル

#### エッジのスタイル

| スタイル         | 構文                                       | 用途                                                                         |
| ---------------- | ------------------------------------------ | ---------------------------------------------------------------------------- |
| 直交             | `edgeStyle=orthogonalEdgeStyle`            | フローチャート・構成図・ネットワーク図など、直角のコネクタを使うほとんどの図 |
| 直線             | `edgeStyle` を指定しない                   | UML クラス図・シーケンス図、点と点を直接結ぶ場合                             |
| エンティティ関連 | `edgeStyle=entityRelationEdgeStyle`        | ER 図。両端に垂直なスタブを作る                                              |
| 曲線             | `curved=1`                                 | マインドマップ・非公式な図                                                   |
| エルボー         | `edgeStyle=elbowEdgeStyle;elbow=vertical;` | 単純な 1 屈曲の直線的な流れのみ。ほとんどの場合は直交で足りる                |

図の中でエッジのスタイルを統一する（ER 図なら全エッジ `entityRelationEdgeStyle`、UML クラス図なら直線、構成図・ネットワーク図なら直交、というように図種で 1 つに決める）。

エッジラベルは 1〜3 語程度に短くまとめる（`Yes`、`async`、`reads` 等）。`call`・`register` のような自明な動作を表すだけのラベルは付けない。長い説明はノードのテキストや小さな凡例ノードに移す。

破線・色・太さは図全体で意味を統一する（例: 破線=任意/非同期/推測される関係、のように 1 つの意味に固定する）。複数の意味を混在させる場合は小さな凡例を添える。

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

- `rounded=1` - エッジの曲がり角を丸める（`0` または `1`）。頂点の角丸規則とは別物
- `orthogonalLoop=1` - 直交ループ
- `jettySize=auto` - ジェッティのサイズ

> **CRITICAL**: エッジの `mxCell` は必ず `<mxGeometry relative="1" as="geometry"/>` を子要素として持つ。自己終了タグ（`<mxCell ... edge="1" ... />` のように子要素を持たない形）のエッジは正しく描画されない。

## グループとコンテナ

### コンテナの種類

| 種別                             | style                          | 用途                                                           |
| -------------------------------- | ------------------------------ | -------------------------------------------------------------- |
| **グループ（不可視）**           | `group;`                       | 視覚的な境界が不要な場合。`pointerEvents=0` が自動的に含まれる |
| **スイムレーン（タイトル付き）** | `swimlane;startSize=30;`       | タイトルバーが必要な場合、またはコンテナ自身に接続が必要な場合 |
| **カスタムコンテナ**             | `container=1;pointerEvents=0;` | 任意の形状をコンテナとして使いたい場合                         |

`pointerEvents=0;` はコンテナ自身が接続を横取りしないようにするために必要。コンテナ自身を接続可能にする必要がある場合のみ省略し、その場合は `swimlane` を使う。

### Key rules（コンテナの必須ルール）

- 子セルは `parent=<コンテナ id>` を設定し、座標はコンテナ相対にする
- **コンテナをまたぐエッジは `parent="1"` にする**（コンテナ内に置くとクリップされて正しく表示されない）
- コンテナには原則 `pointerEvents=0` を付ける
- コンテナ自身を接続可能にしたい場合だけ `pointerEvents=0` を省略し、`swimlane` を使う

### グループ化

複数の図形をグループ化するには、親子関係を使用する。

```xml
<mxCell id="group1" value="グループ"
  style="rounded=0;whiteSpace=wrap;html=1;dashed=1;dashPattern=5 5;fillColor=none;fontFamily=Helvetica;fontSize=18;"
  vertex="1" parent="1">
  <mxGeometry x="80" y="80" width="280" height="200" as="geometry" />
</mxCell>

<mxCell id="child1" value="子要素 1"
  style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontFamily=Helvetica;fontSize=18;"
  vertex="1" parent="group1">
  <mxGeometry x="20" y="40" width="120" height="60" as="geometry" />
</mxCell>

<mxCell id="child2" value="子要素 2"
  style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontFamily=Helvetica;fontSize=18;"
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

### 汎用の入れ子コンテナ（provider 非依存）

VPC → Availability Zone → EC2 インスタンス、Datacenter → Rack → Server のように**入れ子になった境界**を表現する場合は、各階層を `swimlane;startSize=24;` のコンテナにする。

- 各コンテナは `swimlane` で `startSize=24`（タイトル領域を上部に確保）
- 子セルは `parent="<コンテナ id>"` を設定し、座標は親コンテナの左上（タイトル領域の下）を原点とした相対座標にする
- **異なるコンテナ間のエッジは `parent="1"` にする**（コンテナの子にするとクリップされる）

```xml
<mxCell id="vpc" value="VPC" style="swimlane;startSize=24;fillColor=#dae8fc;strokeColor=#6c8ebf;html=1;" vertex="1" parent="1">
  <mxGeometry x="0" y="0" width="720" height="360" as="geometry"/>
</mxCell>
<mxCell id="az1" value="AZ us-east-1a" style="swimlane;startSize=24;fillColor=#fff2cc;strokeColor=#d6b656;html=1;" vertex="1" parent="vpc">
  <mxGeometry x="20" y="36" width="320" height="300" as="geometry"/>
</mxCell>
<mxCell id="web1" value="web-1" style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;" vertex="1" parent="az1">
  <mxGeometry x="30" y="40" width="120" height="60" as="geometry"/>
</mxCell>
<mxCell id="db1" value="db-1" style="shape=cylinder3;whiteSpace=wrap;html=1;" vertex="1" parent="az1">
  <mxGeometry x="180" y="40" width="100" height="70" as="geometry"/>
</mxCell>
<mxCell id="az2" value="AZ us-east-1b" style="swimlane;startSize=24;fillColor=#fff2cc;strokeColor=#d6b656;html=1;" vertex="1" parent="vpc">
  <mxGeometry x="360" y="36" width="340" height="300" as="geometry"/>
</mxCell>
<mxCell id="web2" value="web-2" style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;" vertex="1" parent="az2">
  <mxGeometry x="30" y="40" width="120" height="60" as="geometry"/>
</mxCell>
<mxCell id="e1" edge="1" parent="1" source="web1" target="web2" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

AWS の VPC/サブネット表現には `mxgraph.aws4.group` (grIcon 付き) という専用シェイプがあるので、そちらは [aws-architecture.md](./aws-architecture.md) を参照。AWS 以外のライブラリには専用の枠シェイプが無いため、上記の汎用コンテナか、`fillColor`/`strokeColor` を指定した通常の `container=1;pointerEvents=0;` の矩形を使う。

## レイヤー

複数のレイヤーを使用する場合は次のようにする。

```xml
<root>
  <mxCell id="0" />
  <mxCell id="1" parent="0" />
  <mxCell id="layer2" value="Layer 2" parent="0" />
  <mxCell id="shape1" ... parent="1" />
  <mxCell id="shape2" ... parent="layer2" />
</root>
```

- レイヤーは `parent="0"` の `mxCell` で、`vertex` も `edge` も持たない
- 図形をレイヤーに割り当てるには、その図形の `parent` をレイヤーの id にする
- 後に定義したレイヤーほど手前（高い z-order）に描画される
- レイヤーを既定で非表示にするには `visible="0"` を付ける

## タグ

タグはビューアが要素を分類ごとに表示・非表示できる視覚的なフィルタ。レイヤーと異なり 1 つの要素に複数のタグを付けられるため、「critical」「v2」「backend」のような横断的な分類に向く。

タグを使うには `mxCell` を `<object>` で包み、`tags` 属性にスペース区切りで指定する。

```xml
<mxGraphModel>
  <root>
    <mxCell id="0" />
    <mxCell id="1" parent="0" />
    <object id="2" label="Auth Service" tags="critical v2">
      <mxCell style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;" vertex="1" parent="1">
        <mxGeometry x="100" y="100" width="120" height="60" as="geometry" />
      </mxCell>
    </object>
  </root>
</mxGraphModel>
```

- タグには `<object>` ラッパが必須（素の `mxCell` にはタグを付けられない）
- `<object>` の `label` 属性が `mxCell` の `value` の代わりになる
- 表示するタグは draw.io の Edit > Tags で切り替える
- タグは z-order や構造上のグループ化には影響しない、純粋な表示フィルタ

## メタデータ

図形にメタデータ（キー・値のプロパティ）を追加するには、`<object>` 要素が `<mxCell>` を包む形にする。`<object>` は `<mxCell>` の子ではなく親であることに注意する。

`placeholders="1"` を `<object>` に設定すると、`label` の中で `%プロパティ名%` がプロパティ値に置換される。

```xml
<mxGraphModel>
  <root>
    <mxCell id="0" />
    <mxCell id="1" parent="0" />
    <object id="2" label="&lt;b&gt;%component%&lt;/b&gt;&lt;br&gt;Owner: %owner%&lt;br&gt;Status: %status%"
            placeholders="1" component="Auth Service" owner="Team Backend" status="Active">
      <mxCell style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;" vertex="1" parent="1">
        <mxGeometry x="100" y="100" width="160" height="80" as="geometry" />
      </mxCell>
    </object>
  </root>
</mxGraphModel>
```

- カスタムプロパティは `<object>` の属性として書く（例: `component="Auth Service"`）
- `placeholders="1"` で `label` とツールチップ内の `%key%` 置換を有効化する
- HTML 書式を使う場合、`label` は `html=1` のスタイルと組み合わせる
- プレースホルダは階層を上へ辿って解決する（図形自身の属性 → 親コンテナ → レイヤー → ルートの順で最初に見つかったもの）
- 定義済みプレースホルダはカスタムプロパティ無しでも使える: `%id%`/`%width%`/`%height%`/`%date%`/`%time%`/`%timestamp%`/`%page%`/`%pagenumber%`/`%pagecount%`/`%filename%`
- ラベル中でリテラルの `%` を使いたい場合は `%%` と書く
- タグ・メタデータ・プレースホルダは同じ `<object>` に併用できる

## ダークモードの色

draw.io はダークモードの自動レンダリングに対応している。色の挙動はプロパティによって異なる。

- `strokeColor`/`fillColor`/`fontColor` の既定値 `"default"` は、ライトモードでは黒、ダークモードでは白として自動でレンダリングされる
- 明示的に色を指定した場合（例: `fillColor=#DAE8FC`）はライトモード用の色として扱われ、ダークモード用の色は RGB 値を反転（93% で逆色寄りにブレンド）し色相を 180° 回転させて自動計算される
- 両方の色を明示したい場合は `light-dark(ライト色,ダーク色)` 形式を使う（例: `fontColor=light-dark(#7EA6E0,#FF0000)`）

ダークモードの自動配色を有効にするには、`mxGraphModel` に `adaptiveColors="auto"` を付ける。

構成図はベンダーの公式カラーを明示的に使うことが多いため、通常はダークモードの色を気にしなくてよい。

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

## 圧縮形式

draw.io は XML を base64 エンコード + deflate 圧縮して保存することがある。

非圧縮形式で保存するには次のようにする。

1. draw.io で開く
2. 名前を付けて保存
3. 「Compressed」のチェックを外す

## CRITICAL: XML 整形式の要件

### XML コメントを一切書かない

**出力に XML コメント (`<!-- -->`) を一切含めてはならない。**コメントはトークンを浪費するうえパースエラーの原因になり、図の XML に必要な役割を持たない。「ここに図形を追加」のような説明もコメントで書かず、直前の散文か `value` 属性のラベルで表現する。

### 特殊文字のエスケープ

属性値やテキスト内で次の文字はエスケープが必要。

| 文字 | エスケープ |
| ---- | ---------- |
| `&`  | `&amp;`    |
| `<`  | `&lt;`     |
| `>`  | `&gt;`     |
| `"`  | `&quot;`   |

```xml
<mxCell value="A &amp; B" .../>
```

### `id` の一意性

すべての `id` 属性は図の中で一意でなければならない。

## デバッグのヒント

### よくあるエラー

1. ID の重複: すべての `id` 属性は一意でなければならない

2. parent が存在しない: すべての `parent` 属性は有効な ID を参照しなければならない

3. source/target が存在しない: エッジの `source` と `target` は有効な図形の ID を参照しなければならない

4. style の構文エラー: セミコロン区切り、`key=value` 形式。最後のセミコロンは省略可能

## 生成後のチェックリスト

XML を生成したら、出力前に次を確認する（[jgraph/drawio-mcp style-reference.md §15](https://github.com/jgraph/drawio-mcp/blob/main/shared/style-reference.md) の検証項目を日本語化したもの）。

1. 整形式の XML であり、正しくエスケープされているか
2. ルート要素は `<mxfile>` で、`<diagram>` を 1 つ以上含んでいるか
3. 各 `<diagram>` の `id` が一意か
4. `<root>` に `<mxCell id="0"/>` と `<mxCell id="1" parent="0"/>` の両方があるか
5. 図の中で全セルの `id` が一意か
6. `id="0"` を除く全セルが、実在するセルを指す有効な `parent` を持つか
7. コンテンツを持つ各セルが `vertex="1"` か `edge="1"` のどちらか一方だけを持つか（両方は不可）
8. エッジの `source`/`target` が実在する図形 (vertex) の id を指しているか
9. エッジの `mxCell` が自己終了タグでなく、`<mxGeometry relative="1" as="geometry"/>` を子に持つか
10. style 文字列が `key=value;` 形式で、キー・値が有効か
11. 矩形以外の形状に、対応する `perimeter` が指定されているか（必要な場合）
12. `value` 属性内の HTML が正しく XML エスケープされているか
13. 座標系（x は右方向、y は下方向に増加）に沿っており、負の width/height が無いか
14. コンテナの子要素の座標が、コンテナ相対になっているか

## 参考資料

- [draw.io XML format](https://www.drawio.com/doc/faq/diagram-source-edit)
- [draw.io style reference](https://www.drawio.com/doc/faq/drawio-style-reference.html)
- [draw.io XML Schema (XSD)](https://www.drawio.com/assets/mxfile.xsd)
- [mxGraph JavaScript API](https://jgraph.github.io/mxgraph/docs/js-api/files/index-txt.html)
- [draw.io GitHub examples](https://github.com/jgraph/drawio-diagrams)
- [jgraph/drawio-mcp style-reference.md](https://github.com/jgraph/drawio-mcp/blob/main/shared/style-reference.md)
- [jgraph/drawio-mcp xml-reference.md](https://github.com/jgraph/drawio-mcp/blob/main/shared/xml-reference.md)
