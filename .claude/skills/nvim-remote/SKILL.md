---
name: nvim-remote
description: 呼び出し側から渡された nvim の socket パスを使い、socket 経由 (nvim --server --remote-tab / --remote-send) でファイル・diff・コマンド出力を nvim へ流し込む具体手順。nvim でファイルを開く / diff を見せる / 長文出力を見せる際に使用する。
---

# nvim 遠隔操作 (socket 経由)

呼び出し側から渡された socket パス経由で nvim を遠隔操作し、作業結果を nvim に流し込む。socket パスがどう供給されるか (環境変数・呼び出し時の指示等) は呼び出し側の責務であり、この skill はそれに関与しない。

## socket パスの受け取り

この skill は socket パスが与えられている前提で動く。socket の検出・導出・存在チェックは呼び出し側が済ませている。

次の手順では、渡された socket パスを `$sock` に入れて使う。

```sh
sock="<呼び出し側から渡された socket パス>"
```

socket パスが渡されていない場合、この skill は適用できない。nvim 手順 (`--server` 系のコマンド) を一切実行せず、socket パスが渡されていないため nvim へ流せなかったことを呼び出し元へ伝えて終える。コンソール出力等の代替手段を取るかどうかは呼び出し側の判断であり、この skill 側で勝手に代替しない。断るのは nvim 手順だけで、ユーザの本来の目的をどう満たすかは呼び出し側に委ねる。

## ファイルを nvim で開く

```sh
nvim --server "$sock" --remote-tab <filepath>
```

## diff を nvim で開く

先にどちらの手順かを選ぶ。2 つのファイルパスが具体的にある (「A と B を並べて」等) なら「2 ファイル間の diff」、`git diff` 等のコマンドが吐く差分文字列を見せるなら「差分文字列そのものを見せる」。

### 2 ファイル間の diff

基準ファイル (base、例: リファクタ前・変更前) を `--remote-tab` で新規タブに開き、続けて比較ファイル (compare、例: リファクタ後・変更後) を `vert diffsplit` で左右に重ねる。`<Esc>` を前置して insert mode の影響を避ける。

- base = 先に `--remote-tab` で開く側。compare = 後から `diffsplit` で重ねる側。どちらが base かは statusline のファイル名で判別する。
- `diffsplit` には `vert` を付けて左右に並べる (`:vert diffsplit`)。この `vert` は意図した指定なので外さない。外すと上下分割になり「並べる」意図とずれる。`splitright` が決めるのは compare が左右どちらの側に入るかだけで、`vert` を付けるかどうかとは別の話。左右の位置を前提にした説明 (どちらが左か等) は書かない。
- ユーザ文の語との対応: 旧・before・変更前・リファクタ前 → base、新・after・変更後・リファクタ後 → compare。
- 両ファイルとも絶対パスで渡す (理由は「注意事項」参照)。

```sh
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
nvim --server "$sock" --remote-tab "$tmp"
```

## 出力結果を nvim で開く

コマンド実行結果や調査結果等、長文の出力は一時ファイルに書き出して `--remote-tab` で開く。

- MUST: 拡張子は内容に合わせる (`.md` / `.log` / `.json` / `.txt` 等)。filetype 判定が効く。
- MUST NOT: 一時ファイルを削除しない。nvim 側で開いている間に消えると参照できなくなる。

```sh
tmp=$(mktemp --suffix=.md)
<command> > "$tmp"                                   # コマンド出力を流す場合
# 文字列が手元にある場合: printf '%s\n' "$var" > "$tmp"  (echo ではなく printf。-e 解釈や先頭ハイフン事故を避ける)
nvim --server "$sock" --remote-tab "$tmp"
```

## 注意事項

- MUST: ファイルを開く際は `--remote` ではなく `--remote-tab` を使用する。ユーザが編集中のバッファを上書きしない為、必ず新規タブに開く。
- MUST: nvim に渡すファイルパスは絶対パスにする。`--remote-tab` / `diffsplit` のパス解決基準は受け取る nvim 側の cwd であり、エージェント側の cwd と一致する保証がない。相対パスで来たら `realpath <path>` 等で絶対パスへ解決してから渡す (`mktemp` が返すパスは元から絶対なのでそのままでよい)。
- `--remote-send` で送るキーシーケンスは nvim 記法 (`<Esc>` / `<CR>` 等) を使用する。
- nvim が insert mode 等にいる可能性を考慮し、Ex コマンド送信前には `<Esc>` を前置する。
