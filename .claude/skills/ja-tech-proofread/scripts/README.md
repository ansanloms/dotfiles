# ja-tech-proofread scripts

ja-tech-proofread skill の機械層を実行する Node の薄い層。表記・文法の機械判定は textlint (preset `@ansanloms/textlint-rule-preset-ansanloms`)、markdown の整形は oxfmt が担う。rule 自体はここでは定義しない。Node.js 24 以上が必要。

## ファイル構成

- `package.json`: `textlint`、`oxfmt`、preset を `dependencies` に固定する。preset は `github:ansanloms/textlint-rule-preset-ansanloms#0.1.0` の git 依存。`lint`/`fix` script はこのディレクトリの設定ファイル自身の整形検査用で、推敲対象には使わない。
- `package-lock.json`: 依存の固定。
- `.npmrc`: `engine-strict`、`ignore-scripts`、`audit`、`min-release-age=7`、`save-exact`、`fund=false`。
- `.textlintrc.json`: preset を有効化するだけの設定。個別 rule の options はここでは上書きしない。
- `.oxfmtrc.json`: oxfmt の設定。`proseWrap: preserve` (日本語の段落を折り返さない) と `embeddedLanguageFormatting: off` (コードフェンス内を整形しない)。
- `.ignore-none`: 空ファイル。`--ignore-path` に渡して、呼び出し元 cwd の `.textlintignore`・`.prettierignore`・`.gitignore` が対象を黙って除外するのを防ぐ (これらを渡さないと、textlint は除外されても終了コード 0 で指摘 0 件に見え、oxfmt は終了コード 2 になる。2026-10-12 実測)。
- `.gitignore`: `node_modules/` と `.cache/` を除外する。
- `README.md`: この文書。

## 起動方法

依存は初回と更新後に `npm ci --omit=dev --prefix "<scripts の絶対パス>"` で入れる。以降は cwd を問わず、絶対パスで次のとおり呼ぶ。

```sh
npx --no --prefix "<scripts の絶対パス>" -- textlint --config "<scripts の絶対パス>/.textlintrc.json" --ignore-path "<scripts の絶対パス>/.ignore-none" [--fix] <対象ファイルの絶対パス...>
npx --no --prefix "<scripts の絶対パス>" -- oxfmt -c "<scripts の絶対パス>/.oxfmtrc.json" --ignore-path "<scripts の絶対パス>/.ignore-none" [--check] <対象ファイルの絶対パス...>
```

- `--` は必須。npm 11 は `--config` や `--fix` を npx 自身のフラグとして解釈するため、`--` で区切らないと textlint に届かない。
- `--prefix` は bin の解決先の指定で、cwd は呼び出し元のまま変わらない。相対パスの対象は呼び出し元の cwd 基準で解決される (2026-10-12 実測)。
- `--no` を付けて、未インストールの依存を npx が勝手に取得しないようにする。`node_modules` が無いと `npm error npx canceled due to missing packages and no YES option` を出して終了コード 1 になる。
  - 以下は `node_modules` を別名へ退避した状態で、cwd を `/` にして実行して得た実物の出力 (取得コマンドは次のとおり、取得日 2026-10-12、実行後に `node_modules` は戻した。パスはリポジトリ外の probe)。

    ```sh
    npx --no --prefix "<scripts の絶対パス>" -- textlint --config "<scripts の絶対パス>/.textlintrc.json" --ignore-path "<scripts の絶対パス>/.ignore-none" /home/ansanloms/.claude/jobs/4da019b2/tmp/jtp-r1/cwd/t.md
    ```

    ```
    npm error npx canceled due to missing packages and no YES option: ["textlint@15.8.0"]
    npm error A complete log of this run can be found in: /home/ansanloms/.npm/_logs/2026-10-12T13_19_00_893Z-debug-0.log
    ```
- oxfmt は `--prefix` 側の設定を見ないため、`-c` に絶対パスで設定を渡す。`..` を含むパスは受け付けない。
- `--fix` を付けると自動修正が効く rule (全角半角スペース等) だけをその場で直す。修正できない指摘が残っていても `--fix` の出力には載らず、終了コードは 0 になる。残りは `--fix` 無しで再実行して確認する。
- oxfmt の `--check` は整形差分ありで終了コード 1、対象が見つからないと 2。`--check` 無しの書き込みモードは変更の有無を出力せず、終了コードは変更なしでも変更ありでも 0。

## preset の参照先

preset は `package.json` の `dependencies` で `github:ansanloms/textlint-rule-preset-ansanloms#0.1.0` を指す git 依存で、dist を同梱しているためビルドは不要。タグを上げるときは `package.json` の `#<タグ>` を書き換え、このディレクトリで `npm install` を実行して `package-lock.json` を更新する。

## preset を取得できないときの挙動

preset が解決できない状態 (`node_modules` に preset が無い、`.textlintrc.json` の rule 名が誤っている等) で実行すると、rule が 1 つも読み込めないまま textlint が終了する。以下は `.textlintrc.json` の rule 名を存在しない名前に書き換えて得た実物の出力の先頭 3 行 (取得コマンドは次のとおり、取得日 2026-10-12)。

```sh
npx --no --prefix "<scripts の絶対パス>" -- textlint --config "<scripts の絶対パス>/.textlintrc.json" --ignore-path "<scripts の絶対パス>/.ignore-none" /home/ansanloms/.claude/jobs/4da019b2/tmp/jtp-impl/probe.md
```

```
== No rules found, textlint hasn’t done anything ==

Possible reasons:
```

終了コードは 1。preset の解決失敗が「rule が 0 件」という形で現れるため、SKILL.md の手順ではこの `No rules found` を「機械層: 実行不可 (理由)」として扱う。

## ローカル検証

公開前の preset の変更を手元で確認したい場合は、このディレクトリで `npm install <手元の textlint-rule-preset-ansanloms clone の絶対パス>` を実行して一時的に差し替える。確認が終わったら `package.json` と `package-lock.json` を元に戻し (`git checkout -- package.json package-lock.json` の後に `npm ci`)、差し替えをコミットしない。

## 注意

- `.cache/`: proofdict の辞書キャッシュは `<scripts>/.cache/kvs-node-localstorage/` に作られる。呼び出し元の cwd には作られない (cwd を `/` や別ディレクトリにして実測、2026-10-12)。`.gitignore` で除外している。
- rule の options は上書きすると (preset 側の値と) マージされず置換される。preset が `false` にした rule を再び有効にしたいときは、その rule の値を空オブジェクト `{}` に置き換える。
