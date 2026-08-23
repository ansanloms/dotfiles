# infra-architecture

インフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集する skill。

## できること

- AWS/Google Cloud/Azure のサービスアイコン、オンプレミス (汎用ネットワーク機器・Cisco・ラック)・Kubernetes のアイコンを用いた構成図 (単一クラウド・マルチクラウド・ハイブリッド) の XML 生成
- PNG (確認用) へのエクスポート
- drawio XML を埋め込んだ編集可能な SVG (`.drawio.svg`, 成果物) へのエクスポート

## 対象外

- フローチャート・シーケンス図・ER 図などベンダーアイコン不要の汎用図 (mermaid 等を使う)

## 発動する場面

インフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集する場面。システム構成・インフラ設計・ネットワーク構成・クラスタ構成を図にする場面、構成図の `.drawio` ファイルを操作する場面。

## 導入

```sh
apm install ansanloms/skills/infra-architecture --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。

## 謝辞・ライセンス

`references/` の一部 (drawio-cli/xml-format/troubleshooting/layout-best-practices) は [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) の drawio skill (Apache License 2.0) を翻訳・改変して取り込んでいる。
