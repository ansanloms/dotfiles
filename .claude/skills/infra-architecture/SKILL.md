---
name: infra-architecture
description: >-
  インフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集するツール。
  AWS / Google Cloud / Azure の各サービスアイコン、オンプレミスのサーバ・ネットワーク機器・ラック、Kubernetes のアイコンを用いた構成図 (単一クラウド・マルチクラウド・ハイブリッド・オンプレ) を XML で生成し、PNG (確認用) と drawio XML を埋め込んだ編集可能 SVG (.drawio.svg, 成果物) にエクスポートする。
  システム構成・インフラ設計・ネットワーク構成・クラスタ構成を図にする場面、構成図の .drawio ファイルを操作する場面で使用する。フローチャート・シーケンス図・ER 図などベンダーアイコン不要の汎用図は対象外 (mermaid 等を使う)。
---

# Infra Architecture (draw.io) Skills

## 引数

このスキルは引数を受け取らない。呼び出しは `/infra-architecture` のみで使用する。

## 概要

この Skills は、インフラ構成図 (アーキテクチャ図) を draw.io の XML 形式で作成・編集するためのツール。

主な用途は次の通り。

- AWS/Google Cloud/Azure/オンプレミス (汎用ネットワーク機器・Cisco・ラック)/Kubernetes、およびそれらの混在 (ハイブリッド・マルチクラウド) の構成図の作成・編集
- クラウドインフラ設計の図解
- 技術ドキュメント用の構成図

フローチャート・シーケンス図・ER 図など、ベンダーアイコンを必要としない汎用ダイアグラムはこのスキルの対象外。テキストで完結するこれらの図は mermaid 等を使う。

PNG/SVG エクスポートが必要な場合は draw.io CLI が必要。

## 推奨ワークフロー

0. 図に登場する provider を特定し、該当する provider 別リファレンス (下表) を読む。複数 provider が混在する図は該当するものを全部読む
1. `.drawio` ファイルを XML 形式で作成 (これが編集用ソース = source of truth)。コンテナ無しで方向性のある流れだけの部分は `--layout verticalFlow`/`horizontalFlow` で自動配置してもよい (詳細は drawio-cli.md)。構成図本体 (コンテナの空間配置に意味がある) は手で配置する
2. PNG を一時ディレクトリ (例: `/tmp`) に出力して**描画**を確認する (アイコン表示・文字化け・テキスト切れ。確認用。成果物には残さない)
3. SVG にエクスポートし、**見やすさの幾何チェック**を走らせる (線の重なり・凡例被り・無関係ノード貫通・枠貫通)。詳細は [readability-checks.md](./references/readability-checks.md)
4. 手順 2・3 で問題があれば `.drawio` の XML を修正して戻る
5. 完成したら `-e` (`--embed-diagram`) 付きで SVG にエクスポート (成果物): `diagram.drawio.svg`
6. 成果物は `diagram.drawio` (編集用ソース) と `diagram.drawio.svg` (配布用) の両方を残す

手順 2 (PNG 目視) と手順 3 (幾何チェック) は別物として両方走らせる。PNG 目視は「描画が成立しているか」を見る工程で、見やすさそのものは検証しない。線の重なりやノード貫通のような幾何的な見づらさは、ラスタ画像の目視では精度・再現性が出ないため、SVG 座標から決定論的に検査する。

図の修正は必ず `.drawio` 側で行い、再エクスポートして `diagram.drawio.svg` を更新する。`diagram.drawio.svg` を直接編集・Read しない。大半が描画データでトークンを浪費し、手編集しても再エクスポートで上書きされる。

## 使用例

### AWS 構成図 (最小構成)

EC2 と RDS を矢印で繋ぐ最小構成の例。

