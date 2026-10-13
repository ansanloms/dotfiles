# infra-architecture

インフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集する skill。

## できること

AWS・Google Cloud・Azure のサービスアイコン、オンプレミス (汎用ネットワーク機器・Cisco・ラック)・Kubernetes のアイコンを用いた、単一クラウド・マルチクラウド・ハイブリッド構成図の XML を生成する。

生成した図は、確認用の PNG と、drawio XML を埋め込んだ編集可能な SVG (`.drawio.svg`, 成果物) にエクスポートできる。

成果物の検証チェックリスト (幾何チェック + PNG 目視) も備える。判定・報告は checklist skill に従い、未導入環境では自己点検へ縮退する。

## 対象外

フローチャート・シーケンス図・ER 図などベンダーアイコン不要の汎用図は対象外で、mermaid 等を使う。

## 発動する場面

インフラ構成図 (アーキテクチャ図) を draw.io 形式で作成・編集する場面。システム構成・インフラ設計・ネットワーク構成・クラスタ構成を図にする場面、構成図の `.drawio` ファイルを操作する場面。

## 導入

```sh
apm install ansanloms/skills/infra-architecture --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。

## 開発

幾何チェックのスクリプト `scripts/check-readability.ts` の開発手順。Node.js 24.2 以上が必要。

```sh
cd scripts
npm ci          # devDependencies (oxlint・oxfmt・typescript) を入れる
npm test        # node --test。fixture は scripts/testdata/
npm run lint    # oxlint・oxfmt --check・tsc --noEmit
npm run fix     # oxlint --fix と oxfmt で整形する
```

## 謝辞・ライセンス

`references/` の一部は [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) の drawio skill (Apache License 2.0) を翻訳・改変して取り込んでいる。該当するのは drawio-cli・xml-format・troubleshooting・layout-best-practices である。
