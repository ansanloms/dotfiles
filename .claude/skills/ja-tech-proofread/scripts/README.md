# ja-tech-proofread scripts

ja-tech-proofread skill の機械層 (表記・文法の機械判定) を実行する textlint のラッパー。preset `textlint-rule-preset-ansanloms` を有効化した状態で textlint を起動するだけの薄い層で、rule 自体はここでは定義しない。

## ファイル構成

- `deno.json`: `@ansanloms/textlint-rule-preset-ansanloms` を jsDelivr 経由の URL に alias する import map と、textlint を起動する `textlint` task を持つ。`fmt` 設定 (proseWrap preserve) と `fmt`/`fmt:check` task も持つ。
- `.textlintrc.js`: `preset-ansanloms` rule を有効化するだけの設定。個別 rule の options はここでは上書きしない。
- `textlint/textlint-rule-preset-ansanloms/index.js`: `--rules-base-directory` が探す実体で、import map で解決した preset をそのまま re-export する 1 行。
- `.gitignore`: `.cache/` を除外する。
- `deno.lock`: 依存の固定。preset の URL とその依存を pin する。
- `README.md`: この文書。

## 起動方法

このディレクトリを cwd として実行する前提で書く。SKILL.md からは `--cwd` に絶対パスを付けて呼ぶ (「呼び出し側の cwd と `--cwd`」参照)。

```sh
deno task -q textlint <対象ファイルの絶対パス...> [--fix] [--format json]
```

`--fix` を付けると自動修正が効く rule (全角半角スペース等) だけをその場で直す。追加の引数は task の後ろにそのまま渡る。

```sh
deno task -q fmt <対象ファイルの絶対パス...>
deno task -q fmt:check <対象ファイルの絶対パス...>
```

`deno fmt` は対象ファイルの祖先ディレクトリから設定を探すため、そのままでは対象が Deno プロジェクトの外 (一時ファイル等) にあると既定の `proseWrap: always` で日本語の段落が折り返される。これを避けるため `fmt` と `fmt:check` の task は常に `--config` でこのディレクトリの `deno.json` (`proseWrap: preserve`) を使う。対象が属するプロジェクトの fmt 設定 (インデント幅や引用符の種類等) と除外は見ない。推敲対象を明示的に渡す前提であり、コードフェンス内のコードがプロジェクトの設定と違う形に整形される可能性は受け入れる。

## preset の参照先

`deno.json` の `imports` で `@ansanloms/textlint-rule-preset-ansanloms` を `https://cdn.jsdelivr.net/gh/ansanloms/textlint-rule-preset-ansanloms@0.0.2/index.ts` に alias している。タグ `0.0.2` は 2026-08-31 に公開済みで、この URL は配信されている。0.0.2 では `no-ai-list-formatting: { disableBoldListItems: true }` と `2.1.5.カタカナ: false` が preset に加わった。ただし `no-ai-emphasis-patterns` は「重要」「注意」等の情報プレフィックスの太字を引き続き検出する。

## preset を取得できないときの挙動

以下はタグ公開前 (2026-08-31) に取得した実物で、URL 不達時の形として残す。URL に到達できない (ネットワーク不通、タグの削除等) 状態で実行すると、rule が 1 つも読み込めないまま textlint が終了する。以下は実物のエラー出力の先頭 3 行 (取得コマンドは次の通り、取得日 2026-08-31)。

```sh
deno task -q --cwd "<scripts の絶対パス>" textlint /home/ansanloms/.claude/jobs/b7dd5f76/tmp/proofread-probe.md
```

```
== No rules found, textlint hasn’t done anything ==
```

終了コードは 1 (失敗)。preset の import 失敗が「rule が 0 件」という形で現れるため、SKILL.md の手順ではこの「No rules found」を「機械層: 実行不可 (理由)」として扱う。

## ローカル検証 (alias の一時差し替え)

公開前の変更を手元で確認したい場合は、`deno.json` の `imports."@ansanloms/textlint-rule-preset-ansanloms"` を、手元にチェックアウト済みの `textlint-rule-preset-ansanloms` リポジトリの `index.ts` の絶対パスに一時的に差し替えて実行する。確認が終わったら jsDelivr の URL (`@0.0.2`) に戻し、差し替えをコミットしない。

## lock の再生成

`deno.lock` を作り直すときは、このディレクトリで `rm -f deno.lock` の後に `deno install` を実行し、続けて `textlint` と `fmt:check` の task を 1 回ずつ走らせて lock を埋める。

## 注意

- 呼び出し側の cwd と `--cwd`: `deno task --cwd <path> <task>` で起動すると、task 内では `$PWD` が `--cwd` に渡した絶対パス (このディレクトリ) を指す。`$INIT_CWD` は `deno task` を起動したシェル自身の cwd を指し、`--cwd` の値とは異なるため使わない (2026-08-31 実測)。`deno.json` の `textlint` task は `$PWD` を使っている。
- `.cache/`: 実測では、proofdict の辞書キャッシュはこのディレクトリ配下ではなく、Deno の npm キャッシュ (`~/.cache/deno/npm/registry.npmjs.org/textlint/<バージョン>/bin/.cache` 相当) に作られた (2026-08-31、strace で `mkdir` の呼び出し先を追跡して確認)。`.gitignore` の `.cache/` はこのディレクトリ配下に生成される場合に備えた予防的なエントリで、現時点の実測では実際には使われていない。
- rule の options は上書きされると (preset 側の値と) マージされず置換される。preset が `false` にした rule を再び有効にしたいときは、その rule の値を空オブジェクト `{}` に置き換える。