```xml
<mxfile host="app.diagrams.net">
  <diagram name="example">
    <mxGraphModel>
      <root>
        <mxCell id="0"/><mxCell id="1" parent="0"/>
        <mxCell id="ec2" value="EC2" style="shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;fillColor=#ED7100;strokeColor=#ffffff;aspect=fixed;verticalLabelPosition=bottom;verticalAlign=top;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="1">
          <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
        </mxCell>
        <mxCell id="rds" value="RDS" style="shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.rds;fillColor=#2E73B8;strokeColor=#ffffff;aspect=fixed;verticalLabelPosition=bottom;verticalAlign=top;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="1">
          <mxGeometry x="300" y="100" width="78" height="78" as="geometry"/>
        </mxCell>
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;" edge="1" source="ec2" target="rds" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

他 provider の最小構成例は各 provider リファレンスにある。

## provider 別リファレンス

| 対象                                                                | ライブラリ (style 方言)                                                                    | リファレンス                               |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------ |
| AWS                                                                 | `mxgraph.aws4.resourceIcon` + `resIcon`                                                    | `references/aws-architecture.md`           |
| Google Cloud                                                        | `mxgraph.gcp2.<name>`                                                                      | `references/gcp-architecture.md`           |
| Azure                                                               | `image=img/lib/azure2/<category>/<Name>.svg`                                               | `references/azure-architecture.md`         |
| オンプレ・汎用ネットワーク・Cisco・ラック・Kubernetes・ハイブリッド | `mxgraph.networks.*` / `mxgraph.cisco19.*` / `mxgraph.rack.*` / `mxgraph.kubernetes.icon2` | `references/generic-infra-architecture.md` |

## 構成図の共通原則

粒度 (俯瞰図と詳細図)・コネクタの色と線種・凡例・命名など、provider に依存しない構成図の原則は [architecture-principles.md](./references/architecture-principles.md) を参照。

## XML 形式の詳細

mxCell 構造、style 属性、グループ・コンテナ、接続ポイントなど詳細は [xml-format.md](./references/xml-format.md) を参照。

## レイアウトとスタイル

フォント設定、テキストサイズ、日本語幅の確保、図形の配置順序、エッジのルーティングなど詳細は [layout-best-practices.md](./references/layout-best-practices.md) を参照。

## draw.io CLI

CLI の所在、Mermaid から `.drawio` への変換、`--layout` による自動レイアウト、ブラウザ URL 出力など詳細は [drawio-cli.md](./references/drawio-cli.md) を参照。

## エクスポート

PNG/SVG の出力コマンド、オプション、使い分けの詳細は [export.md](./references/export.md) を参照。

## 見やすさの検証

線の重なり・凡例被り・無関係ノードの貫通・枠の貫通といった見やすさの欠陥は、PNG 目視ではなく `.drawio` と SVG の座標から幾何的に検査する。チェッカ `scripts/check-readability.ts` の実行方法、4 観点の定義、正当な交差のポリシー、限界は [readability-checks.md](./references/readability-checks.md) を参照。

## トラブルシューティング

詳細は [troubleshooting.md](./references/troubleshooting.md) を参照。

## アイコン名の調べ方

ライブラリを横断したアイコン名の調べ方 (app.asar の grep、shape 索引の検索、最終判定の方法) は [icon-lookup.md](./references/icon-lookup.md) を参照。

## 参考資料

- `references/architecture-principles.md` - provider 非依存の構成図の共通原則 (粒度・帯・コネクタの色と線種・凡例・命名)
- `references/xml-format.md` - XML 形式の詳細
- `references/layout-best-practices.md` - フォント・レイアウト・エッジのベストプラクティス
- `references/drawio-cli.md` - draw.io CLI (Mermaid 変換・`--layout`・URL 出力)
- `references/icon-lookup.md` - アイコン名の調べ方 (ライブラリ横断)
- `references/aws-architecture.md` - AWS アーキテクチャ図のベストプラクティス
- `references/gcp-architecture.md` - Google Cloud アーキテクチャ図のベストプラクティス
- `references/azure-architecture.md` - Azure アーキテクチャ図のベストプラクティス
- `references/generic-infra-architecture.md` - オンプレ・汎用ネットワーク・Cisco・ラック・Kubernetes・ハイブリッド構成図のベストプラクティス
- `references/readability-checks.md` - 見やすさの幾何チェック (4 観点・実行方法・限界)
- `references/export.md` - PNG/SVG エクスポートコマンドとオプション
- `references/troubleshooting.md` - よくある問題と解決策
- `scripts/check-readability.ts` - 見やすさの幾何チェッカ (Deno)

## 外部リンク

- [draw.io 公式ドキュメント](https://www.drawio.com/doc/)
- [draw.io XML format](https://www.drawio.com/doc/faq/diagram-source-edit)
- [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
- [Google Cloud アーキテクチャ図のアイコン](https://cloud.google.com/icons)
- [Azure architecture icons](https://learn.microsoft.com/azure/architecture/icons/)
- [jgraph/drawio-mcp (公式 drawio skill)](https://github.com/jgraph/drawio-mcp)

## 謝辞

`references/` の一部 (drawio-cli/xml-format/troubleshooting/layout-best-practices) は jgraph/drawio-mcp の drawio skill (Apache License 2.0) を翻訳・改変して取り込んでいる。
