# worktree

メインの worktree (clone 直下) のブランチを切り替えず、別ブランチの作業を隔離 worktree で行うライフサイクルを扱う skill。作成から branch description の維持、マージ後の片付けまでをカバーする。

## できること

- ファイルを変更する作業で専用ブランチを新規に切り、隔離 worktree で作業
- main から切られた別ブランチの状態を、メインのブランチを切り替えずに調べる
- ローカル設定の持ち込みと branch description の設定 (subject + status + todo のテンプレート構成)
- 作業の節目 (タスク完了・方針転換・中断・PR 作成) での status と todo の更新
- マージ報告を受けた後の worktree とローカルブランチの片付け (マージ確認できたものに限る汎用手順。専用ツールの供給は呼び出し側)

worktree の配置先 (base) の供給・`git status` 非汚染の保証は呼び出し側の責務。この skill は渡された base を使った worktree 操作の手順を担う。

## 対象外

- 現在いるブランチに対する読み取りだけの調査。理由: ブランチを変えないため。

## 発動する場面

ファイルを変更する作業で専用ブランチを切るとき、main から切られた別ブランチを調べるとき、作業の節目で description を更新するとき、マージ済み worktree を片付けるとき。

## 導入

```sh
apm install ansanloms/skills/worktree --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
