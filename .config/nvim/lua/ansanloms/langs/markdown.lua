-- Markdownの設定
local augroup_markdown = vim.api.nvim_create_augroup("markdown-setting", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_markdown,
  pattern = "*.{md,mdwn,mkd,mkdn,mark*}",
  callback = function()
    vim.opt_local.filetype = "markdown"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_markdown,
  pattern = "markdown",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- フォーマット指定。
    if vim.fn.executable("deno") == 1 then
      vim.opt_local.formatprg = "deno fmt --ext md --prose-wrap preserve -"
    end
  end,
})

local augroup_markdown_mdx = vim.api.nvim_create_augroup("markdown-mdx-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_markdown_mdx,
  pattern = "markdown.mdx",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun - markdown
if vim.fn.executable("pandoc") == 1 then
  -- pandoc 用の取得物 (markdown.css / mermaid.min.js) の置き場。
  -- リポジトリ管理の設定ではなく、初回のみ手動取得するデータのため data dir に置く。
  local assets_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "pandoc")
  local pandoc_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "pandoc")

  -- CSS は取得済みのときだけ適用する。存在しないパスを --css へ渡すと
  -- pandoc がエラー終了するため。
  local css = vim.fs.joinpath(assets_dir, "markdown.css")
  local css_option = vim.fn.filereadable(css) == 1 and (" --css=" .. css) or ""

  -- mermaid.min.js を取得済みならローカル参照の header を使い、
  -- 無ければ CDN 参照の header にフォールバックする。
  local mermaid_header = vim.fn.filereadable(vim.fs.joinpath(assets_dir, "mermaid.min.js")) == 1
      and vim.fs.joinpath(pandoc_dir, "mermaid-local.html")
    or vim.fs.joinpath(pandoc_dir, "mermaid-cdn.html")

  -- 生成した HTML を OS 既定のブラウザで開くコマンド。open-browser.vim には依存しない。
  -- WSL では Windows 側プログラムに Linux パスを直接渡せないため wslpath で変換する。
  -- quickrun は exec を quickrun#expand() に通し & や $ を展開トリガとして解釈するため、
  -- シェルに渡したい & と $ はバックスラッシュでエスケープしておく (%s は quickrun の
  -- プレースホルダとして展開させるためエスケープしない)。
  local function browser_command(path)
    if vim.fn.has("wsl") == 1 then
      return 'rundll32.exe url.dll,FileProtocolHandler "\\$(wslpath -w ' .. path .. ')"'
    elseif vim.fn.has("mac") == 1 then
      return "open " .. path
    end
    return "xdg-open " .. path
  end

  local quickrun_config = vim.g.quickrun_config or {}

  quickrun_config["markdown"] = {
    type = "markdown/pandoc",
  }

  -- html 出力
  quickrun_config["markdown/pandoc"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "error",
    ["outputter/error/success"] = "null",
    ["outputter/error/error"] = "buffer",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6"
      .. css_option
      .. " --lua-filter=" .. vim.fs.joinpath(pandoc_dir, "mermaid.lua")
      .. " --include-in-header=" .. mermaid_header
      .. " --resource-path=.:" .. assets_dir
      .. " --metadata title=%s --output=%s.html \\&\\& "
      .. browser_command("%s.html"),
  }

  -- slidy 出力
  quickrun_config["markdown/pandoc-slidy"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "error",
    ["outputter/error/success"] = "null",
    ["outputter/error/error"] = "buffer",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=slidy --toc-depth=6"
      .. " --metadata title=%s --output=%s.html \\&\\& "
      .. browser_command("%s.html"),
  }

  -- Word docx 出力
  quickrun_config["markdown/pandoc-docx"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "null",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=docx --toc-depth=6 --highlight-style=zenburn --output=%s.docx",
  }

  -- 単一 markdown 出力
  quickrun_config["markdown/pandoc-self-contained"] = {
    ["hook/cd/directory"] = "%S:p:h",
    ["outputter/buffer/filetype"] = "markdown",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --no-highlight --metadata title=%s | pandoc --from html --to markdown --wrap none --markdown-headings=atx"
      .. ' | sed -r -e "s/```\\s*\\{\\.(.*)\\}/```\\1/g"',
  }

  vim.g.quickrun_config = quickrun_config
end
