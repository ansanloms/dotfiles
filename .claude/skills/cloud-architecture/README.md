# cloud-architecture

AWS のクラウドインフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集する skill。

## できること

- EC2/RDS/S3/VPC などの AWS サービスアイコンを用いた構成図を XML で生成
- PNG (確認用) へのエクスポート
- drawio XML を埋め込んだ編集可能な SVG (`.drawio.svg`, 成果物) へのエクスポート

## 対象外

- GCP/Azure 等の他クラウド (依頼された場合は代替案と拡張パスを本文で案内)
- フローチャート・シーケンス図などベンダーアイコン不要の汎用図 (mermaid 等を使う)

## 発動する場面

AWS のシステム構成やインフラ設計を図にする場面、AWS 構成図の `.drawio` ファイルを操作する場面。

## 導入

```sh
apm install ansanloms/skills/cloud-architecture --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
