# worktree

メインの worktree (clone 直下) のブランチを切り替えず、別ブランチの作業を隔離 worktree で行うライフサイクルを扱う skill。作成から branch description の維持、マージ後の片付けまでをカバーする。

## できること

ファイルを変更する作業で専用ブランチを新規に切り、隔離 worktree で作業する。main から切られた別ブランチの状態は、メインのブランチを切り替えずに調べられる。

ローカル設定の持ち込みと branch description の設定 (subject + status + todo のテンプレート構成) も扱う。作業の節目 (タスク完了・方針転換・中断・PR 作成) では status と todo を更新する。

マージ報告を受けた後は、worktree とローカルブランチを片付ける。片付けはマージ確認できたものに限る汎用手順である。専用ツールの供給は呼び出し側が担う。

worktree の配置先 (base) の供給・`git status` 非汚染の保証は呼び出し側の責務。この skill は渡された base を使った worktree 操作の手順を担う。

## 対象外

現在いるブランチに対する読み取りだけの調査は対象外である。理由: ブランチを変えないため。

## 発動する場面

ファイルを変更する作業で専用ブランチを切るとき、main から切られた別ブランチを調べるとき、作業の節目で description を更新するとき、マージ済み worktree を片付けるとき。

## 導入

```sh
apm install ansanloms/skills/worktree --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
