# 推敲 (日本語 markdown)

日本語の markdown を推敲するときの skill の実行順序を定めるルール。各 skill の手順は skill 本文に委譲する。

## 原則

- MUST: 日本語の markdown を推敲する場面では、skill `yomiyasu` を先に当て、続けて skill `ja-tech-proofread` (fix モード) を当てる。順序はこの通りに固定する。
  - 理由: yomiyasu は文の構造と語の選び方を書き換える。ja-tech-proofread は構成・語彙の推敲に加え preset の表記規則で最終形を揃える。逆順にすると、yomiyasu の書き換えが持ち込んだ preset 違反が残る。
- ユーザが一方の skill だけを名指しした場合は、その skill だけを実行する。
- 対象は変更したファイルを列挙して渡し、ディレクトリ走査はしない。
- yomiyasu の lint スクリプトは `python3` で動く (`packages.nix` で導入)。実行できない場合は実行不可の事実を報告し、ja-tech-proofread へ進む。
- yomiyasu は他の校正 skill との併用で指示が食い違う場合があると注記している。食い違いの解消は順序に委ね、後に当てた ja-tech-proofread の結果を最終形とする。
