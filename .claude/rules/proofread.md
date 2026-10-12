# 文書執筆後の推敲

markdown で書いた文書を確定させる前に `/ja-tech-proofread` で推敲するタイミングと適用範囲を定めるルール。推敲の具体手順 (textlint との分担、構成・語彙の判定基準、報告書式等) は `ja-tech-proofread` skill に委譲し、本ルールは「いつ使うか」「何を対象にするか」だけを定める。

## 原則

- MUST: 日本語で書かれた markdown ファイルを新規作成、または実質的な内容変更を伴う改稿をしたら、成果物として確定させる前 (ユーザへの提示・コミット・PR 作成等の前) に `/ja-tech-proofread` をそのファイルに対して実行する。
- 本規範は、dev-workflow ルールの「ファイル変更を伴う実装はメインループが直接行わない」MUST に対する明示的な例外である。markdown 文書へ `/ja-tech-proofread` を適用する行為に限って本規範を優先する。
- 適用主体はメインループに限る。`/ja-tech-proofread` は Skill ツール経由の起動が前提で、Skill ツールを持たない subagent (implementer 等) には課さない。dev-workflow ルールの例外条項による散文文書の直接執筆と、通常フローで subagent が書いた markdown ファイルのコミット前確認の両方が対象になる。
- 次は対象外とする。
  - dev-workflow ルールの例外の 1 番目が定める、軽微な修正の基準に該当する変更。
  - コミットメッセージ・PR 本文。書式と規約は git ルール・dev-workflow ルールが個別に定めており、本ルールでは扱わない。
  - `ja-tech-proofread` skill の「持ち込まないもの」節が対象外とする文書 (英語文書等)。
- mode 指定は既定の fix を使う。要判断が生じた場合は skill の手順通りその場でユーザに確認する。
