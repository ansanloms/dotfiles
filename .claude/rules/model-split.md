# モデル分担 (設計 = Fable / 実装 = implementer subagent)

方針立案・設計・レビューと、手を動かす実装を別モデルへ分担するルール。メインループは Fable で走らせて設計・判断・レビューを担い、ツール呼び出し密度の高い実装作業は implementer subagent (`.claude/agents/implementer.md`、model: sonnet) へ委譲する。

## 背景

- Opus 4.8 には malformed tool-call の既知障害がある ([anthropics/claude-code#62123](https://github.com/anthropics/claude-code/issues/62123) / [#64774](https://github.com/anthropics/claude-code/issues/64774))。発生はモデル固有で、upstream の transcript 調査でも当環境の全数調査 (2026-07、13 件全件 opus-4-8) でも、Sonnet / Fable / opus-4-7 は 0 件。ツール呼び出しが密になる実装工程を Opus 4.8 に載せない。
- Fable を設計・レビュー側に置くのは判断品質のため。実装の実行自体は計画が確定していれば Sonnet で足りる。

## 運用

- 前提: メインセッションは Fable で走らせる (`/model fable` または settings の `model`)。
- MUST: ファイル変更を伴う実装作業は、メインループが直接行わず implementer subagent へ委譲する。
- MUST: 委譲時は自己完結した計画を渡す。目的・対象ファイル・変更内容・制約 (規約等)・検証コマンドを含め、会話の文脈を前提にしない。
- MUST: subagent の完了報告と diff をメインループがレビューする。計画との乖離があれば修正を再委譲する。
- 例外: 数行程度の単純修正 (typo・設定値 1 箇所等) は委譲オーバーヘッドが勝るため、メインループが直接行ってよい。
- コミット・push・PR はメインループの管轄とし、通常の Git 運用に従う。
- 強制力は instruction レベルであり機械的な enforcement は無い。メインループはファイル編集の前に、この分担に反していないか確認する。
