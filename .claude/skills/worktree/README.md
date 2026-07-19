# worktree

メインの worktree (clone 直下) のブランチを切り替えず、別ブランチの作業を隔離 worktree で行う skill。`git worktree` でチェックアウトし branch description を付ける。

## できること

- ファイルを変更する作業で専用ブランチを新規に切り、隔離 worktree で作業
- main から切られた別ブランチの状態を、メインのブランチを切り替えずに調べる
- ローカル設定の持ち込みと branch description の設定

worktree の配置先 (base) の供給・`git status` 非汚染の保証は呼び出し側の責務。この skill は渡された base を使った worktree 操作の手順を担う。

## 対象外

- 現在いるブランチに対する読み取りだけの調査 (ブランチを変えないため不要)

## 発動する場面

ファイルを変更する作業で専用ブランチを切るとき、または main から切られた別ブランチを調べるとき。

## 導入

```sh
apm install ansanloms/skills/worktree --target claude
```

詳細は [SKILL.md](./SKILL.md) を参照。
