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
  -- CSSの取得は初回のみのためここでは実装しない

  vim.g.quickrun_config = vim.g.quickrun_config or {}
  vim.g.quickrun_config["markdown"] = {
    type = "markdown/pandoc",
  }

  -- html 出力
  vim.g.quickrun_config["markdown/pandoc"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "browser",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --css=" .. vim.fn.expand(
      "~/.config/vim/markdown.css"
    ) .. " --metadata title=%s",
  }

  -- slidy 出力
  vim.g.quickrun_config["markdown/pandoc-slidy"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "browser",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=slidy --toc-depth=6 --metadata title=%s",
  }

  -- Word docx 出力
  vim.g.quickrun_config["markdown/pandoc-docx"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "null",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=docx --toc-depth=6 --highlight-style=zenburn --output=%s.docx",
  }

  -- 単一 markdown 出力
  vim.g.quickrun_config["markdown/pandoc-self-contained"] = {
    ["hook/cd/directory"] = "%S:p:h",
    ["outputter/buffer/filetype"] = "markdown",
    exec = "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --no-highlight --metadata title=%s | pandoc --from html --to markdown --wrap none --markdown-headings=atx"
      .. ' | sed -r -e "s/```\\s*\\{\\.(.*)\\}/```\\1/g"',
  }
end
