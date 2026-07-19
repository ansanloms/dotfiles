# find-docs

ライブラリ・フレームワーク・SDK・API・CLI ツール・クラウドサービスについて質問された際に、Context7 CLI で最新の公式ドキュメントを取得してから回答する skill。

## できること

- API 構文・設定方法・バージョン移行の確認
- ライブラリ固有のデバッグ・セットアップ手順の確認
- CLI ツールの使用方法の確認

React/Next.js/Prisma/Express/Tailwind/Django/Spring Boot 等の著名なものを含む。ライブラリのドキュメントに関しては Web 検索よりこちらを優先する。

## 対象外

- リファクタリング
- ゼロからのスクリプト作成
- ビジネスロジックのデバッグ
- コードレビュー
- 一般的なプログラミング概念の質問

## 発動する場面

特定のライブラリ・ツールの公式ドキュメントに基づいた回答が必要なとき。

## 導入

```sh
apm install ansanloms/skills/find-docs --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
