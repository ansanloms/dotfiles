# 見やすさの幾何チェック

構成図の「見やすさ」を、目視ではなく座標計算で検査する手順。チェッカは [`scripts/check-readability.ts`](../scripts/check-readability.ts)。

## なぜ PNG 目視ではなく幾何チェックか

推奨ワークフローの PNG 目視は「描画が成立しているか」を見る工程であり、見やすさの検証ではない。PNG 目視が拾うのは次のような描画の破綻だ。

- アイコンが空表示になる (resIcon 名の誤り)
- 日本語が豆腐になる (fontFamily 未指定)
- テキストが途切れる
- エッジがノードラベルやエッジラベルの文字を横切る (幾何チェックはラベル文字の矩形を見ないため、これは目視でしか検出できない)

一方、見やすさを損なう次の 4 事象はすべて幾何的性質であり、目視では精度・再現性が出ない。

- 線同士が 2px 重なっているか
- 線と凡例が接触しているか
- 線が無関係なノードを横切っているか
- 線が枠を貫いているか

これらはノード矩形・エッジ経路・枠・凡例の座標から決定論的に判定できる。座標はエクスポート後の SVG に厳密な数値で入っているため、ラスタ化した PNG を読み取るより SVG から直接計算するほうが正確で安定する。PNG 目視 (描画確認) と幾何チェック (見やすさ検証) は別の工程として両方走らせる。

## 4 つの観点

| 観点          | 判定内容                                       | 重大度 |
| :------------ | :--------------------------------------------- | :----- |
| `overlaps`    | エッジ線同士が共線で重なる                     | error  |
| `overlaps`    | エッジ線同士が交差する                         | warn   |
| `legend-hits` | エッジ線が凡例ボックスを横切る                 | error  |
| `node-cross`  | エッジ線が始点・終点でない無関係なノードを貫く | error  |
| `group-cross` | エッジ線が所属しない枠 (VPC/Subnet/帯) を貫く  | error  |

線の交差 (`cross`) を warn に留めるのは、複雑な図では交差を避けきれない場合があるため。共線の重なり (`collinear-overlap`) は線が文字通り上下に重なって 1 本に見える状態であり、error 扱いにする。

## 入力

チェッカは 2 ファイルを取る。役割を分けている。

- `.drawio` (XML): グラフモデル。セルの種別 (edge/vertex/container)、エッジの `source`/`target`、親子関係 (`parent`) を読む。
- `.drawio.svg` または `.svg`: エクスポート後の SVG。auto-router で解決済みの実経路と、ノード・枠・凡例の矩形を `data-cell-id` 付きで読む。

`.drawio` の `mxGeometry` には auto-router が決める折れ曲がりが含まれない。エッジに明示的な経由点 (`<Array as="points">`) を書かない限り、実際の通り道は描画時に計算され XML には残らない。そのため幾何は必ず SVG から取り、`.drawio` はセルの意味づけ (種別・接続・所属) だけに使う。両者はセル id (= SVG の `data-cell-id`) で突き合わせる。

## 実行

```bash
# まず SVG をエクスポートしておく (推奨ワークフローの成果物 SVG をそのまま使える)
drawio -x -f svg -e -o diagram.drawio.svg diagram.drawio --disable-gpu --no-sandbox

# 幾何チェック
deno run --allow-read scripts/check-readability.ts \
  --drawio diagram.drawio --svg diagram.drawio.svg
```

スクリプトは skill 配下の絶対パス、対象ファイルは任意の絶対パスで渡せる。図が skill 外のディレクトリにある場合は両方とも絶対パスで指定する。

```bash
deno run --allow-read <skillの絶対パス>/scripts/check-readability.ts \
  --drawio /path/to/diagram.drawio --svg /path/to/diagram.drawio.svg
```

`scripts/` には `deno.json` があり、そのディレクトリからは task でも呼べる。

```bash
cd scripts
deno task check --drawio ../diagram.drawio --svg ../diagram.drawio.svg
```

オプション。

- `--json`: 指摘を JSON で出力する (件数サマリと findings 配列)。
- `--legend-id <id>`: 凡例セルの id を指定する (既定 `legend`)。凡例ボックスは [aws-architecture.md](./aws-architecture.md) の規約どおり id を `legend` にしておくと既定で拾える。

終了コードは error が 1 件でもあれば 1、無ければ 0。修正は必ず `.drawio` 側で行い、SVG を再エクスポートしてから再度かける。

チェッカ本体・テスト・fixture の開発手順は [README](../README.md) を参照。

## 正当な交差の扱い

幾何は「線が矩形に交わった」までしか言わない。それを欠陥とするかはポリシーで決めており、チェッカには次を組み込んである。

- `node-cross`: エッジの `source`/`target` に当たるノードは除外する。線が自分の端点ノードに接続するのは当然のため。凡例 (`--legend-id`) もノード扱いしない。
- `group-cross`: エッジの `source`/`target` が枠の子孫 (`parent` チェーン) であれば、枠への出入りは正当とみなす。`parent` 化していない帯のような枠については、端点が枠の内側にあれば正当とみなす (幾何判定)。どちらにも該当せず枠を貫く場合だけ指摘する。

## 限界

チェッカが見ないもの・前提にしているもの。

- ラベル文字の幅は見ない。4 観点は線とノード・枠・凡例の関係が対象で、文字のはみ出しは PNG 目視側で確認する。
- 座標変換は drawio export が出す平行移動 (`translate`) のみを想定する。回転・拡大を含む図は対象外。
- エッジ経路は直線セグメント (M/L) のみ解釈する。`rounded=1` の曲線ベンドは角を直線近似する。
- ノード・枠の外形は SVG の最初の図形要素 (rect、または閉じた path の bbox) を本体とみなす。
- 凡例の検出は id 規約 (`legend`) に依存する。異なる id を使う場合は `--legend-id` で渡す。

これらは検査の取りこぼしになりうる。幾何チェックは PNG 目視を置き換えるものではなく、目視では測れない幾何欠陥を機械的に潰すための補完手段として併用する。
