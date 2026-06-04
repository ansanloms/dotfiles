---
name: nvim-remote
description: zellij + nvim 環境で socket 経由 (nvim --server --remote-tab / --remote-send) にファイル・diff・コマンド出力を隣ペインの nvim へ流し込む具体手順。nvim でファイルを開く / diff を見せる / 長文出力を見せる際に使用する。
---

# nvim 遠隔操作 (socket 経由)

zellij セッション内で起動している nvim は `/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock` で listen している (`~/.config/zellij/layouts/default.kdl` 参照)。この socket 経由で nvim を遠隔操作し、作業結果を隣ペインの nvim に流し込む。

## 前提の確認

nvim 手順に進む前に socket の存在を確認する。これは「nvim を使うか / 使わずにコンソール出力へフォールバックするか」を決めるゲートで、手順を選ぶ前に 1 度だけ行う。下記の各手順 (ファイル / diff / 出力結果) は socket 実在を前提に書いてあるので、ゲートの内側に入れ子にする必要はない。

```sh
sock="/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock"
if [ -S "$sock" ]; then
  : # socket あり: 下記の該当手順 (ファイル / diff / 出力結果) を実行する
else
  : # socket なし: 下記カテゴリ別フォールバックを行い、nvim 手順は実行しない
fi
```

守るべき不変条件は **「socket 不在時に `nvim --server` を実行しないこと」の 1 点** のみ。上の `if` に該当手順を入れ子で書いても、不成立時に early return / `exit` してから手順を地続きに書いてもよい。形は問わず、この不変条件さえ守ればよい。

- MUST: socket がある場合のみ下記の該当手順を実行する。
- MUST: socket がない場合は nvim 手順を一切実行せず、見せようとしていた内容を nvim を使わずに出力する (フォールバック)。出力先は通常どおりユーザに見える経路 (エージェントの応答 / シェル stdout 等) でよい。エラー扱いにはせず、中身は手順カテゴリに対応させる:
  - ファイル / 長文出力 → 内容をそのままコンソールへ (`cat <file>`、または手元の文字列をそのまま出力)
  - 2 ファイル間 diff → `diff -u <base> <compare>` の結果を出す
  - 差分文字列 (`git diff` 等) → その差分文字列をそのまま出力
- MUST NOT: `[ -S "$sock" ] || { echo ...; }` のように検出だけで後続の nvim 手順を止めない書き方にしない。socket 不在のまま `nvim --server` を叩くことになる。

## ファイルを nvim で開く

```sh
nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote-tab <filepath>
```

## diff を nvim で開く

先にどちらの手順かを選ぶ: 2 つのファイルパスが具体的にある (「A と B を並べて」等) なら「2 ファイル間の diff」、`git diff` 等のコマンドが吐く差分文字列を見せるなら「差分文字列そのものを見せる」。

### 2 ファイル間の diff

基準ファイル (base、例: リファクタ前・変更前) を `--remote-tab` で新規タブに開き、続けて比較ファイル (compare、例: リファクタ後・変更後) を `diffsplit` で重ねる。`<Esc>` を前置して insert mode の影響を避ける。

- base = 先に `--remote-tab` で開く側。compare = 後から `diffsplit` で重ねる側。左右どちらに並ぶかは nvim 側の `splitright` 設定に従う (位置に依存した指示は書かない。どちらが base かは statusline のファイル名で判別する)。
- ユーザ文の語との対応: 旧 / before / 変更前 / リファクタ前 → base、新 / after / 変更後 / リファクタ後 → compare。
- 両ファイルとも絶対パスで渡す (理由は「注意事項」参照)。

```sh
sock="/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock"
base="$(realpath <旧・基準ファイル>)"
compare="$(realpath <新・比較ファイル>)"
nvim --server "$sock" --remote-tab "$base"
nvim --server "$sock" --remote-send '<Esc>:vert diffsplit '"$compare"'<CR>'
```

### 差分文字列そのものを見せる

`git diff` 等の差分文字列は一時ファイルに書き出してから開く。拡張子 `.diff` で filetype が自動判定される。

```sh
tmp=$(mktemp --suffix=.diff)
git diff > "$tmp"
nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote-tab "$tmp"
```

## 出力結果を nvim で開く

コマンド実行結果や調査結果等、長文の出力は一時ファイルに書き出して `--remote-tab` で開く。

- MUST: 拡張子は内容に合わせる (`.md` / `.log` / `.json` / `.txt` 等)。filetype 判定が効く。
- MUST NOT: 一時ファイルを削除しない。nvim 側で開いている間に消えると参照できなくなる。

```sh
tmp=$(mktemp --suffix=.md)
<command> > "$tmp"                                   # コマンド出力を流す場合
# 文字列が手元にある場合: printf '%s\n' "$var" > "$tmp"  (echo ではなく printf。-e 解釈や先頭ハイフン事故を避ける)
nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote-tab "$tmp"
```

## 注意事項

- MUST: ファイルを開く際は `--remote` ではなく `--remote-tab` を使用する。ユーザが編集中のバッファを上書きしない為、必ず新規タブに開く。
- MUST: nvim に渡すファイルパスは絶対パスにする。`--remote-tab` / `diffsplit` のパス解決基準は受け取る nvim 側の cwd であり、エージェント側の cwd と一致する保証がない。相対パスで来たら `realpath <path>` 等で絶対パスへ解決してから渡す (`mktemp` が返すパスは元から絶対なのでそのままでよい)。
- `--remote-send` で送るキーシーケンスは nvim 記法 (`<Esc>` / `<CR>` 等) を使用する。
- nvim が insert mode 等にいる可能性を考慮し、Ex コマンド送信前には `<Esc>` を前置する。
- socket 接続失敗時はエラー扱いせず通常出力にフォールバックする。
