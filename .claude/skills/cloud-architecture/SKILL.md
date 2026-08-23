---
name: cloud-architecture
description: >-
  AWS のクラウドインフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集するツール。
  EC2 / RDS / S3 / VPC などの AWS サービスアイコンを用いた構成図を XML で生成し、PNG (確認用) と drawio XML を埋め込んだ編集可能 SVG (.drawio.svg, 成果物) にエクスポートする。
  AWS のシステム構成やインフラ設計を図にする場面、AWS 構成図の .drawio ファイルを操作する場面で使用する。GCP/Azure 等の他クラウドは未対応で、依頼された場合は代替案と拡張パスを案内する (本文参照)。フローチャート・シーケンス図などベンダーアイコン不要の汎用図は対象外 (mermaid 等を使う)。
---

# Cloud Architecture (draw.io) Skills

## 引数

このスキルは引数を受け取らない。呼び出しは `/cloud-architecture` のみで使用する。

## 概要

この Skills は、AWS のクラウドインフラ構成図 (アーキテクチャ図) を draw.io の XML 形式で作成・編集するためのツール。

主な用途は次の通り。

- AWS アーキテクチャ図 (構成図) の作成・編集
- クラウドインフラ設計の図解
- 技術ドキュメント用の AWS 構成図

現時点の対象は AWS のみ。GCP/Azure 等の他クラウドは未対応 (将来 `references/<provider>-architecture.md` とテンプレートを追加して拡張する想定)。

フローチャート・シーケンス図・ER 図など、ベンダーアイコンを必要としない汎用ダイアグラムはこのスキルの対象外。テキストで完結するこれらの図は mermaid 等を使う。

スコープ外の依頼 (GCP/Azure 等の未対応クラウド) を受けたときは、AWS アイコンや汎用図形で代用して描き切らず、未対応である旨を伝えたうえで次の選択肢を案内する: (1) AWS 構成への読み替えなら本スキルで対応可能、(2) ベンダーアイコン不要の汎用図なら mermaid 等、(3) 恒久対応が必要なら `references/<provider>-architecture.md` とテンプレートを追加する拡張。

PNG/SVG エクスポートが必要な場合は draw.io CLI が必要。

## 推奨ワークフロー

1. `.drawio` ファイルを XML 形式で作成 (これが編集用ソース = source of truth)
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

## XML 形式の詳細

mxCell 構造、style 属性、グループ・コンテナ、接続ポイントなど詳細は [xml-format.md](./references/xml-format.md) を参照。

## レイアウトとスタイル

フォント設定、テキストサイズ、日本語幅の確保、図形の配置順序、エッジのルーティングなど詳細は [layout-best-practices.md](./references/layout-best-practices.md) を参照。

## AWS アーキテクチャ図

アイコンスタイル、resIcon 値、カラー、レイアウト原則など詳細は [aws-architecture.md](./references/aws-architecture.md) を参照。

## エクスポート

PNG/SVG の出力コマンド、オプション、使い分けの詳細は [export.md](./references/export.md) を参照。

## 見やすさの検証

線の重なり・凡例被り・無関係ノードの貫通・枠の貫通といった見やすさの欠陥は、PNG 目視ではなく `.drawio` と SVG の座標から幾何的に検査する。チェッカ `scripts/check-readability.ts` の実行方法、4 観点の定義、正当な交差のポリシー、限界は [readability-checks.md](./references/readability-checks.md) を参照。

## トラブルシューティング

詳細は [troubleshooting.md](./references/troubleshooting.md) を参照。

## 参考資料

- `references/xml-format.md` - XML 形式の詳細
- `references/layout-best-practices.md` - フォント・レイアウト・エッジのベストプラクティス
- `references/aws-architecture.md` - AWS アーキテクチャ図のベストプラクティス
- `references/readability-checks.md` - 見やすさの幾何チェック (4 観点・実行方法・限界)
- `references/export.md` - PNG/SVG エクスポートコマンドとオプション
- `references/troubleshooting.md` - よくある問題と解決策
- `scripts/check-readability.ts` - 見やすさの幾何チェッカ (Deno)

## 外部リンク

- [draw.io 公式ドキュメント](https://www.drawio.com/doc/)
- [draw.io XML format](https://www.drawio.com/doc/faq/diagram-source-edit)
- [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
