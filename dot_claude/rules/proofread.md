# 推敲 (日本語 markdown)

日本語の markdown を推敲するときの skill の実行順序を定めるルール。各 skill の手順は skill 本文に委譲する。

## 原則

- MUST: 日本語の markdown を推敲する場面では、skill `yomiyasu` を先に当て、続けて skill `ja-tech-proofread` (fix モード) を当てる。順序はこの通りに固定する。
  - 理由: yomiyasu は文の構造と語の選び方を書き換える。ja-tech-proofread は構成・語彙の推敲に加え preset の表記規則で最終形を揃える。逆順にすると、yomiyasu の書き換えが持ち込んだ preset 違反が残る。
- このルールによる推敲は yomiyasu を名指しした依頼として扱う。理由: 現行の yomiyasu (3.1.0) は名前を出して頼まれたときだけ動く。
- ユーザが一方の skill だけを名指しした場合は、その skill だけを実行する。
- 対象は変更したファイルを列挙して渡し、ディレクトリ走査はしない。
- yomiyasu の検査には原文と最終稿を標準入力で渡す (`yomiyasu_check.py run --stdin`。照合は `verify --final -`)。理由: yomiyasu は名前が点で始まるフォルダの中のファイルを読まない。隔離 worktree は `.claude/worktrees/` の下にあるので、パスでは渡せない。
  - 検査を終えた最終稿はメインループが対象ファイルへ書き戻す。理由: 続く ja-tech-proofread は同じパスを読む。
  - 検査の記録は `--state-dir` で非汚染領域 (`$CLAUDE_JOB_DIR/tmp` があればそこ、無ければ `mktemp -d` の結果) に置く。理由: 省くと cwd が属するリポジトリの最上位に `.yomiyasu/` が作られる。メインループの cwd はメイン checkout なので、そこへ書き込むことになる。
  - yomiyasu の最終稿の照合 (`verify`) は yomiyasu の手順の中で済ませ、ja-tech-proofread が本文を変えた後にやり直さない。理由: 照合が確かめるのは、検査した本文と yomiyasu が提出する本文が同じかどうかである。
- yomiyasu の検査は `python3` で動く (`packages.nix` で導入)。実行できない場合は実行不可の事実を報告し、ja-tech-proofread へ進む。
- yomiyasu と ja-tech-proofread の指示が食い違う場合は、後に当てた ja-tech-proofread の結果を最終形とする。
