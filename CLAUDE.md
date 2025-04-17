# CLAUDE.md for dotfiles

## Commands

- Install: `deno task install`
- Uninstall: `deno task uninstall`
- Formatting: `deno fmt`
- Linting: `deno lint`
- Type checking: `deno check`

## Code Style Guidelines

- Formatting: Uses Deno's formatter with `proseWrap: "preserve"`
- Use Prettier for JavaScript, TypeScript, CSS, and other web files
- Follow efm-langserver configuration for consistent formatting
- Organize files by OS target (windows, linux, darwin) in config.yaml
- Use descriptive comments for configuration files
- Maintain consistent indentation (2 spaces) across YAML and code files
- Use relative paths with the `./` prefix in config.yaml
- Prefer absolute paths with `~/` or full paths for target locations
- Keep commands in deno.json tasks concise and single-purpose
- Maintain clear README with installation instructions

## 言語設定

- 日本語での出力を優先する
- コメントやコミットメッセージは日本語で書く
- ドキュメンテーションは日本語と英語の両方で提供する
