# LSP

コードベース内のシンボルの検索・ナビゲーションで使う手段の選択と、TypeScript と JavaScript での LSP の使い分けを定めるルール。適用主体は LSP ツールを持つ subagent (research-worker/implementer)。

## コード検索・ナビゲーション

- MUST: コードの定義元・参照元・型情報の確認には LSP ツールを第一手段として使用すること。grep/ripgrep によるテキスト検索は LSP で解決できない場合の補助手段とする。
- MUST: ファイル内のシンボル一覧が必要な場合は `documentSymbol` を使用すること。
- MUST: プロジェクト横断のシンボル検索には `workspaceSymbol` を使用すること。
- MUST: リファクタリング前に `findReferences` で影響範囲を確認すること。

## TypeScript / JavaScript の LSP 使い分け

- `package.json` が存在する → vtsls を優先して使用する。
- `deno.json` または `deno.jsonc` が存在する → denols を優先して使用する。`package.json` より優先する。
