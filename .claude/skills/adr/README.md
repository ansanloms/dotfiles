# adr

設計上の決定を ADR (Architecture Decision Record) として `docs/adr/` に記録し、status の遷移で決定のライフサイクルを追うための skill。テンプレートと運用規則 (閾値・採番・遷移・supersede) を供給する。

## できること

- テンプレート (`assets/template.md`) に沿った新規 ADR の起票 (`docs/adr/NNNN-<kebab-case の要約>.md`。配置先は変更可で `docs/adr/` は既定)
- ADR にする閾値の判定 (層の境界・データモデル・外部依存に触れる決定、覆すコストが大きい決定、やらないと決めたこと)
- status の遷移 (proposed から accepted/rejected へ、accepted から deprecated/superseded へ、deprecated から superseded へ) と supersede による決定の置き換え
- 合意済みの決定の遡及起票
- ADR 運用の初回導入 (ADR-0000 の生成)
- 書き上げた ADR のチェックリスト検証 (判定・報告は checklist skill に従い、導入されていない環境では自己点検へ縮退)

## 対象外

- 影響が局所的な決定 (命名規約・フォーマッタ設定等) の記録
- ADR 以外の設計文書・議事録の作成

## 発動する場面

「ADR を書いて」「この決定を記録して」と頼まれたとき、または層の境界・データモデル・外部依存に触れる決定や、スコープの切り捨てを記録する場面。

## 導入

```sh
apm install ansanloms/skills/adr --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
